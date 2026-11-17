// Task 5 (Phase 3): the catalog appliers' `onPushResult` against the
// FakeSyncServer (BE semantics) through the real SyncEngine, services and
// appliers. Spec "Push results" table.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/core/sync/appliers/product_applier.dart';
import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/appliers/stock_applier.dart';
import 'package:amana_pos/core/sync/appliers/vendor_applier.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/engine_harness.dart';
import 'support/fake_sync_server.dart';
import 'support/test_db.dart';

const _scope = 'u1|t1';
const _shop = 'e0000000-0000-4000-8000-000000000001';
const _other = 'a0000000-0000-4000-8000-0000000000aa';
const _otherCat = 'a0000000-0000-4000-8000-0000000000cc';

/// One device: real DB, engine, catalog appliers and services.
class _Device {
  _Device._();

  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late ScenarioTransport transport;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  late SyncEngine engine;
  late CategoryService categories;
  late ProductService products;
  late VendorService vendors;
  late SaleService sales;
  late Directory base;
  final notifier = DbChangeNotifier();
  final registry = ChangeApplierRegistry();
  DateTime clock = DateTime.utc(2026, 11, 17, 9);
  DateTime now() => clock;

  static Future<_Device> create() async {
    final d = _Device._();
    d.odb = await openTestDb();
    d.db = await d.odb.database;
    d.base = await Directory.systemTemp.createTemp('catalog_push_results');
    d.server = FakeSyncServer(now: d.now);
    d.transport = ScenarioTransport(d.server);
    d.outbox = OutboxStore(d.odb, now: d.now);
    d.state = SyncStateStore(d.odb, now: d.now, scope: _scope);
    d.writer = LocalWriter(
      d.odb,
      d.outbox,
      d.notifier,
      scopeProvider: () => _scope,
    );
    d.registry
      ..register(CategoryApplier(scopeProvider: () => _scope))
      ..register(ProductApplier())
      ..register(VendorApplier())
      ..register(SaleApplier())
      ..register(StockApplier());
    d.engine = SyncEngine(
      db: d.odb,
      transport: d.transport,
      outbox: d.outbox,
      state: d.state,
      scopeProvider: () => _scope,
      reachability: ServerReachability(d.transport, now: d.now),
      appliers: d.registry,
      notifier: d.notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(1)),
      now: d.now,
    );
    const actor = CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    d.categories = CategoryService(
      writer: d.writer,
      actor: () => actor,
      now: d.now,
    );
    d.products = ProductService(
      writer: d.writer,
      actor: () => actor,
      uploads: PendingUploadStore(baseDir: () async => d.base.path),
      categories: d.categories,
      now: d.now,
    );
    d.vendors = VendorService(writer: d.writer, actor: () => actor, now: d.now);
    d.sales = SaleService(
      writer: d.writer,
      state: d.state,
      cashierId: () => null,
      now: d.now,
    );
    await d.db.insert('sync_state', {
      'key': 'device_id',
      'value': 'abcd1234-0000-4000-8000-000000000000',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    await d.db.transaction((t) async {
      await d.state.setCursor(t, EngineHarness.seedCursor);
      await d.state.setBootstrapped(t, true);
    });
    return d;
  }

  Future<void> dispose() async {
    await engine.dispose();
    notifier.dispose();
    await db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  }

  Future<SyncOutcome> sync() {
    clock = clock.add(const Duration(hours: 2));
    return engine.syncNow();
  }

  /// Another device writes straight to the server.
  Future<PushResult> other(
    String entity,
    String op,
    String id,
    Map<String, dynamic> payload, {
    int? baseVersion,
  }) async {
    final r = await server
        .forDevice('dev-2')
        .push(
          deviceId: 'dev-2',
          appVersion: '1.0.0',
          mutations: [
            OutboxEntry(
              seq: 1,
              mutationId: 'o-$entity-$op-$id-${server.headSeq}',
              entity: entity,
              op: op,
              entityId: id,
              baseVersion: baseVersion,
              occurredAt: clock,
              payload: payload,
            ),
          ],
          scope: _scope,
        );
    return r.results.single;
  }

  Future<Map<String, Object?>?> row(String table, String id) async {
    final r = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.single;
  }

  Future<Map<String, dynamic>> json(String table, String id) async =>
      jsonDecode((await row(table, id))!['json'] as String)
          as Map<String, dynamic>;

  Future<List<OutboxEntry>> rows(String entityId) async => (await db.query(
    'outbox',
    where: 'entity_id = ?',
    whereArgs: [entityId],
    orderBy: 'seq',
  )).map(OutboxEntry.fromRow).toList();

  Future<OutboxEntry> rowOf(String mutationId) async => OutboxEntry.fromRow(
    (await db.query(
      'outbox',
      where: 'mutation_id = ?',
      whereArgs: [mutationId],
    )).single,
  );

  Future<String> syncedCategory(String name) async {
    final id = await categories.create(name: name);
    expect(await sync(), SyncOutcome.completed);
    return id;
  }

  AddProductRequestDto product(
    String category, {
    String name = 'Cola',
    String price = '12.50',
    String? barcode,
    String? sku,
  }) => AddProductRequestDto(
    name: name,
    price: price,
    category: category,
    unit: 'piece',
    trackInventory: true,
    barcode: barcode,
    sku: sku,
  );
}

void main() {
  late _Device d;

  setUp(() async => d = await _Device.create());
  tearDown(() => d.dispose());

  group('applied / duplicate', () {
    test('applied adopts version and clears pending', () async {
      final cat = await d.categories.create(name: 'Drinks');
      final p = await d.products.create(d.product(cat, barcode: 'B1'));
      final v = await d.vendors.create(
        const CreateVendorRequestDto(name: 'Acme'),
      );
      expect((await d.row('products', p))!['version'], isNull);

      expect(await d.sync(), SyncOutcome.completed);

      for (final (table, id) in [
        ('categories', cat),
        ('products', p),
        ('vendors', v),
      ]) {
        final r = (await d.row(table, id))!;
        expect(r['version'], 1, reason: table);
        expect(r['server_json'], isNotNull, reason: table);
        final server = jsonDecode(r['server_json'] as String) as Map;
        expect(server['id'], id);
        expect(server['version'], 1);
        expect(
          (await d.rows(id)).every((e) => e.status == OutboxStatus.done),
          isTrue,
        );
      }
      expect(
        (jsonDecode((await d.row('products', p))!['server_json'] as String)
            as Map)['barcode'],
        'B1',
      );
      // Synced: an edit now carries base_version 1.
      await d.products.update(p, const UpdateProductRequestDto(price: '13'));
      expect((await d.rows(p)).last.baseVersion, 1);
    });

    test('duplicate behaves like applied', () async {
      final v = await d.vendors.create(
        const CreateVendorRequestDto(name: 'Acme'),
      );
      d.server.dropResponseAfterApply = 1;
      expect(await d.sync(), isNot(SyncOutcome.completed));
      expect((await d.row('vendors', v))!['version'], isNull);
      expect(d.server.tables['vendor']![v]!['version'], 1);

      expect(await d.sync(), SyncOutcome.completed);
      expect(d.transport.pushed.where((e) => e.entityId == v), hasLength(2));
      final r = (await d.row('vendors', v))!;
      expect(r['version'], 1);
      expect(r['server_json'], isNotNull);
      expect((await d.rows(v)).single.status, OutboxStatus.done);
      // Applied once on the server.
      expect(
        d.server.feed.where((c) => c.entity == 'vendor' && c.id == v),
        hasLength(1),
      );
    });

    test('a duplicate replay never rolls a newer local version back', () async {
      final v = await d.vendors.create(
        const CreateVendorRequestDto(name: 'Acme'),
      );
      expect(await d.sync(), SyncOutcome.completed);
      await d.db.update(
        'vendors',
        {'version': 5},
        where: 'id = ?',
        whereArgs: [v],
      );
      final sent = (await d.rows(v)).single;
      await d.db.transaction(
        (t) => VendorApplier().onPushResult(
          t,
          sent,
          PushResult(
            mutationId: sent.mutationId,
            status: PushStatus.duplicate,
            entityId: v,
            version: 1,
          ),
        ),
      );
      expect((await d.row('vendors', v))!['version'], 5);
    });

    test('applied+merged replaces fields from server_state', () async {
      final cat = await d.syncedCategory('Drinks');
      final p = await d.products.create(d.product(cat, price: '10'));
      expect(await d.sync(), SyncOutcome.completed);
      // Another device changes the price meanwhile (server v2).
      await d.other('product', 'update', p, {'price': '11.00'}, baseVersion: 1);
      await d.products.update(
        p,
        const UpdateProductRequestDto(name: 'Cola Zero'),
      );
      final edit = (await d.rows(p)).last;
      expect(edit.baseVersion, 1);
      expect(await d.sync(), SyncOutcome.completed);

      final r = (await d.row('products', p))!;
      expect(r['version'], 3);
      expect(r['name'], 'Cola Zero');
      expect(r['price'], '11.00');
      final j = await d.json('products', p);
      expect(j['price'], '11.00');
      expect(j['name'], 'Cola Zero');
      final server = jsonDecode(r['server_json'] as String) as Map;
      expect(server['price'], '11.00');
      expect(server['version'], 3);
      expect((await d.rowOf(edit.mutationId)).status, OutboxStatus.done);
    });

    test('merged server_state is applied by onPushResult itself (BE snapshot '
        'keys category_id/parent_id)', () async {
      final cat = await d.syncedCategory('Drinks');
      final cat2 = await d.syncedCategory('Snacks');
      final p = await d.products.create(d.product(cat, price: '10'));
      expect(await d.sync(), SyncOutcome.completed);
      await d.products.update(p, const UpdateProductRequestDto(name: 'X'));
      final edit = (await d.rows(p)).last;
      await d.db.transaction(
        (t) => ProductApplier().onPushResult(
          t,
          edit,
          PushResult(
            mutationId: edit.mutationId,
            status: PushStatus.applied,
            entityId: p,
            version: 4,
            merged: true,
            serverState: {
              'id': p,
              'tenant_id': 't1',
              'category_id': cat2,
              'shop_id': _shop,
              'name': 'X',
              'price': '15.00',
              'cost_price': '0.00',
              'is_active': true,
              'image': 'products/x.webp',
              'version': 4,
            },
          ),
        ),
      );
      final r = (await d.row('products', p))!;
      expect(r['version'], 4);
      expect(r['category_id'], cat2);
      expect(r['price'], '15.00');
      final j = await d.json('products', p);
      expect(j['category'], cat2);
      expect(j['category_name'], 'Snacks');
      expect(j.containsKey('category_id'), isFalse);
      expect(j.containsKey('tenant_id'), isFalse);
      expect(j['shop'], _shop, reason: 'snapshot shop_id -> feed shop');
      expect(j.containsKey('shop_id'), isFalse);
      expect(r['image_url'], isNull, reason: 'server_state image is a key');
      // server_json is the pure server snapshot in feed shape.
      final sj = jsonDecode(r['server_json'] as String) as Map;
      expect(sj['shop'], _shop);
      expect(sj['category'], cat2);
      expect(sj['version'], 4);
      for (final k in [
        'shop_id',
        'category_id',
        'category_name',
        'stock_level',
      ]) {
        expect(sj.containsKey(k), isFalse, reason: k);
      }
      expect(
        (jsonDecode((await d.row('categories', cat2))!['json'] as String)
            as Map)['product_count'],
        1,
      );
      expect(
        (jsonDecode((await d.row('categories', cat))!['json'] as String)
            as Map)['product_count'],
        0,
      );
    });

    test(
      'merged result does not overwrite a newer unsent local edit',
      () async {
        final cat = await d.syncedCategory('Drinks');
        final p = await d.products.create(d.product(cat, price: '10'));
        expect(await d.sync(), SyncOutcome.completed);
        await d.products.update(p, const UpdateProductRequestDto(name: 'A'));
        final first = (await d.rows(p)).last;
        await d.products.update(p, const UpdateProductRequestDto(price: '20'));
        await d.db.transaction((t) async {
          await t.update(
            'outbox',
            {'status': 'done'},
            where: 'mutation_id = ?',
            whereArgs: [first.mutationId],
          );
          await ProductApplier().onPushResult(
            t,
            first,
            PushResult(
              mutationId: first.mutationId,
              status: PushStatus.applied,
              entityId: p,
              version: 3,
              merged: true,
              serverState: {
                'id': p,
                'name': 'A',
                'price': '11.00',
                'version': 3,
              },
            ),
          );
        });
        final r = (await d.row('products', p))!;
        expect(r['price'], '20', reason: 'the pending local edit still shows');
        final server = jsonDecode(r['server_json'] as String) as Map;
        expect(server['price'], '11.00');
      },
    );
  });

  group('rejected', () {
    test('conflict_unique leaves the local row and marks the outbox row '
        'rejected with conflict_entity_id', () async {
      final cat = await d.syncedCategory('Drinks');
      await d.other('product', 'create', _other, {
        'name': 'Theirs',
        'price': '1',
        'barcode': 'B1',
      });
      final p = await d.products.create(d.product(cat, barcode: 'B1'));
      expect(await d.sync(), SyncOutcome.completed);

      final row = (await d.rows(p)).single;
      expect(row.status, OutboxStatus.rejected);
      expect(row.errorCode, 'conflict_unique');
      expect(row.errorEntityId, _other);
      expect(row.errorMessage, isNotEmpty);
      final local = (await d.row('products', p))!;
      expect(local['id'], p, reason: 'no id rewrite');
      expect(local['version'], isNull);
      expect(local['server_json'], isNull);
      expect(local['barcode'], 'B1');
    });

    test('conflict_unique for category (name per parent) and vendor '
        '(name, case-insensitive)', () async {
      await d.other('category', 'create', _otherCat, {'name': 'Drinks'});
      await d.other('vendor', 'create', _other, {'name': 'Acme Ltd'});
      final cat = await d.categories.create(name: 'Drinks');
      final v = await d.vendors.create(
        const CreateVendorRequestDto(name: 'ACME LTD'),
      );
      expect(await d.sync(), SyncOutcome.completed);
      final c = (await d.rows(cat)).single;
      expect(
        [c.status, c.errorCode, c.errorEntityId],
        [OutboxStatus.rejected, 'conflict_unique', _otherCat],
      );
      final vr = (await d.rows(v)).single;
      expect(
        [vr.status, vr.errorCode, vr.errorEntityId],
        [OutboxStatus.rejected, 'conflict_unique', _other],
      );
      expect(await d.row('categories', cat), isNotNull);
      expect(await d.row('vendors', v), isNotNull);
    });

    test(
      'entity_deleted on update keeps local row inactive and rejected',
      () async {
        final v = await d.vendors.create(
          const CreateVendorRequestDto(name: 'Acme'),
        );
        expect(await d.sync(), SyncOutcome.completed);
        await d.vendors.update(v, const UpdateVendorRequestDto(phone: '0912'));
        final edit = (await d.rows(v)).last;
        d.transport.scripted[edit.mutationId] = PushResult(
          mutationId: edit.mutationId,
          status: PushStatus.rejected,
          entityId: v,
          code: 'entity_deleted',
          message: 'The record was deleted.',
        );
        expect(await d.sync(), SyncOutcome.completed);
        final r = await d.rowOf(edit.mutationId);
        expect(
          [r.status, r.errorCode],
          [OutboxStatus.rejected, 'entity_deleted'],
        );
        expect(await d.row('vendors', v), isNotNull);
        expect((await d.json('vendors', v))['is_active'], isFalse);
      },
    );

    test('entity_deleted on update against the fake: rejected, and the pulled '
        'delete then removes the row', () async {
      final cat = await d.syncedCategory('Drinks');
      await d.other('category', 'delete', cat, const {});
      await d.categories.update(cat, EditCategoryRequestDto(name: 'Juice'));
      final edit = (await d.rows(cat)).last;
      expect(await d.sync(), SyncOutcome.completed);
      final r = await d.rowOf(edit.mutationId);
      expect(
        [r.status, r.errorCode],
        [OutboxStatus.rejected, 'entity_deleted'],
      );
      expect(await d.row('categories', cat), isNull);
    });

    test(
      'forbidden / limit_exceeded / validation_error keep row with message',
      () async {
        final cat = await d.syncedCategory('Drinks');
        // limit_exceeded (plan allows 0 more products)
        d.server.productLimit = 0;
        final p = await d.products.create(d.product(cat));
        // forbidden: this device's user is a cashier on the server
        final v = await d.vendors.create(
          const CreateVendorRequestDto(name: 'A'),
        );
        // validation_error with an empty message: errors{} gives the text
        final c2 = await d.categories.create(name: 'Snacks');
        final c2row = (await d.rows(c2)).single;
        d.transport.scripted[c2row.mutationId] = PushResult(
          mutationId: c2row.mutationId,
          status: PushStatus.rejected,
          entityId: c2,
          code: 'validation_error',
          message: '',
          errors: const {
            'name': ['Ensure this field has no more than 100 characters.'],
          },
        );
        d.server.role = 'cashier';
        expect(await d.sync(), SyncOutcome.completed);

        final pr = (await d.rows(p)).single;
        // forbidden comes first for a cashier: check each code in its own run
        expect(pr.status, OutboxStatus.rejected);
        expect(pr.errorCode, 'forbidden');
        expect(pr.errorMessage, isNotEmpty);
        final vr = (await d.rows(v)).single;
        expect([vr.status, vr.errorCode], [OutboxStatus.rejected, 'forbidden']);
        final cr = await d.rowOf(c2row.mutationId);
        expect(
          [cr.status, cr.errorCode, cr.errorMessage],
          [
            OutboxStatus.rejected,
            'validation_error',
            'Ensure this field has no more than 100 characters.',
          ],
        );
        for (final (t, id) in [
          ('products', p),
          ('vendors', v),
          ('categories', c2),
        ]) {
          expect(await d.row(t, id), isNotNull, reason: t);
        }

        // Owner again: the product create now hits the plan limit.
        d.server.role = 'owner';
        final p2 = await d.products.create(d.product(cat, name: 'Tea'));
        expect(await d.sync(), SyncOutcome.completed);
        final p2r = (await d.rows(p2)).single;
        expect(
          [p2r.status, p2r.errorCode],
          [OutboxStatus.rejected, 'limit_exceeded'],
        );
        expect(p2r.errorMessage, contains('0'));
        expect(await d.row('products', p2), isNotNull);
      },
    );

    test('not_found keeps the row with the server message', () async {
      final v = await d.vendors.create(const CreateVendorRequestDto(name: 'A'));
      expect(await d.sync(), SyncOutcome.completed);
      d.server.tables['vendor']!.remove(v); // server lost it (not a delete)
      await d.vendors.update(v, const UpdateVendorRequestDto(phone: '1'));
      expect(await d.sync(), SyncOutcome.completed);
      final r = (await d.rows(v)).last;
      expect([r.status, r.errorCode], [OutboxStatus.rejected, 'not_found']);
      expect(r.errorMessage, isNotEmpty);
      expect(await d.row('vendors', v), isNotNull);
    });
  });

  group('rejected create cascades', () {
    test('rejected create fails later edit and delete of the same entity with '
        'dependency_failed', () async {
      final cat = await d.syncedCategory('Drinks');
      await d.other('product', 'create', _other, {
        'name': 'Theirs',
        'price': '1',
        'barcode': 'B1',
      });
      // Opening stock waits on the create, so the delete below is queued
      // (not dropped) behind the create.
      final p = await d.products.create(
        d.product(cat, barcode: 'B1'),
        initialQuantity: '5',
        shopId: _shop,
      );
      await d.products.update(p, const UpdateProductRequestDto(name: 'Mine'));
      await d.products.delete(p);
      final mine = await d.rows(p);
      expect(mine.map((e) => e.op), ['create', 'update', 'delete']);
      final stockRow = (await d.db.query(
        'outbox',
        where: "entity = 'stock'",
      )).map(OutboxEntry.fromRow).single;

      expect(await d.sync(), SyncOutcome.completed);

      final after = await d.rows(p);
      expect(after[0].status, OutboxStatus.rejected);
      expect(after[0].errorCode, 'conflict_unique');
      for (final e in [...after.skip(1), await d.rowOf(stockRow.mutationId)]) {
        expect(e.status, OutboxStatus.rejected, reason: e.op);
        expect(e.errorCode, 'dependency_failed', reason: e.op);
      }
      expect(
        d.transport.pushed
            .where((e) => e.entityId == p || e.entity == 'stock')
            .map((e) => e.mutationId),
        [after[0].mutationId],
        reason: 'nothing behind the rejected create is sent',
      );
      expect(d.engine.current.pending, 0);
    });

    test('rejected category create fails the product that depends on it '
        '(and that product\'s own later edit)', () async {
      await d.other('category', 'create', _otherCat, {'name': 'Drinks'});
      final cat = await d.categories.create(name: 'Drinks');
      final p = await d.products.create(d.product(cat));
      await d.products.update(p, const UpdateProductRequestDto(price: '3'));
      expect((await d.rows(p)).first.status, OutboxStatus.blocked);

      expect(await d.sync(), SyncOutcome.completed);

      expect((await d.rows(cat)).single.errorCode, 'conflict_unique');
      final prows = await d.rows(p);
      expect(prows.map((e) => e.status), [
        OutboxStatus.rejected,
        OutboxStatus.rejected,
      ]);
      expect(prows.map((e) => e.errorCode), [
        'dependency_failed',
        'dependency_failed',
      ]);
      expect(d.transport.pushed.where((e) => e.entityId == p), isEmpty);
    });

    test('a rejected UPDATE fails nothing behind it; the later edit of the '
        'row is still sent (ruling I2)', () async {
      final cat = await d.syncedCategory('Drinks');
      await d.other('product', 'create', _other, {
        'name': 'T',
        'barcode': 'B9',
      });
      final p = await d.products.create(d.product(cat));
      expect(await d.sync(), SyncOutcome.completed);
      await d.products.update(p, const UpdateProductRequestDto(barcode: 'B9'));
      await d.products.update(p, const UpdateProductRequestDto(name: 'Later'));
      expect(await d.sync(), SyncOutcome.completed);
      final rows = await d.rows(p);
      expect(rows[1].errorCode, 'conflict_unique');
      expect(rows[2].status, OutboxStatus.done, reason: 'not held, not failed');
      expect(d.server.tables['product']![p]!['name'], 'Later');
    });

    test(
      'server_json of a plain applied result carries no local-only keys',
      () async {
        final cat = await d.syncedCategory('Drinks');
        final p = await d.products.create(d.product(cat));
        expect(await d.sync(), SyncOutcome.completed);
        for (final (t, id) in [('products', p), ('categories', cat)]) {
          final sj =
              jsonDecode((await d.row(t, id))!['server_json'] as String) as Map;
          for (final k in [
            'category_name',
            'stock_level',
            'product_count',
            'children',
            'tenant',
          ]) {
            expect(sj.containsKey(k), isFalse, reason: '$t $k');
          }
        }
      },
    );

    test(
      'price edit rejected, then a second price edit is sent and applied',
      () async {
        final cat = await d.syncedCategory('Drinks');
        final p = await d.products.create(d.product(cat, price: '10'));
        expect(await d.sync(), SyncOutcome.completed);
        await d.products.update(p, const UpdateProductRequestDto(price: '12'));
        final first = (await d.rows(p)).last;
        d.transport.scripted[first.mutationId] = PushResult(
          mutationId: first.mutationId,
          status: PushStatus.rejected,
          entityId: p,
          code: 'validation_error',
          message: 'bad price',
        );
        expect(await d.sync(), SyncOutcome.completed);
        expect((await d.rowOf(first.mutationId)).status, OutboxStatus.rejected);

        await d.products.update(p, const UpdateProductRequestDto(price: '14'));
        final second = (await d.rows(p)).last;
        expect(second.baseVersion, 1);
        expect(await d.sync(), SyncOutcome.completed);
        expect((await d.rowOf(second.mutationId)).status, OutboxStatus.done);
        expect(d.server.tables['product']![p]!['price'], '14');
        final r = (await d.row('products', p))!;
        expect([r['version'], r['price']], [2, '14']);
        expect(
          (await d.rowOf(first.mutationId)).status,
          OutboxStatus.rejected,
          reason: 'still waits for the user',
        );
      },
    );

    test(
      'a pull of a newer server row for a product with only a rejected '
      'row is applied (not deferred); the rejected edit keeps its payload',
      () async {
        final cat = await d.syncedCategory('Drinks');
        final p = await d.products.create(d.product(cat, price: '10'));
        expect(await d.sync(), SyncOutcome.completed);
        await d.products.update(p, const UpdateProductRequestDto(price: '20'));
        final edit = (await d.rows(p)).last;
        d.transport.scripted[edit.mutationId] = PushResult(
          mutationId: edit.mutationId,
          status: PushStatus.rejected,
          entityId: p,
          code: 'validation_error',
          message: 'no',
        );
        expect(await d.sync(), SyncOutcome.completed);
        expect((await d.row('products', p))!['price'], '20');

        await d.other('product', 'update', p, {
          'name': 'Theirs',
        }, baseVersion: 1);
        expect(await d.sync(), SyncOutcome.completed);
        expect(await d.state.deferredPullJson(d.db), isNull);
        final r = (await d.row('products', p))!;
        expect([r['version'], r['name'], r['price']], [2, 'Theirs', '10']);
        final kept = await d.rowOf(edit.mutationId);
        expect(kept.status, OutboxStatus.rejected);
        expect(kept.payload['price'], '20');
      },
    );

    test(
      'retrying the rejected create revives the rows it failed (M1)',
      () async {
        await d.other('category', 'create', _otherCat, {'name': 'Drinks'});
        final cat = await d.categories.create(name: 'Drinks');
        final p = await d.products.create(
          d.product(cat),
          initialQuantity: '2',
          shopId: _shop,
        );
        await d.products.update(p, const UpdateProductRequestDto(price: '3'));
        // An unrelated row that failed for another reason stays rejected.
        final v = await d.vendors.create(
          const CreateVendorRequestDto(name: 'V'),
        );
        final vrow = (await d.rows(v)).single;
        d.transport.scripted[vrow.mutationId] = PushResult(
          mutationId: vrow.mutationId,
          status: PushStatus.rejected,
          entityId: v,
          code: 'validation_error',
          message: 'bad',
        );
        expect(await d.sync(), SyncOutcome.completed);
        final create = (await d.rows(cat)).single;
        expect(create.status, OutboxStatus.rejected);
        expect(
          (await d.db.query('outbox', where: "status = 'rejected'")).length,
          5,
        );

        // The user renames the other category on the server side (fixing the
        // clash) and retries.
        await d.other('category', 'update', _otherCat, {'name': 'Old drinks'});
        d.transport.scripted.clear();
        expect(await d.outbox.retryRejected(create.mutationId), isTrue);
        final prows = await d.rows(p);
        expect(prows.map((e) => e.status), [
          OutboxStatus.blocked,
          OutboxStatus.pending,
        ]);
        expect(prows.every((e) => e.errorCode == null), isTrue);
        final stock = OutboxEntry.fromRow(
          (await d.db.query('outbox', where: "entity = 'stock'")).single,
        );
        expect(stock.status, OutboxStatus.blocked);
        expect((await d.rowOf(vrow.mutationId)).status, OutboxStatus.rejected);

        expect(await d.sync(), SyncOutcome.completed);
        expect(await d.sync(), SyncOutcome.completed);
        for (final e in [create, ...prows, stock]) {
          expect(
            (await d.rowOf(e.mutationId)).status,
            OutboxStatus.done,
            reason: '${e.entity}.${e.op}',
          );
        }
        expect(d.server.stockQuantity(p, _shop), '2');
      },
    );
  });

  test('deleting a create whose response was lost does not drop it (the '
      'server has the row): a delete follows it', () async {
    final v = await d.vendors.create(const CreateVendorRequestDto(name: 'A'));
    d.server.dropResponseAfterApply = 1;
    expect(await d.sync(), isNot(SyncOutcome.completed));
    expect((await d.rows(v)).single.status, OutboxStatus.pending);
    expect(d.server.tables['vendor']![v]!['is_active'], isTrue);

    await d.vendors.delete(v);
    expect((await d.rows(v)).map((e) => e.op), ['create', 'delete']);
    expect(await d.sync(), SyncOutcome.completed);
    expect(d.server.tables['vendor']![v]!['is_active'], isFalse);
    expect(await d.row('vendors', v), isNull);
  });

  test('a never-claimed create is still dropped by a local delete', () async {
    final v = await d.vendors.create(const CreateVendorRequestDto(name: 'A'));
    await d.vendors.delete(v);
    expect(await d.rows(v), isEmpty);
    expect(await d.row('vendors', v), isNull);
  });

  test('BE finding 1 (client stopgap, fix-wave I1): a sale in the same push '
      'as a rejected product edit comes back dependency_failed; with no open '
      'local create behind it the sale is retried, not rejected, and lands '
      'alone exactly once; local stock never goes back up', () async {
    final cat = await d.syncedCategory('Drinks');
    final p = await d.products.create(
      d.product(cat, price: '5'),
      initialQuantity: '5',
      shopId: _shop,
    );
    expect(await d.sync(), SyncOutcome.completed);
    // Another device deletes the product; this device (not yet pulled)
    // edits it and sells it: both go in ONE push, edit first.
    await d.other('product', 'delete', p, const {});
    await d.products.update(p, const UpdateProductRequestDto(price: '6'));
    final sale = await d.sales.createSale(
      SaleDraft(
        shopId: _shop,
        paymentMethod: 'cash',
        lines: [
          SaleDraftLine.product(
            productId: p,
            productName: 'Cola',
            quantity: '2',
            unitPrice: '5',
          ),
        ],
      ),
    );
    final saleRow = (await d.rows(sale.id)).single;
    expect(saleRow.status, OutboxStatus.pending, reason: 'create is done');
    Future<num?> localQty() async =>
        (await d.db.query(
              'stock',
              where: 'product_id = ? AND shop_id = ?',
              whereArgs: [p, _shop],
            )).firstOrNull?['quantity']
            as num?;
    expect(await localQty(), 3);

    expect(await d.sync(), SyncOutcome.completed);
    final edit = (await d.rows(p)).last;
    expect(edit.errorCode, 'entity_deleted');
    // The first push really did hit BE finding 1 ...
    expect(
      d.transport.pushed.where((e) => e.mutationId == saleRow.mutationId),
      hasLength(2),
      reason: 'sent with the edit, then alone',
    );
    // ... and the sale still landed, once, without any user action.
    final after = await d.rowOf(saleRow.mutationId);
    expect([after.status, after.errorCode], [OutboxStatus.done, null]);
    expect(d.server.tables['sale']!.keys, [sale.id]);
    expect(
      d.server.feed.where((c) => c.entity == 'sale' && c.id == sale.id),
      hasLength(1),
    );
    expect(d.server.stockQuantity(p, _shop), '3');
    expect(
      (await d.db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [sale.id],
      )).single['sync_state'],
      'synced',
    );
    expect(await localQty(), anyOf(isNull, 3), reason: 'never back up to 5');
    expect(d.engine.current.rejected, 1, reason: 'only the edit');
  });

  test('a dependency_failed row whose dependency create is still open (here: '
      'rejected) stays rejected (I1 guard)', () async {
    final cat = await d.syncedCategory('Drinks');
    final p = await d.products.create(d.product(cat));
    final row = (await d.rows(p)).single;
    d.transport.scripted[row.mutationId] = PushResult(
      mutationId: row.mutationId,
      status: PushStatus.rejected,
      entityId: p,
      code: 'dependency_failed',
      message: 'dep',
      dependsOn: [cat],
    );
    // The category create is still open locally: simulate by re-opening it.
    await d.db.update(
      'outbox',
      {'status': 'rejected', 'error_code': 'conflict_unique'},
      where: "entity_id = ? AND op = 'create'",
      whereArgs: [cat],
    );
    expect(await d.sync(), SyncOutcome.completed);
    final r = await d.rowOf(row.mutationId);
    expect(
      [r.status, r.errorCode],
      [OutboxStatus.rejected, 'dependency_failed'],
    );

    // M9: the row the BE failed (with its own message) is revived when the
    // create it named is retried; matched by column, not by message text.
    expect(r.errorMessage, 'dep');
    final cr = (await d.rows(cat)).single;
    expect(await d.outbox.retryRejected(cr.mutationId), isTrue);
    expect((await d.rowOf(row.mutationId)).status, OutboxStatus.blocked);
  });

  test('delete converges on entity_deleted', () async {
    final c = await d.syncedCategory('C');
    await d.categories.delete(c); // synced, no products: inactive + delete
    final del = (await d.rows(c)).last;
    expect(del.op, 'delete');
    d.transport.scripted[del.mutationId] = PushResult(
      mutationId: del.mutationId,
      status: PushStatus.rejected,
      entityId: c,
      code: 'entity_deleted',
      message: 'gone',
    );
    expect(await d.sync(), SyncOutcome.completed);
    expect((await d.rowOf(del.mutationId)).status, OutboxStatus.done);
    expect(d.engine.current.rejected, 0);
  });

  test('a delete of a row another device already deleted is applied '
      '(BE: idempotent) and the row is gone after the pull', () async {
    final v = await d.vendors.create(const CreateVendorRequestDto(name: 'A'));
    expect(await d.sync(), SyncOutcome.completed);
    await d.other('vendor', 'delete', v, const {});
    await d.vendors.delete(v);
    expect(await d.sync(), SyncOutcome.completed);
    expect((await d.rows(v)).last.status, OutboxStatus.done);
    expect(await d.row('vendors', v), isNull);
    expect(d.server.tables['vendor']![v]!['is_active'], isFalse);
  });
}
