import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/offline_constants.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/sync/decimal3.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../data/local/stock_local_store.dart';
import '../data/models/requests/create_inbound_request_dto.dart';
import '../data/models/responses/inbound_response_dto.dart';

/// Thrown before anything is written when a stock change is refused locally.
class StockValidationException implements Exception {
  const StockValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Who is changing stock: read from the signed-in session (injected, so the
/// service never depends on a bloc). Mirrors the BE checks in
/// `apps/sync/handlers.py` (`stock_op`, `inbound_create`, `_own_shop_only`).
class StockActor {
  const StockActor({
    required this.businessType,
    required this.role,
    required this.shopId,
  });

  final AppBusinessType businessType;
  final AppUserRole role;

  /// The user's assigned (default) shop; only enforced for cashiers.
  final String? shopId;
}

/// The only writer of local stock edits and inbound receipts on the sync
/// engine path. Each call is ONE [LocalWriter.write]: the outbox row and the
/// local stock effect commit together.
///
/// Stock: the outbox row IS the pending delta (`StockLocalStore
/// .pendingDeltaUnits` counts open `stock.*` and `inbound.create` rows), so
/// after enqueueing, each touched (product, shop) is re-derived as
/// base + pending. `base_quantity` is never touched here; negative stock is
/// allowed. The BE answers `stock_after`, applied on `applied` only by
/// `StockApplier` / `InboundApplier`.
class StockService {
  StockService({
    required LocalWriter writer,
    required StockActor Function() actor,
    DateTime Function()? now,
    Uuid? uuid,
    StockLocalStore stock = const StockLocalStore(),
  }) : _writer = writer,
       _actor = actor,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid(),
       _stock = stock;

  final LocalWriter _writer;
  final StockActor Function() _actor;
  final DateTime Function() _now;
  final Uuid _uuid;
  final StockLocalStore _stock;

  /// Tables a stock edit touches (notified once after commit, plus outbox).
  static const Set<String> tables = {'stock', 'products', SyncTables.outbox};

  /// Tables an inbound receipt touches.
  static const Set<String> inboundTables = {
    'stock',
    'products',
    OfflineConstants.inboundTransactionsTable,
    SyncTables.outbox,
  };

  /// BE `stock_op` keeps at most 200 chars of the reason.
  static const int maxReason = 200;

  /// `stock.add`: [delta] must be > 0 (BE rejects otherwise). Returns the new
  /// displayed quantity (exact decimal string).
  ///
  /// [expiryDate] (`YYYY-MM-DD`) and [batchNumber] ride in the payload; the
  /// BE then creates the batch (capability `stock_add_expiry`, the caller
  /// checks it). Local stock is unaffected: the batch comes back by pull.
  Future<String> add({
    required String productId,
    required String shopId,
    required String delta,
    String? reason,
    String? expiryDate,
    String? batchNumber,
  }) async {
    final d = _delta(delta);
    if (d <= BigInt.zero) {
      throw const StockValidationException(
        'Quantity to add must be greater than 0',
      );
    }
    final expiry = expiryDate?.trim();
    if (expiry != null &&
        expiry.isNotEmpty &&
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(expiry)) {
      throw const StockValidationException('Expiry date must be YYYY-MM-DD');
    }
    final batch = batchNumber?.trim();
    if (batch != null && batch.length > 100) {
      throw const StockValidationException('Batch number is too long');
    }
    return _op(
      'add',
      productId,
      shopId,
      d,
      reason,
      extra: {
        if (expiry != null && expiry.isNotEmpty) 'expiry_date': expiry,
        if (expiry != null &&
            expiry.isNotEmpty &&
            batch != null &&
            batch.isNotEmpty)
          'batch_number': batch,
      },
    );
  }

  /// `stock.remove`: the BE takes the magnitude of the delta, so the
  /// magnitude is sent (always positive). Returns the new quantity.
  Future<String> remove({
    required String productId,
    required String shopId,
    required String delta,
    String? reason,
  }) async {
    final d = _delta(delta).abs();
    if (d == BigInt.zero) {
      throw const StockValidationException('Quantity must not be 0');
    }
    return _op('remove', productId, shopId, d, reason);
  }

  /// `stock.adjust`: signed delta, sent as given. Returns the new quantity.
  Future<String> adjust({
    required String productId,
    required String shopId,
    required String delta,
    String? reason,
  }) async {
    final d = _delta(delta);
    if (d == BigInt.zero) {
      throw const StockValidationException('Quantity must not be 0');
    }
    return _op('adjust', productId, shopId, d, reason);
  }

  /// `stock.adjust` towards an absolute quantity: the delta is
  /// [newQuantity] minus the local quantity (base + pending), computed in
  /// the same transaction as the enqueue. A zero delta is refused.
  Future<String> adjustTo({
    required String productId,
    required String shopId,
    required String newQuantity,
    String? reason,
  }) async {
    final target = _delta(newQuantity);
    return _op('adjust', productId, shopId, null, reason, target: target);
  }

  Future<String> _op(
    String op,
    String productId,
    String shopId,
    BigInt? delta,
    String? reason, {
    BigInt? target,
    Map<String, Object?> extra = const {},
  }) async {
    final p = productId.trim();
    final s = shopId.trim();
    if (p.isEmpty) throw const StockValidationException('Product is required');
    if (s.isEmpty) throw const StockValidationException('Shop is required');
    _checkActor(shopId: s, inbound: false);
    final why = _reason(reason);
    final occurredAt = _now().toUtc();
    final entityId = _uuid.v4();

    return _writer.write<String>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        var d = delta;
        if (target != null) {
          d = target - await _stock.currentUnits(txn, p, s);
          if (d == BigInt.zero) {
            throw const StockValidationException('Quantity is unchanged');
          }
        }
        return enqueueOpIn(
          scope,
          op: op,
          productId: p,
          shopId: s,
          delta: d!,
          reason: why,
          occurredAt: occurredAt,
          entityId: entityId,
          stock: _stock,
          extra: extra,
        );
      },
    );
  }

  /// The body of every `stock.*` op, for callers that already hold a
  /// [WriteScope] (`LocalWriter.write` cannot nest; e.g. `ProductService`
  /// recording an opening quantity in the product's own write). Enqueues
  /// the op (depending on [productId], so it waits for an open product
  /// create), re-derives local stock and returns the new displayed
  /// quantity. No validation: callers validate first.
  static Future<String> enqueueOpIn(
    WriteScope scope, {
    required String op,
    required String productId,
    required String shopId,
    required BigInt delta,
    required String reason,
    required DateTime occurredAt,
    required String entityId,
    StockLocalStore stock = const StockLocalStore(),
    Map<String, Object?> extra = const {},
  }) async {
    final txn = scope.txn;
    // entity_id: a fresh UUID per mutation (BE requires a UUID and only
    // uses it for the applied-mutation ledger; using the product id would
    // serialise every stock edit of a product behind a rejected one and
    // make the BE fail later same-batch mutations of that product with
    // dependency_failed).
    await scope.enqueue(
      entity: 'stock',
      op: op,
      entityId: entityId,
      occurredAt: occurredAt,
      dependsOn: [productId],
      payload: {
        'product_id': productId,
        'shop_id': shopId,
        'delta': Decimal3.format(delta),
        'reason': reason,
        'occurred_at': occurredAt.toIso8601String(),
        ...extra,
      },
    );
    await stock.recompute(txn, productId, shopId, createIfMissing: true);
    return Decimal3.format(await stock.currentUnits(txn, productId, shopId));
  }

  /// After a successful REST add (used only for dated adds, which
  /// `stock.add` cannot express): raises the local base by exactly
  /// [quantity], no outbox row. The next pull overwrites the base with the
  /// absolute server value. Returns the new displayed quantity.
  Future<String> applyOnlineAdd({
    required String productId,
    required String shopId,
    required String quantity,
  }) async {
    final p = productId.trim();
    final s = shopId.trim();
    final q = _delta(quantity);
    return _writer.write<String>(
      tables: const {'stock', 'products'},
      body: (scope) async {
        final txn = scope.txn;
        final rows = await txn.query(
          'stock',
          columns: ['base_quantity'],
          where: 'product_id = ? AND shop_id = ?',
          whereArgs: [p, s],
          limit: 1,
        );
        final base = rows.isEmpty
            ? BigInt.zero
            : (Decimal3.tryParse(rows.first['base_quantity']) ?? BigInt.zero);
        await _stock.setBase(txn, p, s, Decimal3.format(base + q));
        return Decimal3.format(await _stock.currentUnits(txn, p, s));
      },
    );
  }

  /// After a successful REST transfer (transfer is not a sync op in Phase
  /// 1): moves exactly [quantity] of local base from [fromShopId] to
  /// [toShopId], no outbox row. The next pull brings the absolute values.
  Future<void> applyOnlineTransfer({
    required String productId,
    required String fromShopId,
    required String toShopId,
    required String quantity,
  }) async {
    final p = productId.trim();
    final q = _delta(quantity).abs();
    await _writer.write<void>(
      tables: const {'stock', 'products'},
      body: (scope) async {
        final txn = scope.txn;
        for (final (shop, sign) in [
          (fromShopId.trim(), -q),
          (toShopId.trim(), q),
        ]) {
          final rows = await txn.query(
            'stock',
            columns: ['base_quantity'],
            where: 'product_id = ? AND shop_id = ?',
            whereArgs: [p, shop],
            limit: 1,
          );
          final base = rows.isEmpty
              ? BigInt.zero
              : (Decimal3.tryParse(rows.first['base_quantity']) ?? BigInt.zero);
          await _stock.setBase(txn, p, shop, Decimal3.format(base + sign));
        }
      },
    );
  }

  /// `inbound.create`: payload = the BE `InboundReceiveSerializer` fields
  /// (the DTO's json, quantities normalised to <= 3 decimals) plus
  /// `client_inbound_id`, which is also the outbox entity id (the BE uses
  /// the mutation's `entity_id` as the InboundTransaction id). Every line
  /// raises local stock at once; a local history row is written in the same
  /// transaction.
  Future<InboundTransactionData> receiveInbound(
    CreateInboundRequestDto request,
  ) async {
    final shopId = request.shopId.trim();
    if (shopId.isEmpty) {
      throw const StockValidationException('Shop is required');
    }
    if (request.vendorId.trim().isEmpty) {
      throw const StockValidationException('Vendor is required');
    }
    final reference = request.reference.trim();
    if (reference.isEmpty) {
      throw const StockValidationException('Reference is required');
    }
    if (reference.length > 255) {
      throw const StockValidationException('Reference is too long');
    }
    if (request.items.isEmpty) {
      throw const StockValidationException('At least one item is required');
    }
    _checkActor(shopId: shopId, inbound: true);

    final items = <CreateInboundItemRequestDto>[];
    var total = BigInt.zero;
    for (final it in request.items) {
      if (it.productId.trim().isEmpty) {
        throw const StockValidationException('Product is required');
      }
      final q = _delta(it.quantity);
      if (q <= BigInt.zero) {
        throw const StockValidationException(
          'Received quantity must be greater than 0',
        );
      }
      total += q;
      items.add(
        CreateInboundItemRequestDto(
          productId: it.productId.trim(),
          quantity: Decimal3.format(q),
          unitCost: it.unitCost,
          expiryDate: it.expiryDate,
          batchNumber: it.batchNumber,
        ),
      );
    }
    final dto = CreateInboundRequestDto(
      shopId: shopId,
      reference: reference,
      notes: request.notes,
      vendorId: request.vendorId.trim(),
      items: items,
    );
    final occurredAt = _now().toUtc();
    final id = _uuid.v4();

    return _writer.write<InboundTransactionData>(
      tables: inboundTables,
      body: (scope) async {
        final txn = scope.txn;
        await scope.enqueue(
          entity: 'inbound',
          op: 'create',
          entityId: id,
          occurredAt: occurredAt,
          // Waits for the create of the vendor and of every product.
          dependsOn: [
            dto.vendorId,
            ...{for (final it in items) it.productId},
          ],
          payload: {...dto.toJson(), 'client_inbound_id': id},
        );
        for (final productId in {for (final it in items) it.productId}) {
          await _stock.recompute(txn, productId, shopId, createIfMissing: true);
        }
        final data = InboundTransactionData(
          id: id,
          reference: reference,
          notes: dto.notes?.trim(),
          shop: shopId,
          vendorId: dto.vendorId,
          totalQuantity: Decimal3.format(total),
          itemCount: items.length,
          items: [
            for (final it in items)
              InboundTransactionItemData(
                product: it.productId,
                productName: await _productName(txn, it.productId),
                quantity: it.quantity,
                unitCost: it.unitCost,
                expiryDate: it.expiryDate,
                batchNumber: it.batchNumber,
              ),
          ],
          createdAt: occurredAt.toIso8601String(),
        );
        await txn.insert(
          OfflineConstants.inboundTransactionsTable,
          {
            'id': id,
            'shop_id': shopId,
            'json': jsonEncode(data.toJson()),
            'created_at': data.createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return data;
      },
    );
  }

  /// BE rules, checked before anything is written:
  /// restaurants reject every stock/inbound op; inbound is owner/manager
  /// only; cashiers may only change their own assigned shop.
  void _checkActor({required String shopId, required bool inbound}) {
    final a = _actor();
    if (a.businessType == AppBusinessType.restaurant) {
      throw const StockValidationException(
        'Restaurants do not track inventory',
      );
    }
    if (inbound && a.role == AppUserRole.cashier) {
      throw const StockValidationException(
        'Only owners and managers can receive inbound stock',
      );
    }
    if (a.role == AppUserRole.cashier &&
        (a.shopId == null || a.shopId!.trim() != shopId)) {
      throw const StockValidationException(
        'Cashiers can only change stock of their assigned shop',
      );
    }
  }

  static String _reason(String? raw) {
    final r = (raw ?? '').trim();
    return r.length > maxReason ? r.substring(0, maxReason) : r;
  }

  /// Exact quantity in units of 0.001; more than 3 significant decimals or
  /// a non-number is refused with [StockValidationException] (never rounded
  /// silently).
  static BigInt parseQuantity(String raw) => _delta(raw);

  static BigInt _delta(String raw) {
    final s = raw.trim();
    final m = RegExp(r'^[+-]?\d*(?:\.(\d*))?$').firstMatch(s);
    if (s.isEmpty || m == null) {
      throw const StockValidationException('Invalid quantity');
    }
    final frac = m.group(1) ?? '';
    if (frac.length > 3 && frac.substring(3).replaceAll('0', '').isNotEmpty) {
      throw const StockValidationException('Quantity has too many decimals');
    }
    try {
      return Decimal3.parse(s);
    } on FormatException {
      throw const StockValidationException('Invalid quantity');
    }
  }

  static Future<String?> _productName(Transaction txn, String id) async {
    final rows = await txn.query(
      'products',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['name'] as String?;
  }
}
