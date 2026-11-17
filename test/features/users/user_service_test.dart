import 'dart:convert';

import 'package:amana_pos/core/sync/appliers/user_applier.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/users/domain/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

void main() {
  late SaleFixture f;
  late UserService svc;
  final applier = UserApplier();

  setUp(() async {
    SyncScope.current = kScope;
    f = await SaleFixture.on(await openTestDb());
    svc = UserService(writer: f.writer, now: () => f.clock);
  });
  tearDown(() async {
    SyncScope.current = null;
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Map<String, Object?>> row(String id) async => (await f.db.query(
    'synced_entities',
    where: 'entity = ? AND id = ?',
    whereArgs: ['user', id],
  )).single;
  Map<String, dynamic> json(Map<String, Object?> r) =>
      jsonDecode(r['json'] as String) as Map<String, dynamic>;
  Future<List<OutboxEntry>> outbox() async => [
    for (final r in await f.db.query('outbox', orderBy: 'seq'))
      OutboxEntry.fromRow(r),
  ];
  Future<void> serverRow(String id, {String role = 'cashier'}) =>
      f.db.transaction(
        (t) => applier.apply(
          t,
          PullChange(
            seq: 1,
            entity: 'user',
            op: 'upsert',
            id: id,
            version: 3,
            data: {
              'id': id,
              'phone': '+249911',
              'full_name': 'Sara',
              'role': role,
              'default_shop': 's1',
              'is_active': true,
              'status': 'active',
            },
          ),
        ),
      );

  test(
    'create writes row (version NULL, invited) and outbox atomically',
    () async {
      final id = await svc.create(
        phone: '+249911',
        fullName: ' Sara ',
        role: 'cashier',
        shopId: 's1',
      );
      final r = await row(id);
      expect(r['version'], isNull);
      expect(json(r)['status'], 'invited');
      expect(json(r)['default_shop'], 's1');
      final o = (await outbox()).single;
      expect(o.op, 'create');
      expect(o.baseVersion, isNull);
      expect(o.payload, {
        'id': id,
        'phone': '+249911',
        'full_name': 'Sara',
        'role': 'cashier',
        'default_shop_id': 's1',
      });
    },
  );

  test('role-only edit enqueues set_role with the row version', () async {
    await serverRow('u2');
    await svc.update('u2', role: 'manager');
    final o = (await outbox()).single;
    expect(o.op, 'set_role');
    expect(o.baseVersion, 3);
    expect(o.payload, {'role': 'manager'});
  });

  test('shop-only edit enqueues set_shop', () async {
    await serverRow('u2');
    await svc.update('u2', shopId: 's2');
    final o = (await outbox()).single;
    expect(o.op, 'set_shop');
    expect(o.payload, {'default_shop_id': 's2'});
  });

  test('name + role is ONE update with base version', () async {
    await serverRow('u2');
    await svc.update('u2', fullName: 'Sara B', role: 'manager');
    final o = (await outbox()).single;
    expect(o.op, 'update');
    expect(o.baseVersion, 3);
    expect(o.payload, {'full_name': 'Sara B', 'role': 'manager'});
  });

  test('edit behind an unsent create uses update, never set_role', () async {
    final id = await svc.create(
      phone: '+249911',
      fullName: 'Sara',
      role: 'cashier',
    );
    await svc.update(id, role: 'manager');
    final o = (await outbox()).last;
    expect(o.op, 'update');
    expect(o.baseVersion, isNull);
  });

  test('no change writes nothing', () async {
    await serverRow('u2');
    await svc.update('u2', fullName: 'Sara', role: 'cashier');
    expect(await outbox(), isEmpty);
  });

  test('deactivate / reactivate carry no base version', () async {
    await serverRow('u2');
    await svc.setActive('u2', false);
    await svc.setActive('u2', true);
    final os = await outbox();
    expect(os.map((o) => o.op), ['deactivate', 'update']);
    expect(os.every((o) => o.baseVersion == null), isTrue);
    expect(os.last.payload, {'is_active': true});
  });

  test('the owner and the signed-in user cannot be edited', () async {
    await serverRow('owner-1', role: 'owner');
    await serverRow('u1');
    expect(
      () => svc.update('owner-1', fullName: 'X'),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(
      () => svc.setActive('u1', false),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
  });

  test('_server is stored once, at the first edit', () async {
    await serverRow('u2');
    await svc.update('u2', role: 'manager');
    await svc.update('u2', fullName: 'Z');
    final j = json(await row('u2'));
    expect(j['_server']['role'], 'cashier');
    expect(j['_server']['full_name'], 'Sara');
    expect(j['role'], 'manager');
  });
}
