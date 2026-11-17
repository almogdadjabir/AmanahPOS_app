import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../../core/offline/offline_db.dart';
import '../../../../core/time/business_day.dart';
import '../../../pos/data/local/sale_local_store.dart';
import '../models/sale_history_item.dart';

/// Sales history straight from the local `sales` tables (sync engine on).
///
/// Newest first by `(occurred_at, id)` with keyset paging behind the
/// existing page-number interface: the last key of each page is remembered
/// per filter set, so page N+1 seeks instead of skipping rows; an unknown
/// page (filters changed, or a jump) falls back to OFFSET once.
///
/// Every local sale is listed, pulled ones from other devices too. A sale
/// still waiting to sync is flagged `isOfflinePending`; one the server
/// rejected shows as `failed` ("Sync failed") with its reason. Date filters
/// are business-timezone days, the same days the dashboard uses.
class LocalSalesHistory {
  LocalSalesHistory({required OfflineDb db, String? Function()? tenantId})
    : _db = db,
      _tenantId = tenantId ?? _noTenant;

  final OfflineDb _db;

  /// Active business (tenant) id; only its shops' sales are visible.
  final String? Function() _tenantId;

  static String? _noTenant() => null;

  /// filterKey -> page -> last (occurred_at, id) of that page.
  final Map<String, Map<int, (String, String)>> _keys = {};

  Future<SalesHistoryPage> page({
    required int page,
    int pageSize = 20,
    String? search,
    String? shopId,
    String? status,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool onlyUnsynced = false,
    String? timezone,
  }) async {
    final db = await _db.database;
    final visible = SaleLocalStore.visibleShopSql('shop_id', _tenantId());
    final where = <String>[visible.sql];
    final args = <Object?>[...visible.args];

    if (shopId != null && shopId.isNotEmpty) {
      where.add('shop_id = ?');
      args.add(shopId);
    }
    if (status != null && status.isNotEmpty) {
      // Like the legacy list: a server status filter only matches sales the
      // server has. Pending and rejected sales show under "All" (and the
      // unsynced filter) only, so a rejected sale is never "Completed".
      where.add("sync_state = 'synced' AND status = ?");
      args.add(status);
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      where.add('payment_method = ?');
      args.add(paymentMethod);
    }
    if (onlyUnsynced) where.add("sync_state != 'synced'");
    if (dateFrom != null) {
      where.add('occurred_at >= ?');
      args.add(BusinessDay.fromDate(dateFrom).utcTextRange(timezone).start);
    }
    if (dateTo != null) {
      where.add('occurred_at < ?');
      args.add(BusinessDay.fromDate(dateTo).utcTextRange(timezone).end);
    }
    final q = search?.trim() ?? '';
    if (q.isNotEmpty) {
      // Same reference the list shows: server receipt, else the local one.
      where.add(
        "(COALESCE(receipt_number, '') LIKE ? ESCAPE '\\' "
        "OR COALESCE(local_receipt_number, '') LIKE ? ESCAPE '\\')",
      );
      final like =
          '%${q.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';
      args
        ..add(like)
        ..add(like);
    }

    final filterSql = where.join(' AND ');
    final filterKey = '$filterSql|${args.join('|')}|$pageSize';
    final keys = _keys.putIfAbsent(filterKey, () => {});

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sales WHERE $filterSql', args),
    )!;

    final prevKey = page > 1 ? keys[page - 1] : null;
    final List<Map<String, Object?>> rows;
    if (page <= 1 || prevKey != null) {
      rows = await db.rawQuery(
        'SELECT * FROM sales WHERE $filterSql'
        '${prevKey == null ? '' : ' AND (occurred_at < ? OR (occurred_at = ? AND id < ?))'}'
        ' ORDER BY occurred_at DESC, id DESC LIMIT ?',
        [
          ...args,
          if (prevKey != null) ...[prevKey.$1, prevKey.$1, prevKey.$2],
          pageSize + 1,
        ],
      );
    } else {
      rows = await db.rawQuery(
        'SELECT * FROM sales WHERE $filterSql'
        ' ORDER BY occurred_at DESC, id DESC LIMIT ? OFFSET ?',
        [...args, pageSize + 1, (page - 1) * pageSize],
      );
    }

    final hasMore = rows.length > pageSize;
    final pageRows = hasMore ? rows.sublist(0, pageSize) : rows;
    if (pageRows.isNotEmpty) {
      final last = pageRows.last;
      keys[page] = (last['occurred_at'] as String, last['id'] as String);
    }

    final ids = [for (final r in pageRows) r['id'] as String];
    final lines = await _lines(db, ids);
    final refunds = await _refunds(db, ids);
    return SalesHistoryPage(
      items: [
        for (final r in pageRows)
          _item(
            r,
            lines[r['id']] ?? const [],
            refunds[r['id']] ?? const [],
          ),
      ],
      hasMore: hasMore,
      totalCount: total,
    );
  }

  Future<Map<String, List<Map<String, Object?>>>> _lines(
    Database db,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final rows = await db.query(
      'sale_items',
      where: 'sale_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
      orderBy: 'sale_id, position ASC',
    );
    final out = <String, List<Map<String, Object?>>>{};
    for (final r in rows) {
      (out[r['sale_id'] as String] ??= []).add(r);
    }
    return out;
  }

  /// One sale with its lines and refunds (pending and voided included), or
  /// null when it is not in the local tables.
  Future<SaleHistoryItem?> byId(String id) async {
    final db = await _db.database;
    final rows = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final lines = await _lines(db, [id]);
    final refunds = await _refunds(db, [id]);
    return _item(rows.single, lines[id] ?? const [], refunds[id] ?? const []);
  }

  /// Refund rows per sale id, newest first. A `rejected` row is kept (the
  /// UI flags it) but never counted: see [SaleHistoryItem.refundedTotal].
  Future<Map<String, List<Map<String, Object?>>>> _refunds(
    Database db,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final rows = await db.query(
      'sale_refunds',
      where: 'sale_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
      orderBy: 'occurred_at DESC, id DESC',
    );
    final out = <String, List<Map<String, Object?>>>{};
    for (final r in rows) {
      (out[r['sale_id'] as String] ??= []).add(r);
    }
    return out;
  }

  /// Refunded quantity per line id from the non-voided refund rows.
  static Map<String, double> _returned(List<Map<String, Object?>> refunds) {
    final out = <String, double>{};
    for (final r in refunds) {
      if (r['sync_state'] == 'rejected') continue;
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
        if (it is! Map || it['sale_item'] is! String) continue;
        out[it['sale_item'] as String] =
            (out[it['sale_item'] as String] ?? 0) +
            (double.tryParse('${it['quantity']}') ?? 0);
      }
    }
    return out;
  }

  static SaleHistoryItem _item(
    Map<String, Object?> r,
    List<Map<String, Object?>> lines,
    List<Map<String, Object?>> refunds,
  ) {
    final returned = _returned(refunds);
    final syncState = r['sync_state'] as String? ?? 'pending';
    final receipt = (r['receipt_number'] as String?)?.isNotEmpty == true
        ? r['receipt_number'] as String
        : r['local_receipt_number'] as String?;
    return SaleHistoryItem(
      id: r['id'] as String,
      clientSaleId: r['id'] as String,
      receiptNumber: receipt,
      shopId: r['shop_id'] as String?,
      shopName: null,
      customerId: r['customer_id'] as String?,
      customerName: null,
      paymentMethod: (r['payment_method'] as String?) ?? '',
      total: _d(r['net_amount']),
      taxAmount: _d(r['tax_amount']),
      taxRate: _d(r['tax_rate']),
      taxInclusive: r['tax_inclusive'] == 1,
      itemCount: lines.length,
      status: syncState == 'rejected'
          ? SaleHistoryStatus.failed
          : SaleHistoryStatus.fromString(r['status'] as String?),
      createdAt: DateTime.parse(r['occurred_at'] as String).toUtc(),
      isOfflinePending: syncState != 'synced',
      offlineErrorMessage: syncState == 'rejected'
          ? (r['error_message'] as String? ?? r['error_code'] as String?)
          : null,
      items: [
        for (final l in lines)
          SaleHistoryLineItem(
            lineId: l['id'] as String,
            returnedQuantity: returned[l['id'] as String] ?? 0,
            isCustom: l['is_custom'] == 1,
            productId: (l['product_id'] as String?) ?? '',
            productName: (l['product_name'] as String?) ?? '',
            quantity: _d(l['quantity']),
            unitPrice: _d(l['unit_price']),
            subtotal: _d(l['line_total']),
          ),
      ],
      discount: _d(r['discount']),
      refunds: [
        for (final f in refunds)
          SaleHistoryRefund(
            reference: (f['reference'] as String?) ?? (f['id'] as String),
            total: _d(f['total']),
            createdAt:
                DateTime.tryParse('${f['occurred_at']}')?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            syncState: (f['sync_state'] as String?) ?? 'synced',
            errorMessage: (f['error_message'] as String?) ??
                (f['error_code'] as String?),
          ),
      ],
    );
  }

  /// Display-only conversion of a stored decimal string.
  static double _d(Object? v) => double.tryParse('${v ?? ''}') ?? 0;
}
