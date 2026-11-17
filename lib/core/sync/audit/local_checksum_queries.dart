import '../../offline/offline_db.dart';
import '../decimal3.dart';

/// Local totals the self-audit compares with `GET sync/checksum/`.
///
/// `sumTotal` / `sumRevenue` are fixed-decimal strings (money: 2 dp, stock:
/// 3 dp) built from exact integer units, never floating point.
class LocalChecksum {
  const LocalChecksum({
    required this.count,
    required this.sumTotal,
    this.sumRevenue,
    this.nearEdge = false,
  });

  final int count;
  final String sumTotal;
  final String? sumRevenue;

  /// A synced row sits within the edge tolerance of the window cutoff: the
  /// server (created_at) and this device (received_at) may disagree about
  /// which side of the cutoff it is on, so the comparison is inconclusive.
  final bool nearEdge;
}

/// Fixed-decimal text of milli-[units] with [dp] (2 or 3) decimals.
String fixedFromMilli(BigInt units, int dp) {
  final neg = units.isNegative;
  var a = units.abs();
  if (dp == 2) a = a ~/ BigInt.from(10); // money never has a 3rd decimal
  final base = BigInt.from(10).pow(dp);
  final body = '${a ~/ base}.${(a % base).toString().padLeft(dp, '0')}';
  return neg && a != BigInt.zero ? '-$body' : body;
}

/// Only rows with `sync_state = 'synced'` count: a pending or rejected row
/// does not exist on the server. Money and stock use exact [Decimal3] units.
class LocalChecksumQueries {
  LocalChecksumQueries(this._db);

  final OfflineDb _db;

  static const List<String> _revenue = [
    'completed',
    'partial_refund',
    'refunded',
  ];

  /// Sale time = `received_at` (the server's created_at), else `occurred_at`.
  Future<LocalChecksum> sales({
    required DateTime cutoff,
    Duration edgeTolerance = const Duration(minutes: 5),
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT COALESCE(received_at, occurred_at) AS ts, status, net_amount "
      "FROM sales WHERE sync_state = 'synced'",
    );
    var count = 0;
    var total = BigInt.zero;
    var rev = BigInt.zero;
    var edge = false;
    for (final r in rows) {
      final ts = DateTime.tryParse('${r['ts'] ?? ''}')?.toUtc();
      if (ts == null) continue;
      if ((ts.difference(cutoff)).abs() <= edgeTolerance) edge = true;
      if (ts.isBefore(cutoff)) continue;
      final net = Decimal3.tryParse(r['net_amount']) ?? BigInt.zero;
      count++;
      total += net;
      if (_revenue.contains(r['status'])) rev += net;
    }
    return LocalChecksum(
      count: count,
      sumTotal: fixedFromMilli(total, 2),
      sumRevenue: fixedFromMilli(rev, 2),
      nearEdge: edge,
    );
  }

  /// Server rule: refund created in the window OR its sale created in it.
  Future<LocalChecksum> refunds({
    required DateTime cutoff,
    Duration edgeTolerance = const Duration(minutes: 5),
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT r.occurred_at AS rts, "
      "COALESCE(s.received_at, s.occurred_at) AS sts, r.total AS total "
      "FROM sale_refunds r LEFT JOIN sales s ON s.id = r.sale_id "
      "WHERE r.sync_state = 'synced'",
    );
    var count = 0;
    var total = BigInt.zero;
    var edge = false;
    for (final r in rows) {
      final times = [
        DateTime.tryParse('${r['rts'] ?? ''}')?.toUtc(),
        DateTime.tryParse('${r['sts'] ?? ''}')?.toUtc(),
      ].whereType<DateTime>().toList();
      if (times.any((t) => t.difference(cutoff).abs() <= edgeTolerance)) {
        edge = true;
      }
      if (!times.any((t) => !t.isBefore(cutoff))) continue;
      count++;
      total += Decimal3.tryParse(r['total']) ?? BigInt.zero;
    }
    return LocalChecksum(
      count: count,
      sumTotal: fixedFromMilli(total, 2),
      nearEdge: edge,
    );
  }

  /// Server base quantity per product/shop (excludes this device's pending
  /// deltas).
  Future<LocalChecksum> stock() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT base_quantity FROM stock');
    var total = BigInt.zero;
    for (final r in rows) {
      total += Decimal3.tryParse(r['base_quantity']) ?? BigInt.zero;
    }
    return LocalChecksum(
      count: rows.length,
      sumTotal: fixedFromMilli(total, 3),
    );
  }
}
