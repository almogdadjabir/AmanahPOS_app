import 'dart:convert';

import 'package:amana_pos/core/sync/appliers/customer_applier.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

void main() {
  late SaleFixture f;
  late CustomerService svc;
  final applier = CustomerApplier();

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    svc = CustomerService(writer: f.writer, now: () => f.clock);
  });
  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Map<String, Object?>> row(String id) async =>
      (await f.db.query('customers', where: 'id = ?', whereArgs: [id])).single;
  Future<List<OutboxEntry>> outbox() async => [
    for (final r in await f.db.query('outbox', orderBy: 'seq'))
      OutboxEntry.fromRow(r),
  ];
  Future<void> serverRow(String id, {int version = 3, String name = 'Ali'}) =>
      f.db.transaction(
        (t) => applier.apply(
          t,
          PullChange(
            seq: 1,
            entity: 'customer',
            op: 'upsert',
            id: id,
            version: version,
            data: {
              'id': id,
              'name': name,
              'phone': '0912',
              'email': null,
              'loyalty_points': 40,
              'is_active': true,
            },
          ),
        ),
      );

  test('create writes row (version NULL) and a customer.create outbox row atomically', () async {
    final id = await svc.create(name: ' Ali ', phone: '0912');
    final r = await row(id);
    expect(r['name'], 'Ali');
    expect(r['version'], isNull);
    expect(jsonDecode(r['json'] as String)['loyalty_points'], 0);
    final o = (await outbox()).single;
    expect(o.entity, 'customer');
    expect(o.op, 'create');
    expect(o.entityId, id);
    expect(o.payload, {'id': id, 'name': 'Ali', 'phone': '0912'});
    expect(o.payload.containsKey('loyalty_points'), isFalse);
  });

  test('update sends only changed fields with base_version, never loyalty_points', () async {
    await serverRow('c1');
    await svc.update('c1', name: 'Ali B', phone: '0912');
    final o = (await outbox()).single;
    expect(o.op, 'update');
    expect(o.baseVersion, 3);
    expect(o.payload, {'name': 'Ali B'});
    expect(jsonDecode((await row('c1'))['json'] as String)['loyalty_points'], 40);
  });

  test('update with no change writes nothing', () async {
    await serverRow('c1');
    await svc.update('c1', name: 'Ali');
    expect(await outbox(), isEmpty);
  });

  test('setActive(false) keeps the row and enqueues is_active', () async {
    await serverRow('c1');
    await svc.setActive('c1', false);
    expect(jsonDecode((await row('c1'))['json'] as String)['is_active'], false);
    expect((await outbox()).single.payload, {'is_active': false});
  });

  test('empty name throws CatalogValidationException and writes nothing', () async {
    await expectLater(
      svc.create(name: '  '),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await f.db.query('customers'), isEmpty);
    expect(await outbox(), isEmpty);
  });

  test('unknown customer cannot be edited', () async {
    await expectLater(
      svc.setActive('nope', false),
      throwsA(isA<CatalogValidationException>()),
    );
  });

  test('applied create adopts the server version', () async {
    final id = await svc.create(name: 'Ali');
    final sent = (await outbox()).single;
    await f.db.transaction(
      (t) => applier.onPushResult(
        t,
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.applied,
          entityId: id,
          version: 1,
        ),
      ),
    );
    expect((await row(id))['version'], 1);
  });

  test('conflict_unique keeps the local row and its id (policy A)', () async {
    final id = await svc.create(name: 'Ali', phone: '0912');
    final sent = (await outbox()).single;
    await f.db.transaction(
      (t) => applier.onPushResult(
        t,
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.rejected,
          entityId: id,
          code: 'conflict_unique',
          conflictEntityId: 'existing',
        ),
      ),
    );
    final r = await row(id);
    expect(r['id'], id);
    expect(r['version'], isNull);
  });

  test('a sale for an unsent customer queues after the create and is NOT blocked by it', () async {
    final id = await svc.create(name: 'Ali');
    await f.service().createSale(
      SaleDraft(
        shopId: kShop,
        paymentMethod: 'cash',
        customerId: id,
        lines: const [
          SaleDraftLine.product(
            productId: kP1,
            productName: 'Tea',
            quantity: '1',
            unitPrice: '2.50',
          ),
        ],
      ),
    );
    final rows = await f.db.query('outbox', orderBy: 'seq');
    expect(rows.map((r) => r['entity']), ['customer', 'sale']);
    // A rejected customer create must never fail a sale (money taken).
    expect(rows.last['status'], 'pending');
    expect(rows.last['depends_on_json'], isNull);
  });
}
