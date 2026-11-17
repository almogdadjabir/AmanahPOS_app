import 'dart:convert';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/appliers/vendor_applier.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/engine_harness.dart';
import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _uuidRe =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

void main() {
  late SaleFixture f;
  late CatalogActor actor;
  late VendorService service;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    service = VendorService(
      writer: f.writer,
      actor: () => actor,
      now: () => f.clock,
    );
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Map<String, Object?>> vrow(String id) async =>
      (await f.db.query('vendors', where: 'id = ?', whereArgs: [id])).single;
  Future<Map<String, dynamic>> vjson(String id) async =>
      jsonDecode((await vrow(id))['json'] as String) as Map<String, dynamic>;
  Future<List<Map<String, Object?>>> outbox() =>
      f.db.query('outbox', orderBy: 'seq');
  Map<String, dynamic> payloadOf(Map<String, Object?> r) =>
      jsonDecode(r['payload_json'] as String) as Map<String, dynamic>;

  Future<void> seedSynced(String id, {int version = 4}) =>
      f.db.insert('vendors', {
        'id': id,
        'version': version,
        'json': jsonEncode({
          'id': id,
          'name': 'Acme',
          'phone': '111',
          'email': null,
          'address': null,
          'notes': null,
          'is_active': true,
        }),
      });

  test('cashier is refused and nothing is written', () async {
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.cashier,
    );
    await seedSynced('v1');
    await expectLater(
      service.create(const CreateVendorRequestDto(name: 'X')),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.update('v1', const UpdateVendorRequestDto(name: 'Y')),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.delete('v1'),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    expect(await f.count('vendors'), 1);
    expect((await vjson('v1'))['name'], 'Acme');
  });

  test('create writes the row (version null) and one create outbox row '
      'with the client id', () async {
    final id = await service.create(
      const CreateVendorRequestDto(name: ' Acme ', phone: '555'),
    );
    expect(id, matches(_uuidRe));
    expect((await vrow(id))['version'], isNull);
    final j = await vjson(id);
    expect(j['name'], 'Acme');
    expect(j['phone'], '555');
    expect(j['is_active'], true);
    final ob = await outbox();
    expect(ob, hasLength(1));
    expect(ob.single['entity'], 'vendor');
    expect(ob.single['op'], 'create');
    expect(ob.single['entity_id'], id);
    expect(payloadOf(ob.single), {'name': 'Acme', 'phone': '555', 'id': id});
    expect(await CatalogSupport.pendingEntityIds(f.db, 'vendor'), {id});
  });

  test('duplicate vendor names are allowed (no local uniqueness)', () async {
    await service.create(const CreateVendorRequestDto(name: 'Acme'));
    await service.create(const CreateVendorRequestDto(name: 'Acme'));
    expect(await f.count('vendors'), 2);
  });

  test('empty name is refused', () async {
    await expectLater(
      service.create(const CreateVendorRequestDto(name: '  ')),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
  });

  test('update enqueues only changed fields with baseVersion', () async {
    await seedSynced('v1');
    await service.update(
      'v1',
      const UpdateVendorRequestDto(name: 'Acme', phone: '111', email: 'a@b.c'),
    );
    final ob = await outbox();
    expect(ob.single['op'], 'update');
    expect(ob.single['base_version'], 4);
    expect(payloadOf(ob.single), {'email': 'a@b.c'});
    expect((await vjson('v1'))['email'], 'a@b.c');
    await service.update('v1', const UpdateVendorRequestDto(phone: '111'));
    expect(await outbox(), hasLength(1));
  });

  test('update of an unsent create is a second outbox row', () async {
    final id = await service.create(const CreateVendorRequestDto(name: 'A'));
    await service.update(id, const UpdateVendorRequestDto(name: 'B'));
    final ob = await outbox();
    expect(ob.map((r) => r['op']), ['create', 'update']);
    expect(ob.last['base_version'], isNull);
  });

  test('delete of a never-sent create removes row and outbox rows', () async {
    final id = await service.create(const CreateVendorRequestDto(name: 'A'));
    await service.update(id, const UpdateVendorRequestDto(name: 'B'));
    await service.delete(id);
    expect(await f.count('vendors'), 0);
    expect(await outbox(), isEmpty);
  });

  test('delete of a never-sent create that an inbound waits on is kept: '
      'delete queued after the create, inbound stays blocked', () async {
    final id = await service.create(const CreateVendorRequestDto(name: 'A'));
    await f.outbox.enqueue(
      f.db,
      entity: 'inbound',
      op: 'create',
      entityId: 'in-1',
      payload: const {},
      scope: kScope,
      dependsOn: [id],
    );
    await service.delete(id);
    final ob = await outbox();
    expect(ob.where((r) => r['entity_id'] == id).map((r) => r['op']), [
      'create',
      'delete',
    ]);
    expect(ob.firstWhere((r) => r['entity'] == 'inbound')['status'], 'blocked');
    expect((await vjson(id))['is_active'], false);
  });

  test('delete of a synced row marks inactive and enqueues delete', () async {
    await seedSynced('v1');
    await service.delete('v1');
    expect((await vjson('v1'))['is_active'], false);
    final ob = await outbox();
    expect(ob.single['op'], 'delete');
    expect(ob.single['base_version'], 4);
  });

  test(
    'clearing a field to empty is sent as a change; null is unchanged',
    () async {
      await seedSynced('v1');
      await service.update('v1', const UpdateVendorRequestDto(phone: ''));
      expect(payloadOf((await outbox()).single), {'phone': ''});
      await service.update('v1', const UpdateVendorRequestDto(name: 'Acme'));
      expect(await outbox(), hasLength(1));
    },
  );

  test('second delete / update of an inactive vendor is refused; '
      'reactivating is allowed', () async {
    await seedSynced('v1');
    await service.delete('v1');
    await expectLater(
      service.delete('v1'),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.update('v1', const UpdateVendorRequestDto(name: 'X')),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), hasLength(1));
    await service.update('v1', const UpdateVendorRequestDto(isActive: true));
    expect(await outbox(), hasLength(2));
    expect((await vjson('v1'))['is_active'], true);
  });

  group('pull while a local edit is open (engine path)', () {
    late EngineHarness h;
    late VendorService svc;

    setUp(() async {
      h = await EngineHarness.create();
      h.registry.register(VendorApplier());
      svc = VendorService(writer: h.writer, actor: () => actor, now: h.now);
      await h.db.insert('vendors', {
        'id': 'v1',
        'version': 4,
        'json': jsonEncode({'id': 'v1', 'name': 'Acme', 'is_active': true}),
      });
    });
    tearDown(() async => h.dispose());

    test('newer server row is deferred, local edit stays; applies once the '
        'outbox row is done', () async {
      await svc.update('v1', const UpdateVendorRequestDto(name: 'Mine'));
      await h.db.update('outbox', {'status': 'blocked'});
      h.server.seedRow('vendor', {
        'id': 'v1',
        'name': 'Server',
        'is_active': true,
        'version': 6,
      });
      h.build();
      expect(await h.engine!.syncNow(), SyncOutcome.completed);
      final row = (await h.db.query('vendors')).single;
      expect(jsonDecode(row['json'] as String)['name'], 'Mine');
      expect(row['version'], 4);
      final deferred =
          jsonDecode((await h.state.deferredPullJson(h.db))!)
              as Map<String, dynamic>;
      expect(deferred.keys, ['vendor|v1']);

      await h.db.update('outbox', {'status': 'done'});
      expect(await h.engine!.syncNow(), SyncOutcome.completed);
      final after = (await h.db.query('vendors')).single;
      expect(jsonDecode(after['json'] as String)['name'], 'Server');
      expect(after['version'], 6);
      expect(await h.state.deferredPullJson(h.db), isNull);
    });
  });
}
