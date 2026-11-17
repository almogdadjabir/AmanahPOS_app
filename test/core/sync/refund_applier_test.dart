import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/refund_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_db.dart';

const _id = 'rf000000-0000-4000-8000-000000000001';
const _sale = 'a0000000-0000-4000-8000-000000000002';
const _shop = 's0000000-0000-4000-8000-000000000003';

/// apps/sync/feed.py `ser_refund` (no `version`).
Map<String, dynamic> _refund({
  String id = _id,
  Object? total = '1500.50',
  String? createdAt = '2026-11-16T10:15:30.123456+00:00',
  String? occurredAt = '2026-11-16T09:00:00Z',
  Object? sale = _sale,
  Object? shop = _shop,
}) => {
  'id': id,
  'sale': sale,
  'shop': shop,
  'reference': 'RF-1',
  'total': total,
  'method': 'cash',
  'notes': '',
  'refunded_by': null,
  'occurred_at': occurredAt,
  'created_at': createdAt,
  'items': [
    {'sale_item': 'si1', 'quantity': '1.000', 'amount': '1500.50'},
  ],
};

PullChange _up(Map<String, dynamic> d, {int? version}) => PullChange(
  seq: 0,
  entity: 'refund',
  op: 'upsert',
  id: d['id'] as String,
  version: version,
  data: d,
);

void main() {
  late OfflineDb odb;
  late Database db;
  final a = RefundApplier();

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
  });
  tearDown(() async => db.close());

  Future<void> run(PullChange c) => db.transaction((txn) => a.apply(txn, c));

  Future<List<Map<String, Object?>>> rows() => db.query('sale_refunds');

  test('registered for entity refund writing sale_refunds', () {
    final r = buildSyncAppliers();
    expect(r.of('refund'), isA<RefundApplier>());
    expect(a.tables, {'sale_refunds'});
    expect(syncedLocalTables(r), contains('sale_refunds'));
  });

  test('upsert maps ser_refund; occurred_at = created_at as UTC ISO', () async {
    await run(_up(_refund()));
    final r = (await rows()).single;
    expect(r['id'], _id);
    expect(r['sale_id'], _sale);
    expect(r['shop_id'], _shop);
    expect(r['total'], '1500.50'); // money kept as the wire string
    expect(r['method'], 'cash');
    // The dashboard windows refunds on the refund's created_at (BE
    // SaleRefund.created_at; the BE dashboard filters on it).
    expect(r['occurred_at'], '2026-11-16T10:15:30.123456Z');
    final j = jsonDecode(r['json'] as String) as Map;
    expect(j['reference'], 'RF-1');
    expect(j['occurred_at'], '2026-11-16T09:00:00Z');
    expect(j['items'], hasLength(1));
  });

  test('replay replaces in place; a newer server row updates', () async {
    await run(_up(_refund()));
    await run(_up(_refund()));
    await run(_up(_refund(total: '20.00')));
    final r = (await rows()).single;
    expect(r['total'], '20.00');
  });

  test('delete removes the row', () async {
    await run(_up(_refund()));
    await run(
      const PullChange(seq: 1, entity: 'refund', op: 'delete', id: _id),
    );
    expect(await rows(), isEmpty);
  });

  test('malformed rows are skipped, never throw', () async {
    await run(_up(_refund(total: 'abc')));
    await run(_up(_refund(total: null)));
    await run(_up(_refund(sale: null)));
    await run(_up(_refund(shop: null)));
    await run(_up(_refund(createdAt: null, occurredAt: null)));
    await run(_up(_refund(createdAt: 'not a date', occurredAt: null)));
    await run(
      const PullChange(seq: 0, entity: 'refund', op: 'upsert', id: _id),
    );
    expect(await rows(), isEmpty);
  });

  test('missing created_at falls back to occurred_at', () async {
    await run(_up(_refund(createdAt: null)));
    expect((await rows()).single['occurred_at'], '2026-11-16T09:00:00.000Z');
  });

  test(
    'never touches the sale row (status comes from the pulled sale)',
    () async {
      await db.insert('sales', {
        'id': _sale,
        'shop_id': _shop,
        'status': 'completed',
        'payment_method': 'cash',
        'subtotal': '1500.50',
        'discount': '0',
        'tax_amount': '0',
        'net_amount': '1500.50',
        'tax_rate': '0',
        'tax_inclusive': 0,
        'tax_name': '',
        'occurred_at': '2026-11-16T09:00:00.000Z',
        'sync_state': 'synced',
      });
      final before = await db.query('sales');
      await run(_up(_refund()));
      expect(await db.query('sales'), before);
    },
  );

  test('sale_refunds has the dashboard columns and indexes', () async {
    final cols = (await db.rawQuery(
      'PRAGMA table_info(sale_refunds)',
    )).map((r) => r['name']).toSet();
    expect(
      cols,
      containsAll([
        'id',
        'sale_id',
        'shop_id',
        'total',
        'occurred_at',
        'method',
        'json',
      ]),
    );
    final idx = (await db.rawQuery(
      'PRAGMA index_list(sale_refunds)',
    )).map((r) => r['name']).toSet();
    expect(
      idx,
      containsAll(['idx_sale_refunds_occurred', 'idx_sale_refunds_sale']),
    );
  });
}
