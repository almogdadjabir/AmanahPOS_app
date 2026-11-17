import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/sync/decimal3.dart';
import '../../domain/sale.dart';

/// Local sales tables (authoritative for the POS UI, dashboard and history).
///
/// Money and quantities are stored as exact decimal strings. Only
/// `SaleService` (local writes) and `SaleApplier` (server state) write here,
/// always inside a caller-owned transaction.
class SaleLocalStore {
  const SaleLocalStore();

  static const String sales = 'sales';
  static const String items = 'sale_items';
  static const String payments = 'sale_payments';

  static const Set<String> tables = {sales, items, payments};

  /// Visibility rule for every local sale READ (dashboard, history): only
  /// sales of shops of the ACTIVE business ([tenantId]). `sales` has no
  /// tenant column and local sales are never wiped on logout / business
  /// switch (the pull cursor is per scope and resumes, so a wiped synced
  /// sale would never come back), so this filter is the isolation. A shop
  /// row without a `business_id` counts as the active business's. Unknown
  /// business (profile not loaded yet): nothing is visible; live queries
  /// re-run when it becomes known.
  static ({String sql, List<Object?> args}) visibleShopSql(
    String column,
    String? tenantId,
  ) => tenantId == null || tenantId.isEmpty
      ? (sql: '0 = 1', args: const [])
      : (
          sql:
              '$column IN (SELECT id FROM shops '
              'WHERE business_id = ? OR business_id IS NULL)',
          args: [tenantId],
        );

  /// Idempotent (DB v9). No FK to `products`: a line outlives its product
  /// and renders from `snapshot_json`.
  static Future<void> createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $sales (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        customer_id TEXT,
        cashier_id TEXT,
        status TEXT NOT NULL,
        payment_method TEXT,
        subtotal TEXT NOT NULL,
        discount TEXT NOT NULL,
        tax_amount TEXT NOT NULL,
        net_amount TEXT NOT NULL,
        tax_rate TEXT NOT NULL DEFAULT '0',
        tax_inclusive INTEGER NOT NULL DEFAULT 0,
        tax_name TEXT NOT NULL DEFAULT '',
        receipt_number TEXT,
        local_receipt_number TEXT,
        device_id TEXT,
        occurred_at TEXT NOT NULL,
        received_at TEXT,
        version INTEGER,
        sync_state TEXT NOT NULL,
        warnings_json TEXT,
        error_code TEXT,
        error_message TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        product_id TEXT,
        product_name TEXT NOT NULL DEFAULT '',
        is_custom INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        quantity TEXT NOT NULL,
        unit_price TEXT NOT NULL,
        unit_cost TEXT,
        discount TEXT NOT NULL DEFAULT '0',
        line_total TEXT NOT NULL,
        snapshot_json TEXT NOT NULL DEFAULT '{}'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $payments (
        sale_id TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        method TEXT NOT NULL,
        amount TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_shop_occurred '
      'ON $sales(shop_id, occurred_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_status ON $sales(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON $items(sale_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_payments_sale '
      'ON $payments(sale_id)',
    );
  }

  /// Inserts a new sale with its lines and payments (local create).
  Future<void> insert(DatabaseExecutor db, Sale s) async {
    await db.insert(sales, _saleRow(s));
    await _insertChildren(db, s, const {});
  }

  /// Writes server state for a sale: updates or inserts the sale row and
  /// replaces its lines and payments. A line that already existed keeps its
  /// local `snapshot_json` (the feed has no snapshot).
  Future<void> replaceFromServer(DatabaseExecutor db, Sale s) async {
    final old = await db.query(
      items,
      columns: ['id', 'snapshot_json'],
      where: 'sale_id = ?',
      whereArgs: [s.id],
    );
    final snapshots = {
      for (final r in old) r['id'] as String: r['snapshot_json'] as String,
    };
    final row = _saleRow(s);
    final n = await db.update(sales, row, where: 'id = ?', whereArgs: [s.id]);
    if (n == 0) await db.insert(sales, row);
    await _deleteChildren(db, s.id);
    await _insertChildren(db, s, snapshots);
  }

  Future<void> delete(DatabaseExecutor db, String id) async {
    await _deleteChildren(db, id);
    await db.delete(sales, where: 'id = ?', whereArgs: [id]);
  }

  Future<int?> version(DatabaseExecutor db, String id) async {
    final r = await db.query(
      sales,
      columns: ['version'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return r.isEmpty ? null : r.first['version'] as int?;
  }

  Future<void> markSynced(
    DatabaseExecutor db,
    String id, {
    String? receiptNumber,
    List<String> warnings = const [],
    int? version,
  }) => db.update(
    sales,
    {
      'sync_state': 'synced',
      'receipt_number': ?receiptNumber,
      'warnings_json': jsonEncode(warnings),
      'version': ?version,
      'error_code': null,
      'error_message': null,
    },
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<void> markRejected(
    DatabaseExecutor db,
    String id, {
    String? code,
    String? message,
  }) => db.update(
    sales,
    {'sync_state': 'rejected', 'error_code': code, 'error_message': message},
    where: 'id = ?',
    whereArgs: [id],
  );

  /// A user retried a rejected sale: it is unsynced again. Only a
  /// `rejected` row changes (never a synced one).
  Future<void> markPendingAgain(DatabaseExecutor db, String id) => db.update(
    sales,
    {'sync_state': 'pending', 'error_code': null, 'error_message': null},
    where: "id = ? AND sync_state = 'rejected'",
    whereArgs: [id],
  );

  /// Refunded quantity per sale line (`sale_items.id`, thousandths), from
  /// every non-voided refund row of [saleId]: synced (pulled or settled) and
  /// pending ones. A `rejected` (voided) refund counts for nothing. Reads the
  /// `items: [{sale_item, quantity}]` of each row's `json`.
  Future<Map<String, BigInt>> refundedQuantities(
    DatabaseExecutor db,
    String saleId,
  ) async {
    final rows = await db.query(
      'sale_refunds',
      columns: ['json'],
      where: "sale_id = ? AND sync_state != 'rejected'",
      whereArgs: [saleId],
    );
    final out = <String, BigInt>{};
    for (final r in rows) {
      final raw = r['json'];
      if (raw is! String) continue;
      final Object? j;
      try {
        j = jsonDecode(raw);
      } on FormatException {
        continue;
      }
      final items = j is Map ? j['items'] : null;
      if (items is! List) continue;
      for (final it in items) {
        if (it is! Map) continue;
        final id = it['sale_item'];
        final q = Decimal3.tryParse(it['quantity']);
        if (id is! String || q == null) continue;
        out[id] = (out[id] ?? BigInt.zero) + q;
      }
    }
    return out;
  }

  /// Sets the sale status from its lines and non-voided refunds:
  /// `refunded` when every line is fully returned, `partial_refund` when
  /// something is, else [baseStatus] (the pre-refund status, `completed`).
  /// A cancelled sale is left alone.
  Future<void> recomputeRefundStatus(
    DatabaseExecutor db,
    String saleId, {
    String baseStatus = 'completed',
  }) async {
    final sale = await db.query(
      sales,
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (sale.isEmpty) return;
    final current = sale.first['status'] as String?;
    if (current == 'cancelled') return;
    final done = await refundedQuantities(db, saleId);
    final lines = await db.query(
      items,
      columns: ['id', 'quantity'],
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    var any = false;
    var all = lines.isNotEmpty;
    for (final l in lines) {
      final sold = Decimal3.tryParse(l['quantity']) ?? BigInt.zero;
      final back = done[l['id'] as String] ?? BigInt.zero;
      if (back > BigInt.zero) any = true;
      if (back < sold) all = false;
    }
    var next = !any ? baseStatus : (all ? 'refunded' : 'partial_refund');
    if (!any && (current == 'partial_refund' || current == 'refunded')) {
      // No local refund counts. Only step back when WE voided one; else the
      // status came from the server (another device's refund whose rows are
      // not pulled yet) and must not be downgraded.
      final voided = await db.query(
        'sale_refunds',
        columns: ['id'],
        where: "sale_id = ? AND sync_state = 'rejected'",
        whereArgs: [saleId],
        limit: 1,
      );
      if (voided.isEmpty) next = current!;
    }
    if (next != current) {
      await db.update(
        sales,
        {'status': next},
        where: 'id = ?',
        whereArgs: [saleId],
      );
    }
  }

  Future<Sale?> read(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      sales,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final lineRows = await db.query(
      items,
      where: 'sale_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    final payRows = await db.query(
      payments,
      where: 'sale_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    return Sale(
      id: r['id'] as String,
      shopId: r['shop_id'] as String,
      customerId: r['customer_id'] as String?,
      cashierId: r['cashier_id'] as String?,
      status: r['status'] as String,
      paymentMethod: (r['payment_method'] as String?) ?? '',
      subtotal: r['subtotal'] as String,
      discount: r['discount'] as String,
      taxAmount: r['tax_amount'] as String,
      netAmount: r['net_amount'] as String,
      taxRate: r['tax_rate'] as String,
      taxInclusive: r['tax_inclusive'] == 1,
      taxName: r['tax_name'] as String,
      receiptNumber: r['receipt_number'] as String?,
      localReceiptNumber: r['local_receipt_number'] as String?,
      occurredAt: DateTime.parse(r['occurred_at'] as String).toUtc(),
      version: r['version'] as int?,
      syncState: r['sync_state'] as String,
      warnings: _strings(r['warnings_json']),
      deviceId: r['device_id'] as String?,
      receivedAt: r['received_at'] == null
          ? null
          : DateTime.tryParse(r['received_at'] as String)?.toUtc(),
      items: [
        for (final l in lineRows)
          SaleLine(
            id: l['id'] as String,
            productId: l['product_id'] as String?,
            productName: l['product_name'] as String,
            isCustom: l['is_custom'] == 1,
            quantity: l['quantity'] as String,
            unitPrice: l['unit_price'] as String,
            unitCost: l['unit_cost'] as String?,
            discount: l['discount'] as String,
            lineTotal: l['line_total'] as String,
            note: l['note'] as String?,
            snapshot: _map(l['snapshot_json']),
          ),
      ],
      payments: [
        for (final p in payRows)
          SalePaymentPart(
            method: p['method'] as String,
            amount: p['amount'] as String,
          ),
      ],
    );
  }

  Map<String, Object?> _saleRow(Sale s) => {
    'id': s.id,
    'shop_id': s.shopId,
    'customer_id': s.customerId,
    'cashier_id': s.cashierId,
    'status': s.status,
    'payment_method': s.paymentMethod,
    'subtotal': s.subtotal,
    'discount': s.discount,
    'tax_amount': s.taxAmount,
    'net_amount': s.netAmount,
    'tax_rate': s.taxRate,
    'tax_inclusive': s.taxInclusive ? 1 : 0,
    'tax_name': s.taxName,
    'receipt_number': s.receiptNumber,
    'local_receipt_number': s.localReceiptNumber,
    'device_id': s.deviceId,
    'occurred_at': s.occurredAt.toUtc().toIso8601String(),
    'received_at': s.receivedAt?.toUtc().toIso8601String(),
    'version': s.version,
    'sync_state': s.syncState,
    'warnings_json': jsonEncode(s.warnings),
  };

  Future<void> _insertChildren(
    DatabaseExecutor db,
    Sale s,
    Map<String, String> keepSnapshots,
  ) async {
    var i = 0;
    for (final l in s.items) {
      await db.insert(items, {
        'id': l.id,
        'sale_id': s.id,
        'position': i++,
        'product_id': l.productId,
        'product_name': l.productName,
        'is_custom': l.isCustom ? 1 : 0,
        'note': l.note,
        'quantity': l.quantity,
        'unit_price': l.unitPrice,
        'unit_cost': l.unitCost,
        'discount': l.discount,
        'line_total': l.lineTotal,
        'snapshot_json': keepSnapshots[l.id] ?? jsonEncode(l.snapshot),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    var j = 0;
    for (final p in s.payments) {
      await db.insert(payments, {
        'sale_id': s.id,
        'position': j++,
        'method': p.method,
        'amount': p.amount,
      });
    }
  }

  Future<void> _deleteChildren(DatabaseExecutor db, String id) async {
    await db.delete(items, where: 'sale_id = ?', whereArgs: [id]);
    await db.delete(payments, where: 'sale_id = ?', whereArgs: [id]);
  }

  static List<String> _strings(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final d = jsonDecode(raw);
      if (d is List) return d.map((e) => '$e').toList();
    } on FormatException {
      // fall through
    }
    return const [];
  }

  static Map<String, dynamic> _map(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final d = jsonDecode(raw);
      if (d is Map) return Map<String, dynamic>.from(d);
    } on FormatException {
      // fall through
    }
    return const {};
  }
}
