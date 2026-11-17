import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/audit/local_checksum_queries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_db.dart';

void main() {
  late OfflineDb odb;
  late Database db;
  late LocalChecksumQueries q;
  final cutoff = DateTime.utc(2026, 11, 10, 12);

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    q = LocalChecksumQueries(odb);
  });
  tearDown(() => db.close());

  Future<void> sale(
    String id, {
    String status = 'completed',
    String net = '10.00',
    String sync = 'synced',
    String? received,
    String occurred = '2026-11-15T10:00:00.000Z',
  }) => db.insert('sales', {
    'id': id,
    'shop_id': 's1',
    'status': status,
    'subtotal': net,
    'discount': '0',
    'tax_amount': '0',
    'net_amount': net,
    'occurred_at': occurred,
    'received_at': received,
    'sync_state': sync,
  });

  test('sales: synced only, window, revenue split (Review Focus 1)', () async {
    await sale('a', net: '100.10');
    await sale('b', status: 'cancelled', net: '50.20');
    await sale('p', sync: 'pending', net: '999');
    await sale('r', sync: 'rejected', net: '888');
    await sale('old', received: '2026-11-01T10:00:00.000Z');
    final c = await q.sales(cutoff: cutoff);
    expect(c.count, 2);
    expect(c.sumTotal, '150.30');
    expect(c.sumRevenue, '100.10');
    expect(c.nearEdge, isFalse);
  });

  test('sales: received_at wins over occurred_at', () async {
    await sale(
      'x',
      received: '2026-11-01T10:00:00.000Z',
      occurred: '2026-11-15T10:00:00.000Z',
    );
    expect((await q.sales(cutoff: cutoff)).count, 0);
  });

  test('sales: nearEdge within 5 min, not at 1 h (Review Focus 2)', () async {
    await sale('e', received: '2026-11-10T12:02:00.000Z');
    expect((await q.sales(cutoff: cutoff)).nearEdge, isTrue);
    await db.delete('sales');
    await sale('e', received: '2026-11-10T13:00:00.000Z');
    expect((await q.sales(cutoff: cutoff)).nearEdge, isFalse);
  });

  test('refunds: own or sale time in window, synced only', () async {
    await sale('s-new', received: '2026-11-15T10:00:00.000Z');
    await sale('s-old', received: '2026-11-01T10:00:00.000Z');
    Future<void> refund(
      String id,
      String sale,
      String at,
      String total, {
      String sync = 'synced',
    }) => db.insert('sale_refunds', {
      'id': id,
      'sale_id': sale,
      'total': total,
      'occurred_at': at,
      'sync_state': sync,
    });
    await refund('r1', 's-new', '2026-11-01T00:00:00.000Z', '5.00'); // sale in
    await refund('r2', 's-old', '2026-11-16T00:00:00.000Z', '7.50'); // own in
    await refund('r3', 's-old', '2026-11-01T00:00:00.000Z', '1.00'); // out
    await refund(
      'r4',
      's-new',
      '2026-11-16T00:00:00.000Z',
      '9.00',
      sync: 'pending',
    );
    final c = await q.refunds(cutoff: cutoff);
    expect(c.count, 2);
    expect(c.sumTotal, '12.50');
  });

  test('stock sums base_quantity exactly', () async {
    for (final e in [('1', '0.333'), ('2', '0.667'), ('3', '10')]) {
      await db.insert('stock', {
        'id': e.$1,
        'product_id': 'p${e.$1}',
        'shop_id': 's1',
        'quantity': 0.0,
        'base_quantity': e.$2,
        'json': '{}',
      });
    }
    final c = await q.stock();
    expect(c.count, 3);
    expect(c.sumTotal, '11.000');
  });

  test('cents sum is exact (0.10 + 0.20)', () async {
    await sale('a', net: '0.10');
    await sale('b', net: '0.20');
    expect((await q.sales(cutoff: cutoff)).sumTotal, '0.30');
  });
}
