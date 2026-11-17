import 'dart:convert';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/engine_harness.dart';
import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _uuidRe =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

void main() {
  late SaleFixture f;
  late CatalogActor actor;
  late CategoryService service;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.manager,
    );
    service = CategoryService(
      writer: f.writer,
      actor: () => actor,
      now: () => f.clock,
    );
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Map<String, Object?>> cat(String id) async =>
      (await f.db.query('categories', where: 'id = ?', whereArgs: [id])).single;
  Future<Map<String, dynamic>> catJson(String id) async =>
      jsonDecode((await cat(id))['json'] as String) as Map<String, dynamic>;
  Future<List<Map<String, Object?>>> outbox() =>
      f.db.query('outbox', orderBy: 'seq');
  Map<String, dynamic> payloadOf(Map<String, Object?> r) =>
      jsonDecode(r['payload_json'] as String) as Map<String, dynamic>;

  Future<void> seedSynced(
    String id,
    String name, {
    int version = 3,
    String? parent,
    bool active = true,
  }) async {
    await f.db.insert('categories', {
      'id': id,
      'tenant_id': 't1',
      'parent_id': parent,
      'name': name,
      'version': version,
      'json': jsonEncode({
        'id': id,
        'name': name,
        'parent': parent,
        'is_active': active,
        'product_count': 0,
      }),
    });
  }

  Future<void> seedProductIn(
    String productId,
    String cat, {
    bool active = true,
  }) async {
    await f.db.insert('products', {
      'id': productId,
      'category_id': cat,
      'name': 'P',
      'json': jsonEncode({'id': productId, 'is_active': active}),
    });
  }

  test('cashier is refused and nothing is written', () async {
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.cashier,
    );
    await seedSynced('c1', 'Tea');
    await expectLater(
      service.create(name: 'X'),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.update('c1', EditCategoryRequestDto(name: 'Y')),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.delete('c1'),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    expect((await catJson('c1'))['name'], 'Tea');
    expect(await f.count('categories'), 1);
  });

  test('create writes the row (version null) and one create outbox row '
      'with the client id', () async {
    final id = await service.create(name: ' Drinks ', description: 'Cold');
    expect(id, matches(_uuidRe));
    final row = await cat(id);
    expect(row['version'], isNull);
    expect(row['name'], 'Drinks');
    expect(row['tenant_id'], 't1');
    final j = await catJson(id);
    expect(j['is_active'], true);
    expect(j['product_count'], 0);
    expect(j['children'], isNull);
    final ob = await outbox();
    expect(ob, hasLength(1));
    expect(ob.single['entity'], 'category');
    expect(ob.single['op'], 'create');
    expect(ob.single['entity_id'], id);
    expect(ob.single['status'], 'pending');
    expect(payloadOf(ob.single), {
      'name': 'Drinks',
      'description': 'Cold',
      'id': id,
    });
    expect(await CatalogSupport.pendingEntityIds(f.db, 'category'), {id});
  });

  test('create under a parent whose create is open depends on it', () async {
    final parent = await service.create(name: 'Parent');
    final child = await service.create(name: 'Child', parent: parent);
    final ob = await outbox();
    expect(ob.last['status'], 'blocked');
    expect(jsonDecode(ob.last['depends_on_json'] as String), [parent]);
    expect(payloadOf(ob.last)['parent'], parent);
    expect((await cat(child))['parent_id'], parent);
  });

  test('create under a synced parent has no dependency', () async {
    await seedSynced('p', 'Parent');
    await service.create(name: 'Child', parent: 'p');
    final ob = await outbox();
    expect(ob.single['status'], 'pending');
    expect(ob.single['depends_on_json'], isNull);
  });

  test('duplicate name against local rows is refused', () async {
    await seedSynced('c1', 'Tea');
    await expectLater(
      service.create(name: ' tea '),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    await service.create(name: 'Coffee');
    await expectLater(
      service.update(
        (await f.db.query('categories', where: "name = 'Coffee'")).single['id']
            as String,
        EditCategoryRequestDto(name: 'TEA'),
      ),
      throwsA(isA<CatalogValidationException>()),
    );
  });

  test('update enqueues only changed fields with baseVersion', () async {
    await seedSynced('c1', 'Tea');
    await service.update(
      'c1',
      EditCategoryRequestDto(name: 'Tea', description: 'Hot'),
    );
    final ob = await outbox();
    expect(ob, hasLength(1));
    expect(ob.single['op'], 'update');
    expect(ob.single['base_version'], 3);
    expect(payloadOf(ob.single), {'description': 'Hot'});
    expect((await catJson('c1'))['description'], 'Hot');
    // unchanged -> nothing
    await service.update('c1', EditCategoryRequestDto(description: 'Hot'));
    expect(await outbox(), hasLength(1));
  });

  test('update of an unsent create is a second outbox row', () async {
    final id = await service.create(name: 'Tea');
    await service.update(id, EditCategoryRequestDto(name: 'Chai'));
    final ob = await outbox();
    expect(ob.map((r) => r['op']), ['create', 'update']);
    expect(ob.last['base_version'], isNull);
    expect((await cat(id))['version'], isNull);
  });

  test('category product_count/category_name refreshed on rename', () async {
    await seedSynced('c1', 'Tea');
    await seedProductIn('pp1', 'c1');
    await service.update('c1', EditCategoryRequestDto(name: 'Chai'));
    final pj =
        jsonDecode(
              (await f.db.query('products', where: "id='pp1'")).single['json']
                  as String,
            )
            as Map<String, dynamic>;
    expect(pj['category_name'], 'Chai');
    expect((await cat('c1'))['name'], 'Chai');
  });

  test('delete of a never-sent create removes row and outbox rows', () async {
    final id = await service.create(name: 'Tea');
    await service.update(id, EditCategoryRequestDto(name: 'Chai'));
    await service.delete(id);
    expect(await f.count('categories'), 0);
    expect(await outbox(), isEmpty);
  });

  test(
    'delete of a never-sent create that a row waits on is NOT dropped; '
    'delete is queued after the create and dependents are not failed',
    () async {
      final parent = await service.create(name: 'Parent');
      final child = await service.create(name: 'Child', parent: parent);
      // child is itself never-sent but removing it first is allowed
      await service.delete(child);
      // simulate a waiting row on the parent (e.g. a product create)
      await f.outbox.enqueue(
        f.db,
        entity: 'product',
        op: 'create',
        entityId: 'prod-1',
        payload: const {},
        scope: kScope,
        dependsOn: [parent],
      );
      await service.delete(parent);
      final ob = await outbox();
      expect(ob.where((r) => r['entity_id'] == parent).map((r) => r['op']), [
        'create',
        'delete',
      ]);
      expect((await catJson(parent))['is_active'], false);
      expect(
        ob.firstWhere((r) => r['entity'] == 'product')['status'],
        'blocked',
      );
    },
  );

  test('delete of a synced row marks inactive and enqueues delete', () async {
    await seedSynced('c1', 'Tea');
    await service.delete('c1');
    expect((await catJson('c1'))['is_active'], false);
    final ob = await outbox();
    expect(ob.single['op'], 'delete');
    expect(ob.single['base_version'], 3);
  });

  test('category delete refused with active products/children', () async {
    await seedSynced('c1', 'Tea');
    await seedProductIn('pp1', 'c1');
    await expectLater(
      service.delete('c1'),
      throwsA(isA<CatalogValidationException>()),
    );
    await f.db.update('products', {
      'json': jsonEncode({'id': 'pp1', 'is_active': false}),
    });
    await seedSynced('c2', 'Sub', parent: 'c1');
    await expectLater(
      service.delete('c1'),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    // inactive product + inactive child -> allowed
    await f.db.update('categories', {
      'json': jsonEncode({'id': 'c2', 'is_active': false}),
    }, where: "id = 'c2'");
    await service.delete('c1');
    expect((await outbox()).single['op'], 'delete');
  });

  test(
    'clearing a field to empty is sent as a change; null is unchanged',
    () async {
      await seedSynced('c1', 'Tea');
      await service.update('c1', EditCategoryRequestDto(description: 'Hot'));
      await service.update('c1', EditCategoryRequestDto(description: ''));
      final ob = await outbox();
      expect(payloadOf(ob.last), {'description': ''});
      await service.update('c1', EditCategoryRequestDto(name: 'Tea'));
      expect(await outbox(), hasLength(2));
    },
  );

  test('second delete / update of an inactive category is refused', () async {
    await seedSynced('c1', 'Tea');
    await service.delete('c1');
    await expectLater(
      service.delete('c1'),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.update('c1', EditCategoryRequestDto(name: 'X')),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), hasLength(1));
  });

  test(
    'getCategories hides a soft-deleted category, keeps active ones',
    () async {
      await seedSynced('c1', 'Tea');
      await seedSynced('c2', 'Coffee');
      final cache = OfflineLocalCache(f.odb);
      expect((await cache.getCategories()).map((c) => c.id), ['c2', 'c1']);
      await service.delete('c1');
      expect((await cache.getCategories()).map((c) => c.id), ['c2']);
      expect(
        (await cache.getCategories(includeInactive: true)).map((c) => c.id),
        ['c2', 'c1'],
      );
    },
  );

  group('pull while a local edit is open (engine path)', () {
    late EngineHarness h;
    late CategoryService svc;

    setUp(() async {
      h = await EngineHarness.create();
      h.registry.register(
        CategoryApplier(scopeProvider: () => EngineHarness.scope),
      );
      svc = CategoryService(writer: h.writer, actor: () => actor, now: h.now);
      await h.db.insert('categories', {
        'id': 'c1',
        'tenant_id': 't1',
        'name': 'Tea',
        'version': 3,
        'json': jsonEncode({'id': 'c1', 'name': 'Tea', 'is_active': true}),
      });
    });
    tearDown(() async => h.dispose());

    test('newer server row is deferred, local edit stays; applies once the '
        'outbox row is done', () async {
      await svc.update('c1', EditCategoryRequestDto(name: 'Chai'));
      // Hold the row blocked so the engine pulls without pushing it.
      await h.db.update('outbox', {'status': 'blocked'});
      h.server.seedRow('category', {
        'id': 'c1',
        'name': 'Server',
        'parent': null,
        'is_active': true,
        'version': 5,
      });
      h.build();
      expect(await h.engine!.syncNow(), SyncOutcome.completed);
      final row = (await h.db.query('categories')).single;
      expect(row['name'], 'Chai');
      expect(row['version'], 3);
      final deferred =
          jsonDecode((await h.state.deferredPullJson(h.db))!)
              as Map<String, dynamic>;
      expect(deferred.keys, ['category|c1']);

      await h.db.update('outbox', {'status': 'done'});
      expect(await h.engine!.syncNow(), SyncOutcome.completed);
      final after = (await h.db.query('categories')).single;
      expect(after['name'], 'Server');
      expect(after['version'], 5);
      expect(await h.state.deferredPullJson(h.db), isNull);
    });
  });
}
