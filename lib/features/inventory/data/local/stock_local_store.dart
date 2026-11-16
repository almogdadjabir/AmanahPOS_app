import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/sync/contract/sync_contract.dart';
import '../../../../core/sync/decimal3.dart';

/// Local stock ledger. `stock.base_quantity` is the exact server quantity
/// (decimal string); `stock.quantity` is what the UI shows:
/// base + the signed deltas of this device's not-yet-done outbox rows.
///
/// All arithmetic is scaled-integer ([Decimal3]); `quantity` (REAL) and
/// `products.stock_level` get the double only for legacy readers.
class StockLocalStore {
  const StockLocalStore();

  static const _openStatuses = "('pending','inflight','blocked')";

  /// Sum (as a decimal string) of the signed stock effect of every open
  /// `stock.*`, `sale.create` and `inbound.create` outbox row for
  /// ([productId], [shopId]).
  Future<String> pendingDeltaSum(
    DatabaseExecutor db,
    String productId,
    String shopId,
  ) async => Decimal3.format(await pendingDeltaUnits(db, productId, shopId));

  Future<BigInt> pendingDeltaUnits(
    DatabaseExecutor db,
    String productId,
    String shopId,
  ) async {
    // The LIKE only narrows the scan; the payload is parsed and matched
    // exactly below.
    final rows = await db.rawQuery(
      'SELECT entity, op, payload_json FROM outbox '
      'WHERE status IN $_openStatuses '
      "AND ((entity = 'stock') OR (entity = 'sale' AND op = 'create') "
      "OR (entity = 'inbound' AND op = 'create')) "
      "AND payload_json LIKE ? ESCAPE '\\'",
      ['%${_likeEscape(productId)}%'],
    );
    var sum = BigInt.zero;
    for (final r in rows) {
      final Object? decoded;
      try {
        decoded = jsonDecode(r['payload_json'] as String);
      } on FormatException {
        continue;
      }
      if (decoded is! Map) continue;
      final payload = Map<String, dynamic>.from(decoded);
      if (r['entity'] == 'stock') {
        sum += stockRowDelta(
          r['op'] as String,
          payload,
          productId: productId,
          shopId: shopId,
        );
      } else if (r['entity'] == 'inbound') {
        sum += inboundCreateDelta(
          payload,
          productId: productId,
          shopId: shopId,
        );
      } else {
        sum += saleCreateDelta(payload, productId: productId, shopId: shopId);
      }
    }
    return sum;
  }

  static String _likeEscape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Signed effect of one `stock.<op>` payload on ([productId], [shopId]).
  /// add => +delta, remove => -abs(delta), adjust => delta as sent.
  /// `count`/`transfer` (not Phase 1) and malformed payloads count as zero.
  static BigInt stockRowDelta(
    String op,
    Map<String, dynamic> payload, {
    required String productId,
    required String shopId,
  }) {
    if (payload['product_id'] != productId) return BigInt.zero;
    if (payload['shop_id'] != shopId) return BigInt.zero;
    final d = Decimal3.tryParse(payload['delta']);
    if (d == null) return BigInt.zero;
    switch (op) {
      case 'add':
        return d;
      case 'remove':
        return -d.abs();
      case 'adjust':
        return d;
      default:
        return BigInt.zero;
    }
  }

  /// Stock effect of a `sale.create` payload: -quantity for each non-custom
  /// line of the matching product, provided the sale's shop matches.
  static BigInt saleCreateDelta(
    Map<String, dynamic> payload, {
    required String productId,
    required String shopId,
  }) {
    if (payload['shop'] != shopId) return BigInt.zero;
    final items = payload['items'];
    if (items is! List) return BigInt.zero;
    var sum = BigInt.zero;
    for (final it in items) {
      if (it is! Map || it['custom'] == true) continue;
      if (it['product_id'] != productId) continue;
      final q = Decimal3.tryParse(it['quantity']);
      if (q != null) sum -= q;
    }
    return sum;
  }

  /// Stock effect of an `inbound.create` payload (BE InboundReceiveSerializer
  /// shape: `shop_id`, `items[].product_id`, `items[].quantity`):
  /// +quantity for each line of the matching product, provided the shop
  /// matches.
  static BigInt inboundCreateDelta(
    Map<String, dynamic> payload, {
    required String productId,
    required String shopId,
  }) {
    if (payload['shop_id'] != shopId) return BigInt.zero;
    final items = payload['items'];
    if (items is! List) return BigInt.zero;
    var sum = BigInt.zero;
    for (final it in items) {
      if (it is! Map || it['product_id'] != productId) continue;
      final q = Decimal3.tryParse(it['quantity']);
      if (q != null) sum += q;
    }
    return sum;
  }

  /// Product ids of an `inbound.create` payload's lines.
  static Set<String> inboundProducts(Map<String, dynamic> payload) {
    final items = payload['items'];
    return {
      if (items is List)
        for (final it in items)
          if (it is Map && it['product_id'] is String)
            it['product_id'] as String,
    };
  }

  /// (product, shop) pairs a stock outbox row affects (Phase 1 ops only).
  static List<(String, String)> affectedBy(
    String op,
    Map<String, dynamic> payload,
  ) {
    if (op != 'add' && op != 'remove' && op != 'adjust') return const [];
    final p = payload['product_id'];
    final s = payload['shop_id'];
    if (p is String && s is String) return [(p, s)];
    return const [];
  }

  /// Sets the exact server base for ([productId], [shopId]) and recomputes
  /// the displayed quantity (and the products row) in the same executor.
  Future<void> setBase(
    DatabaseExecutor db,
    String productId,
    String shopId,
    String baseQuantity,
  ) async {
    final base = Decimal3.tryParse(baseQuantity);
    if (base == null) {
      throw FormatException('Bad stock quantity: $baseQuantity');
    }
    await _write(db, productId, shopId, base: base);
  }

  /// Re-derives quantity = base + pending deltas without touching the base.
  /// With no local row nothing happens, unless [createIfMissing]: then a row
  /// with base 0 is created (the server base arrives with `stock_after` or
  /// the next pull).
  Future<void> recompute(
    DatabaseExecutor db,
    String productId,
    String shopId, {
    bool createIfMissing = false,
  }) => _write(db, productId, shopId, create: createIfMissing);

  /// The displayed quantity, exactly: base + pending deltas, in units of
  /// 0.001 (base 0 when there is no local row).
  Future<BigInt> currentUnits(
    DatabaseExecutor db,
    String productId,
    String shopId,
  ) async {
    final rows = await db.query(
      'stock',
      columns: ['base_quantity'],
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, shopId],
      limit: 1,
    );
    final base = rows.isEmpty
        ? BigInt.zero
        : (Decimal3.tryParse(rows.first['base_quantity']) ?? BigInt.zero);
    return base + await pendingDeltaUnits(db, productId, shopId);
  }

  /// Applies every entry of a server `stock_after` as the new base.
  Future<void> rebaseFromStockAfter(
    DatabaseExecutor db,
    Iterable<StockAfter> after,
  ) async {
    for (final a in after) {
      if (Decimal3.tryParse(a.quantity) == null) continue;
      await setBase(db, a.productId, a.shopId, a.quantity);
    }
  }

  /// Applies a server stock upsert: [serverId] is the StockLevel id. A row
  /// for the same (product, shop) created locally under another id adopts
  /// the server id (UNIQUE(product_id, shop_id) is never violated).
  Future<void> upsertServerBase(
    DatabaseExecutor db,
    String serverId,
    String productId,
    String shopId,
    String baseQuantity,
  ) async {
    if (Decimal3.tryParse(baseQuantity) == null) {
      throw FormatException('Bad stock quantity: $baseQuantity');
    }
    // A different row already holding the server id would collide on the PK.
    await db.delete(
      'stock',
      where: 'id = ? AND NOT (product_id = ? AND shop_id = ?)',
      whereArgs: [serverId, productId, shopId],
    );
    await db.update(
      'stock',
      {'id': serverId},
      where: 'product_id = ? AND shop_id = ? AND id != ?',
      whereArgs: [productId, shopId, serverId],
    );
    await _write(
      db,
      productId,
      shopId,
      base: Decimal3.parse(baseQuantity),
      insertId: serverId,
    );
  }

  /// Removes the stock row with server id [serverId] (BE delete changes have
  /// no data) and re-derives the product's level from its remaining rows.
  Future<void> deleteByServerId(DatabaseExecutor db, String serverId) async {
    final rows = await db.query(
      'stock',
      columns: ['product_id'],
      where: 'id = ?',
      whereArgs: [serverId],
    );
    if (rows.isEmpty) return;
    await db.delete('stock', where: 'id = ?', whereArgs: [serverId]);
    for (final productId
        in rows.map((r) => r['product_id'] as String).toSet()) {
      await _writeProduct(db, productId);
    }
  }

  Future<void> _write(
    DatabaseExecutor db,
    String productId,
    String shopId, {
    BigInt? base,
    String? insertId,
    bool create = false,
  }) async {
    final rows = await db.query(
      'stock',
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, shopId],
      limit: 1,
    );
    final row = rows.isEmpty ? null : rows.first;
    final effectiveBase =
        base ??
        (row == null
            ? BigInt.zero
            : (Decimal3.tryParse(row['base_quantity']) ?? BigInt.zero));
    if (base == null && row == null && !create) return; // nothing to do
    final pending = await pendingDeltaUnits(db, productId, shopId);
    final qty = Decimal3.toDouble(effectiveBase + pending);
    final now = DateTime.now().toUtc().toIso8601String();

    final jsonMap = _decode(row?['json']);
    jsonMap['product'] ??= productId;
    jsonMap['shop'] ??= shopId;
    jsonMap['quantity'] = qty;
    jsonMap['is_out_of_stock'] = qty <= 0;
    jsonMap['updated_at'] = now;

    if (row == null) {
      await db.insert('stock', {
        'id': insertId ?? '$productId-$shopId',
        'product_id': productId,
        'shop_id': shopId,
        'quantity': qty,
        'base_quantity': Decimal3.format(effectiveBase),
        'json': jsonEncode(jsonMap),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'stock',
        {
          'quantity': qty,
          'base_quantity': Decimal3.format(effectiveBase),
          'json': jsonEncode(jsonMap),
          'updated_at': now,
        },
        where: 'product_id = ? AND shop_id = ?',
        whereArgs: [productId, shopId],
      );
    }
    await _writeProduct(db, productId);
  }

  /// products.stock_level = exact sum of the product's local stock rows
  /// (every shop visible locally); 0 when none remain.
  Future<void> _writeProduct(DatabaseExecutor db, String productId) async {
    final rows = await db.query(
      'products',
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final stockRows = await db.query(
      'stock',
      columns: ['quantity'],
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    var sum = BigInt.zero;
    for (final r in stockRows) {
      sum += Decimal3.tryParse(r['quantity']) ?? BigInt.zero;
    }
    final level = Decimal3.toDouble(sum);
    final jsonMap = _decode(rows.first['json']);
    jsonMap['stock_level'] = level;
    await db.update(
      'products',
      {'stock_level': level, 'json': jsonEncode(jsonMap)},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  static Map<String, dynamic> _decode(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) return Map<String, dynamic>.from(d);
      } on FormatException {
        // fall through
      }
    }
    return <String, dynamic>{};
  }
}
