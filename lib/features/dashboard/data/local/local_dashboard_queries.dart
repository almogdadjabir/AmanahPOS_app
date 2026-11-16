import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../../core/offline/offline_db.dart';
import '../../../../core/sync/db_change_notifier.dart';
import '../../../../core/time/business_day.dart';
import '../../../pos/data/local/sale_local_store.dart';
import '../../../pos/domain/sale_math.dart';
import '../../domain/entities/dashboard_summary.dart';

/// Revenue basis of every dashboard amount (gross, cash, Bankak, payment
/// breakdown, average, sparkline, shift, comparison), as SQL integer cents
/// for the `sales` row aliased [alias].
///
/// The app matches the LIVE BE endpoint `GET sales/dashboard-summary/`
/// (`amanaPOS-be/apps/sales/views.py` `DashboardSummaryView`), which sums
/// `Sale.total_amount` (= local `sales.subtotal`: Σ line totals BEFORE the
/// sale discount and exclusive tax) and groups the payment breakdown by
/// `sale.payment_method` (a split sale is one `split` entry).
/// `amanaPOS-be/docs/sync-contract.md` "Reporting definitions" says
/// `net_amount` and `sale.payments[]` instead; that discrepancy is listed in
/// `docs/BE_GAPS.md`. Switching to the contract is this one line (use
/// `net_amount`) plus [_breakdown] (read `sale_payments`).
String saleRevenueCentsSql([String alias = 's']) => _cents('$alias.subtotal');

/// `REVENUE_STATUSES` (apps/sales/models/sale.py): `pending` and
/// `cancelled` sales are not revenue. A sale the server REJECTED keeps its
/// local status (`completed`) and still counts: it happened.
const List<String> kRevenueStatuses = [
  'completed',
  'partial_refund',
  'refunded',
];

/// Exact integer minor units from a decimal TEXT column.
///
/// Each stored value (money: at most 2 decimals, quantity: at most 3) is
/// rounded to an INTEGER on its own row, which is exact for any value below
/// ~10^13, and only integers are summed. No floating-point accumulation.
String _cents(String col) => 'CAST(ROUND(CAST($col AS REAL) * 100) AS INTEGER)';
String _milli(String col) =>
    'CAST(ROUND(CAST($col AS REAL) * 1000) AS INTEGER)';

/// Reactive dashboard from the local sales tables (authoritative when the
/// sync engine is on). Mirrors `DashboardSummaryView` field by field so the
/// existing Home UI renders unchanged.
class LocalDashboardQueries {
  LocalDashboardQueries({
    required OfflineDb db,
    required DbChangeNotifier notifier,
    DateTime Function()? now,
    String? Function()? tenantId,
    Stream<Object?>? tenantChanges,
  }) : _tenantChanges = tenantChanges,
       _db = db,
       _notifier = notifier,
       _now = now ?? DateTime.now,
       _tenantId = tenantId ?? _noTenant;

  final OfflineDb _db;
  final DbChangeNotifier _notifier;
  final DateTime Function() _now;

  /// Active business (tenant) id; only its shops' sales are visible.
  final String? Function() _tenantId;

  static String? _noTenant() => null;

  /// Fires when the active business may have changed (auth state): live
  /// streams re-evaluate, so "nothing visible yet" is never permanent.
  final Stream<Object?>? _tenantChanges;

  /// Phase 4 adds refund rows; listening to the name now is harmless.
  static const String refundsTable = 'sale_refunds';

  static const Set<String> watchedTables = {
    'sales',
    'sale_items',
    'sale_payments',
    'products',
    // Visibility depends on the active business's shops (re-login: the
    // bootstrap fills `shops` after the first value).
    'shops',
    refundsTable,
  };

  /// "Today" in the business timezone, re-evaluated on every change and at
  /// each hour boundary (sparkline grows, midnight rolls the day over).
  /// The first value comes straight from SQLite.
  Stream<DashboardSummary> watchToday({
    required String? shopId,
    required String timezone,
    String currency = 'SDG',
    String? businessId,
    String? shiftCashierId,
    int topSellersLimit = 5,
  }) {
    late final StreamController<DashboardSummary> out;
    Timer? tick;
    StreamSubscription<DashboardSummary>? inner;
    StreamSubscription<Object?>? tenantSub;

    void start() {
      final now = _now();
      inner?.cancel();
      inner = watchDay(
        day: BusinessDay.of(now, timezone),
        shopId: shopId,
        timezone: timezone,
        currency: currency,
        businessId: businessId,
        shiftCashierId: shiftCashierId,
        topSellersLimit: topSellersLimit,
      ).listen(out.add, onError: out.addError);
      final local = now.toUtc().add(BusinessDay.offsetOf(timezone));
      final toNextHour = Duration(
        microseconds:
            Duration.microsecondsPerHour -
            (local.minute * Duration.microsecondsPerMinute +
                local.second * Duration.microsecondsPerSecond +
                local.millisecond * 1000 +
                local.microsecond),
      );
      tick?.cancel();
      tick = Timer(toNextHour + const Duration(milliseconds: 50), start);
    }

    out = StreamController<DashboardSummary>(
      onListen: () {
        tenantSub = _tenantChanges?.listen((_) => start());
        start();
      },
      onCancel: () async {
        tick?.cancel();
        await tenantSub?.cancel();
        await inner?.cancel();
      },
    );
    return out.stream;
  }

  /// One fixed business [day].
  Stream<DashboardSummary> watchDay({
    required BusinessDay day,
    required String? shopId,
    required String timezone,
    String currency = 'SDG',
    String? businessId,
    String? shiftCashierId,
    int topSellersLimit = 5,
  }) => _notifier.watch(
    tables: watchedTables,
    query: () => summaryFor(
      day: day,
      shopId: shopId,
      timezone: timezone,
      currency: currency,
      businessId: businessId,
      shiftCashierId: shiftCashierId,
      topSellersLimit: topSellersLimit,
    ),
  );

  Future<DashboardSummary> summaryFor({
    required BusinessDay day,
    required String? shopId,
    required String timezone,
    String currency = 'SDG',
    String? businessId,
    String? shiftCashierId,
    int topSellersLimit = 5,
  }) async {
    final db = await _db.database;
    final now = _now().toUtc();
    final range = day.utcTextRange(timezone);
    final tenant = _tenantId();
    final w = _Where(range.start, range.end, shopId, tenant);
    final rev = saleRevenueCentsSql();

    // ── Today aggregates (gross/cash/bankak on the revenue basis) ─────────
    final agg = (await db.rawQuery('''
      SELECT COUNT(*) AS n,
        COALESCE(SUM($rev), 0) AS gross,
        COALESCE(SUM(CASE WHEN s.payment_method = 'cash' THEN $rev END), 0)
          AS cash,
        COALESCE(SUM(CASE WHEN s.payment_method = 'bankak' THEN $rev END), 0)
          AS bankak,
        COALESCE(MAX(s.sync_state != 'synced'), 0) AS unsynced
      FROM sales s WHERE ${w.sql}
    ''', w.args)).single;
    final count = _int(agg['n']);
    final gross = _int(agg['gross']);
    final cash = _int(agg['cash']);
    final bankak = _int(agg['bankak']);
    final unsynced = _int(agg['unsynced']) > 0;

    final breakdown = await _breakdown(db, w);
    final refunds = await _refunds(db, range.start, range.end, shopId, tenant);

    // ── Shift (cashier role only, like the endpoint) ───────────────────────
    ShiftSalesSummary shift = const ShiftSalesSummary(
      mode: 'inferred',
      cashierId: null,
      cashierName: null,
      shiftStartedAt: null,
      grossSalesAmount: 0,
      salesCount: 0,
      averageSaleAmount: 0,
    );
    if (shiftCashierId != null) {
      final r = (await db.rawQuery(
        '''
        SELECT MIN(s.occurred_at) AS started, COALESCE(SUM($rev), 0) AS gross,
          COUNT(*) AS n
        FROM sales s WHERE ${w.sql} AND s.cashier_id = ?
      ''',
        [...w.args, shiftCashierId],
      )).single;
      final g = _int(r['gross']);
      final n = _int(r['n']);
      final started = r['started'] as String?;
      shift = ShiftSalesSummary(
        mode: 'inferred',
        cashierId: shiftCashierId,
        cashierName: null,
        shiftStartedAt: started == null
            ? null
            : DateTime.tryParse(started)?.toUtc().toIso8601String(),
        grossSalesAmount: _money(g),
        salesCount: n,
        averageSaleAmount: _money(_avg(g, n)),
      );
    }

    // ── Hourly sparkline (business-timezone hours, zero-filled) ───────────
    final off =
        ((BusinessDay.offsetOf(timezone).inMinutes % 1440) + 1440) % 1440;
    final hourly = await db.rawQuery('''
      SELECT ((CAST(substr(s.occurred_at, 12, 2) AS INTEGER) * 60
          + CAST(substr(s.occurred_at, 15, 2) AS INTEGER) + $off) / 60) % 24
          AS h,
        SUM($rev) AS amount, COUNT(*) AS n
      FROM sales s WHERE ${w.sql}
      GROUP BY h
    ''', w.args);
    final today = BusinessDay.of(now, timezone);
    final maxHour = day == today
        ? now.add(BusinessDay.offsetOf(timezone)).hour
        : 23;
    // The endpoint only buckets hours up to "now", silently dropping sales
    // stamped later today (another device's clock ahead). Here they are
    // folded into the last bucket so the bars always add up to gross.
    final byHour = <int, (int, int)>{};
    for (final r in hourly) {
      final h = _int(r['h']) > maxHour ? maxHour : _int(r['h']);
      final old = byHour[h] ?? (0, 0);
      byHour[h] = (old.$1 + _int(r['amount']), old.$2 + _int(r['n']));
    }
    final points = [
      for (var h = 0; h <= maxHour; h++)
        SparklinePoint(
          label: _hourLabel(h),
          amount: _money(byHour[h]?.$1 ?? 0),
          salesCount: byHour[h]?.$2 ?? 0,
        ),
    ];
    final firstHour = byHour.isEmpty
        ? null
        : _hourLabel(byHour.keys.reduce((a, b) => a < b ? a : b));

    // ── Top sellers: product lines by Σ quantity (then product id) ────────
    final top = await db.rawQuery('''
      SELECT i.product_id AS pid,
        SUM(${_milli('i.quantity')}) AS q,
        SUM(${_cents('i.line_total')}) AS a,
        MAX(i.product_name) AS line_name,
        p.name AS name, p.thumbnail_url AS thumb
      FROM sales s
        JOIN sale_items i ON i.sale_id = s.id
        LEFT JOIN products p ON p.id = i.product_id
      WHERE ${w.sql} AND i.is_custom = 0 AND i.product_id IS NOT NULL
      GROUP BY i.product_id
    ''', w.args);
    // Phase 4: subtract returned quantity/amount of refund items dated in
    // the window (endpoint: SaleRefundItem by refund.created_at).
    final ranked =
        [
          for (final r in top)
            if (_int(r['q']) > 0) r,
        ]..sort((x, y) {
          final c = _int(y['q']).compareTo(_int(x['q']));
          return c != 0 ? c : '${x['pid']}'.compareTo('${y['pid']}');
        });
    final topSellers = [
      for (final r in ranked.take(topSellersLimit))
        TopSeller(
          productId: '${r['pid']}',
          // Current catalog name like the endpoint; a product not (yet) in
          // the local catalog keeps its line snapshot name.
          name: (r['name'] as String?)?.trim().isNotEmpty == true
              ? r['name'] as String
              : (r['line_name'] as String? ?? ''),
          quantitySold: _int(r['q']) / 1000,
          grossAmount: _money(_int(r['a'])),
          thumbnailUrl: r['thumb'] as String?,
        ),
    ];

    // ── Custom-amount lines (count = lines, like the endpoint) ────────────
    final custom = (await db.rawQuery('''
      SELECT COALESCE(SUM(${_cents('i.line_total')}), 0) AS a, COUNT(*) AS n
      FROM sales s JOIN sale_items i ON i.sale_id = s.id
      WHERE ${w.sql} AND i.is_custom = 1
    ''', w.args)).single;

    // ── Comparison with the previous business day ──────────────────────────
    final prev = day.addDays(-1);
    final prevRange = prev.utcTextRange(timezone);
    final start = day.startUtc(timezone);
    final elapsed = day == today
        ? now.difference(start)
        : const Duration(days: 1);
    final cut = BusinessDay.utcText(prev.startUtc(timezone).add(elapsed));
    final pw = _Where(prevRange.start, prevRange.end, shopId, tenant);
    final p = (await db.rawQuery(
      '''
      SELECT COUNT(*) AS n, COALESCE(SUM($rev), 0) AS gross,
        COALESCE(SUM(CASE WHEN s.occurred_at < ? THEN $rev END), 0) AS same
      FROM sales s WHERE ${pw.sql}
    ''',
      [cut, ...pw.args],
    )).single;
    final prevCount = _int(p['n']);

    return DashboardSummary(
      serverTime: null,
      timezone: timezone,
      currency: currency,
      scope: DashboardScope(
        businessId: businessId,
        shopId: shopId,
        shopName: null,
      ),
      today: TodaySalesSummary(
        date: day.iso,
        grossSalesAmount: _money(gross),
        netSalesAmount: _money(gross - refunds.amount),
        salesCount: count,
        averageSaleAmount: _money(_avg(gross, count)),
        refundAmount: _money(refunds.amount),
        refundCount: refunds.count,
        cashAmount: _money(cash),
        bankakAmount: _money(bankak),
        otherAmount: _money(gross - cash - bankak),
        paymentBreakdown: breakdown,
        refundCashAmount: _money(refunds.cash),
        refundBankakAmount: _money(refunds.bankak),
        customAmount: _money(_int(custom['a'])),
        customCount: _int(custom['n']),
        comparison: prevCount == 0
            ? null
            : SalesComparison(
                date: prev.iso,
                grossSalesAmount: _money(_int(p['gross'])),
                salesCount: prevCount,
                grossSalesAmountSameTime: _money(_int(p['same'])),
              ),
      ),
      shift: shift,
      sparkline: SparklineSummary(
        interval: 'hour',
        points: points,
        firstSaleHour: firstHour,
      ),
      topSellers: topSellers,
      sync: DashboardSyncInfo(
        includesPendingOfflineSales: unsynced,
        lastCalculatedAt: now.toIso8601String(),
      ),
      source: DashboardSummarySource.remote,
      includesLocalPendingSales: unsynced,
    );
  }

  /// Every method with sales, by `sales.payment_method` on the revenue
  /// basis; ordered like the endpoint (`-amount, payment_method`).
  Future<List<PaymentBreakdownItem>> _breakdown(Database db, _Where w) async {
    final rows = await db.rawQuery('''
      SELECT s.payment_method AS m, SUM(${saleRevenueCentsSql()}) AS a,
        COUNT(*) AS n
      FROM sales s WHERE ${w.sql}
      GROUP BY s.payment_method
    ''', w.args);
    final sorted = [...rows]
      ..sort((x, y) {
        final c = _int(y['a']).compareTo(_int(x['a']));
        return c != 0 ? c : '${x['m']}'.compareTo('${y['m']}');
      });
    return [
      for (final r in sorted)
        PaymentBreakdownItem(
          method: (r['m'] as String?) ?? '',
          amount: _money(_int(r['a'])),
          count: _int(r['n']),
        ),
    ];
  }

  /// PHASE 4 MUST LAND BEFORE REAL USE: local refunds are not tracked yet,
  /// so refund figures are 0 and a REST return is not reflected locally.
  ///
  /// Refunds are subtracted on the REFUND date (endpoint: SaleRefund by
  /// `created_at` in the window, method of the original sale). The local
  /// `sale_refunds` table arrives in Phase 4; until then this is zero and
  /// never fails. Phase 4 contract: `sale_refunds(id, sale_id, shop_id,
  /// total TEXT, occurred_at TEXT UTC ISO)`; adjust this one query if the
  /// table differs.
  Future<_Refunds> _refunds(
    Database db,
    String start,
    String end,
    String? shopId,
    String? tenant,
  ) async {
    final exists = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [refundsTable],
    );
    if (exists.isEmpty) return const _Refunds(0, 0, 0, 0);
    final visible = SaleLocalStore.visibleShopSql('r.shop_id', tenant);
    final r = (await db.rawQuery(
      '''
      SELECT COUNT(*) AS n, COALESCE(SUM(${_cents('r.total')}), 0) AS a,
        COALESCE(SUM(CASE WHEN s.payment_method = 'cash'
          THEN ${_cents('r.total')} END), 0) AS cash,
        COALESCE(SUM(CASE WHEN s.payment_method = 'bankak'
          THEN ${_cents('r.total')} END), 0) AS bankak
      FROM $refundsTable r LEFT JOIN sales s ON s.id = r.sale_id
      WHERE r.occurred_at >= ? AND r.occurred_at < ?
        ${shopId == null ? '' : 'AND r.shop_id = ?'}
        AND ${visible.sql}
    ''',
      [start, end, ?shopId, ...visible.args],
    )).single;
    return _Refunds(
      _int(r['a']),
      _int(r['n']),
      _int(r['cash']),
      _int(r['bankak']),
    );
  }

  /// Average in cents, half away from zero (the endpoint rounds a float
  /// to 2 decimals; they can differ only on an exact half-cent tie).
  static int _avg(int cents, int n) => n == 0
      ? 0
      : ExactDecimal.divRoundHalfUp(BigInt.from(cents), BigInt.from(n)).toInt();

  /// The entity carries doubles: convert once, at the end, from exact cents.
  static double _money(int cents) => cents / 100;

  static int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

  static String _hourLabel(int h) => '${h.toString().padLeft(2, '0')}:00';
}

class _Where {
  _Where(String start, String end, String? shopId, String? tenantId)
    : this._(
        start,
        end,
        shopId,
        SaleLocalStore.visibleShopSql('s.shop_id', tenantId),
      );

  _Where._(
    String start,
    String end,
    String? shopId,
    ({String sql, List<Object?> args}) visible,
  ) : sql =
          's.occurred_at >= ? AND s.occurred_at < ? '
          "AND s.status IN ('${kRevenueStatuses.join("','")}')"
          '${shopId == null ? '' : ' AND s.shop_id = ?'}'
          ' AND ${visible.sql}',
      args = [start, end, ?shopId, ...visible.args];

  final String sql;
  final List<Object?> args;
}

class _Refunds {
  const _Refunds(this.amount, this.count, this.cash, this.bankak);

  final int amount;
  final int count;
  final int cash;
  final int bankak;
}
