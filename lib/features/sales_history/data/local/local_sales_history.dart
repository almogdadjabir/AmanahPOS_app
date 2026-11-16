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

    final lines = await _lines(db, [
      for (final r in pageRows) r['id'] as String,
    ]);
    return SalesHistoryPage(
      items: [for (final r in pageRows) _item(r, lines[r['id']] ?? const [])],
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

  static SaleHistoryItem _item(
    Map<String, Object?> r,
    List<Map<String, Object?>> lines,
  ) {
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
            isCustom: l['is_custom'] == 1,
            productId: (l['product_id'] as String?) ?? '',
            productName: (l['product_name'] as String?) ?? '',
            quantity: _d(l['quantity']),
            unitPrice: _d(l['unit_price']),
            subtotal: _d(l['line_total']),
          ),
      ],
      discount: _d(r['discount']),
    );
  }

  /// Display-only conversion of a stored decimal string.
  static double _d(Object? v) => double.tryParse('${v ?? ''}') ?? 0;
}
