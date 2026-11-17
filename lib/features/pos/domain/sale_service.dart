import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/decimal3.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../../../core/sync/sync_state_store.dart';
import '../../inventory/data/local/stock_local_store.dart';
import '../data/local/sale_local_store.dart';
import 'sale.dart';
import 'sale_math.dart';

export 'sale.dart';

/// The only writer of local sales. A sale is written locally, together with
/// its single `sale.create` outbox row and its local stock effect, in ONE
/// [LocalWriter.write] transaction: it is never lost and never doubled.
///
/// Stock: the sale's outbox row IS its pending stock delta
/// (`StockLocalStore.pendingDeltaUnits` counts open `sale.create` rows), so
/// after enqueueing, each touched (product, shop) is re-derived as
/// base + pending. `base_quantity` is never touched here; negative stock is
/// allowed. The BE decrements stock for `sale.create` and answers
/// `stock_after`, applied by `SaleApplier` on `applied`.
class SaleService {
  SaleService({
    required LocalWriter writer,
    required SyncStateStore state,
    required String? Function() cashierId,
    DateTime Function()? now,
    Uuid? uuid,
    SaleLocalStore store = const SaleLocalStore(),
    StockLocalStore stock = const StockLocalStore(),
    @visibleForTesting Future<void> Function(String stage)? debugHook,
  }) : _writer = writer,
       _state = state,
       _cashierId = cashierId,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid(),
       _store = store,
       _stock = stock,
       _hook = debugHook;

  final LocalWriter _writer;
  final SyncStateStore _state;
  final String? Function() _cashierId;
  final DateTime Function() _now;
  final Uuid _uuid;
  final SaleLocalStore _store;
  final StockLocalStore _stock;
  final Future<void> Function(String stage)? _hook;

  /// Tables one sale write touches (notified once after commit).
  static const Set<String> tables = {
    SaleLocalStore.sales,
    SaleLocalStore.items,
    SaleLocalStore.payments,
    'stock',
    'products',
    SyncTables.outbox,
  };

  /// BE `PaymentMethod` choices (apps/sales/models/sale.py). Anything else
  /// is rejected by the server, so it is refused before enqueue.
  static const Set<String> paymentMethods = {
    'cash',
    'bankak',
    'card',
    'bank_transfer',
    'mobile_wallet',
    'loyalty_points',
    'split',
    'credit',
  };

  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  Future<Sale> createSale(SaleDraft draft) async {
    final p = _prepare(draft); // throws SaleValidationException
    // Own transaction: must run before (never inside) the write below.
    final deviceId = await _state.deviceId();
    // The BE parses `cashier` as a user UUID and rejects the WHOLE sale
    // otherwise, so anything else is left out (the server uses the caller).
    final rawCashier = _cashierId()?.trim();
    final cashier = rawCashier != null && _uuidRe.hasMatch(rawCashier)
        ? rawCashier
        : null;
    final occurredAt = _now().toUtc();
    final saleId = _uuid.v4();
    final lineIds = [for (final _ in p.lines) _uuid.v4()];

    final sale = await _writer.write<Sale>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        // Fix-wave I2: a cart may still hold a product that a merge, a
        // discard or a dropped create removed (or another device deleted)
        // since it was added. Its sale would reach the BE with
        // product = NULL; refuse it before anything is written.
        final gone = await unavailableIn(txn, {
          for (final l in p.lines)
            if (!l.isCustom) l.productId!,
        });
        if (gone.isNotEmpty) throw SaleProductUnavailableException(gone);
        final n = await _state.nextLocalReceiptCounter(txn);
        final prefix = deviceId.length >= 4
            ? deviceId.substring(0, 4)
            : deviceId;
        final localReceipt = 'L-$prefix-${'$n'.padLeft(6, '0')}';

        final sale = Sale(
          id: saleId,
          shopId: draft.shopId,
          customerId: draft.customerId,
          cashierId: cashier,
          status: 'completed',
          paymentMethod: p.paymentMethod,
          subtotal: p.totals.subtotal,
          discount: p.totals.discount,
          taxAmount: p.totals.taxAmount,
          netAmount: p.totals.netAmount,
          taxRate: p.taxRate,
          taxInclusive: p.taxInclusive,
          taxName: p.taxName,
          receiptNumber: null,
          localReceiptNumber: localReceipt,
          occurredAt: occurredAt,
          version: null,
          syncState: 'pending',
          warnings: const [],
          deviceId: deviceId,
          items: [
            for (var i = 0; i < p.lines.length; i++)
              SaleLine(
                id: lineIds[i],
                productId: p.lines[i].productId,
                productName: p.lines[i].productName,
                isCustom: p.lines[i].isCustom,
                quantity: p.lines[i].quantity,
                unitPrice: p.lines[i].unitPrice,
                unitCost: p.lines[i].unitCost,
                discount: p.lines[i].discount,
                lineTotal: p.totals.lineTotals[i],
                note: p.lines[i].note,
                snapshot: p.lines[i].snapshot,
              ),
          ],
          payments: p.payments,
        );

        final products = {
          for (final l in p.lines)
            if (!l.isCustom) l.productId!,
        };
        await _store.insert(txn, sale);
        // Never pushed before the create of any of its products is `done`
        // (the BE would keep the line with product = NULL). Custom lines
        // reference no product.
        await scope.enqueue(
          entity: 'sale',
          op: 'create',
          entityId: saleId,
          occurredAt: occurredAt,
          payload: _payload(sale, cashier: cashier),
          dependsOn: products.toList(),
        );
        // The outbox row above now counts as pending; re-derive each touched
        // stock row once (quantity = base + pending, base untouched).
        for (final productId in products) {
          await _stock.recompute(txn, productId, draft.shopId);
        }
        await _hook?.call('beforeCommit');
        return sale;
      },
    );
    await _hook?.call('afterCommit');
    return sale;
  }

  /// The subset of [productIds] that cannot be sold: no local `products`
  /// row (merged away, discarded, dropped never-sent create) or an
  /// inactive one (deleted).
  Future<Set<String>> unavailableProductIds(Iterable<String> productIds) {
    final ids = productIds.toSet();
    if (ids.isEmpty) return Future.value(<String>{});
    return _writer.read((db) => unavailableIn(db, ids));
  }

  /// [unavailableProductIds] on [txn].
  static Future<Set<String>> unavailableIn(
    DatabaseExecutor txn,
    Set<String> ids,
  ) async {
    if (ids.isEmpty) return <String>{};
    final list = ids.toList();
    final live = <String>{};
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(
        i,
        i + 500 > list.length ? list.length : i + 500,
      );
      final rows = await txn.query(
        'products',
        columns: ['id', 'json'],
        where: 'id IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      );
      for (final r in rows) {
        if (!_inactive(r['json'])) live.add(r['id'] as String);
      }
    }
    return ids.difference(live);
  }

  static bool _inactive(Object? json) {
    if (json is! String) return false;
    try {
      final j = jsonDecode(json);
      return j is Map && j['is_active'] == false;
    } on FormatException {
      return false;
    }
  }

  /// `sale.create` payload, field names exactly as the BE reads them
  /// (apps/sync/handlers.py `sale_create` + OfflineSaleInputSerializer).
  Map<String, dynamic> _payload(Sale s, {required String? cashier}) => {
    'client_sale_id': s.id,
    'shop': s.shopId,
    'customer': ?s.customerId,
    'payment_method': s.paymentMethod,
    'discount_amount': s.discount,
    'items': [
      for (final l in s.items)
        if (l.isCustom)
          {
            'id': l.id,
            'custom': true,
            'quantity': l.quantity,
            'unit_price': l.unitPrice,
            if (l.note != null && l.note!.isNotEmpty) 'note': l.note,
          }
        else
          {
            'id': l.id,
            'product_id': l.productId,
            'custom': false,
            'quantity': l.quantity,
            'unit_price': l.unitPrice,
            if (l.discount != '0.00') 'discount': l.discount,
            'unit_cost': ?l.unitCost,
            'product_name': l.productName,
          },
    ],
    'occurred_at': s.occurredAt.toUtc().toIso8601String(),
    'cashier': ?cashier,
    'device_id': s.deviceId,
    'tax_rate': s.taxRate,
    'tax_inclusive': s.taxInclusive,
    'tax_name': s.taxName,
    'payments': [for (final x in s.payments) x.toJson()],
    'local_receipt_number': s.localReceiptNumber,
  };

  _Prepared _prepare(SaleDraft d) {
    if (d.shopId.trim().isEmpty) {
      throw const SaleValidationException('Shop is required');
    }
    if (d.lines.isEmpty) {
      throw const SaleValidationException('Cart is empty');
    }
    final lines = <_Line>[];
    for (final l in d.lines) {
      final qty = _parse(l.quantity, 'quantity');
      if (qty.units <= BigInt.zero) {
        throw const SaleValidationException('Invalid product quantity');
      }
      if (qty.scale > 3 &&
          qty.units % BigInt.from(10).pow(qty.scale - 3) != BigInt.zero) {
        throw const SaleValidationException('Quantity has too many decimals');
      }
      final price = _money(l.unitPrice, 'unit price');
      if (price.startsWith('-')) {
        throw const SaleValidationException('Invalid unit price');
      }
      if (l.isCustom && ExactDecimal.parse(price).units <= BigInt.zero) {
        throw const SaleValidationException(
          'A custom amount needs a price greater than 0',
        );
      }
      if (!l.isCustom && (l.productId == null || l.productId!.trim().isEmpty)) {
        throw const SaleValidationException('Product is required');
      }
      lines.add(
        _Line(
          productId: l.productId?.trim(),
          productName: l.productName,
          isCustom: l.isCustom,
          // DRF rejects more than 3 decimal places ('1.5000'): send the
          // exact value with trailing zeros trimmed ('1.5').
          quantity: Decimal3.format(Decimal3.parse(l.quantity)),
          unitPrice: price,
          unitCost: l.unitCost == null || l.unitCost!.trim().isEmpty
              ? null
              : _money(l.unitCost!, 'unit cost'),
          discount: _money(l.discount, 'line discount'),
          note: l.note == null
              ? null
              : (l.note!.trim().length > 120
                    ? l.note!.trim().substring(0, 120)
                    : l.note!.trim()),
          snapshot: l.snapshot,
        ),
      );
    }

    final discount = _money(d.discountAmount, 'discount');
    if (discount.startsWith('-')) {
      throw const SaleValidationException('Discount cannot be negative');
    }
    final taxRate = SaleMath.taxRateOf(d.taxConfig);
    final taxInclusive = d.taxConfig.isActive && d.taxConfig.inclusive;
    final totals = SaleMath.compute(
      lines: [
        for (final l in lines)
          SaleMathLine(
            quantity: l.quantity,
            unitPrice: l.unitPrice,
            discount: l.discount,
          ),
      ],
      discount: discount,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
    );
    if (totals.netAmount.startsWith('-')) {
      throw const SaleValidationException('Discount exceeds the sale total');
    }

    final List<SalePaymentPart> payments;
    final String method;
    if (d.payments == null) {
      method = d.paymentMethod.trim();
      if (method == 'split') {
        throw const SaleValidationException(
          'A split payment needs its payment parts',
        );
      }
      payments = [SalePaymentPart(method: method, amount: totals.netAmount)];
    } else {
      if (d.payments!.isEmpty) {
        throw const SaleValidationException('Payment is required');
      }
      payments = [
        for (final x in d.payments!)
          SalePaymentPart(
            method: x.method.trim(),
            amount: _money(x.amount, 'payment amount'),
          ),
      ];
      method = payments.length == 1 ? payments.single.method : 'split';
    }
    if (!paymentMethods.contains(method) ||
        payments.any((x) => !paymentMethods.contains(x.method))) {
      throw const SaleValidationException('Unknown payment method');
    }
    if (!SaleMath.paymentsMatch([
      for (final x in payments) x.amount,
    ], totals.netAmount)) {
      throw SaleValidationException(
        'Payments do not add up to the sale total (${totals.netAmount})',
      );
    }

    return _Prepared(
      lines: lines,
      totals: totals,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
      taxName: d.taxConfig.isActive ? d.taxConfig.name : '',
      paymentMethod: method,
      payments: payments,
    );
  }

  static ExactDecimal _parse(String raw, String what) {
    try {
      return ExactDecimal.parse(raw);
    } on FormatException {
      throw SaleValidationException('Invalid $what');
    }
  }

  static String _money(String raw, String what) {
    try {
      return SaleMath.money(raw);
    } on FormatException {
      throw SaleValidationException('Invalid $what');
    }
  }
}

class _Line {
  const _Line({
    required this.productId,
    required this.productName,
    required this.isCustom,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.discount,
    required this.note,
    required this.snapshot,
  });

  final String? productId;
  final String productName;
  final bool isCustom;
  final String quantity;
  final String unitPrice;
  final String? unitCost;
  final String discount;
  final String? note;
  final Map<String, dynamic> snapshot;
}

class _Prepared {
  const _Prepared({
    required this.lines,
    required this.totals,
    required this.taxRate,
    required this.taxInclusive,
    required this.taxName,
    required this.paymentMethod,
    required this.payments,
  });

  final List<_Line> lines;
  final SaleTotals totals;
  final String taxRate;
  final bool taxInclusive;
  final String taxName;
  final String paymentMethod;
  final List<SalePaymentPart> payments;
}
