// Phase 3 Task 7, Review Focus 4: a pull never erases or reverts an unsynced
// local catalog edit. Real SyncEngine + FakeSyncServer (BE semantics) +
// ProductService + ProductApplier, and the ProductBloc reading SQLite.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/core/sync/appliers/product_applier.dart';
import 'package:amana_pos/core/sync/appliers/stock_applier.dart';
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
import 'package:amana_pos/features/category/data/repository_impl/category_repo_impl.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/repository_impl/product_repo_impl.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/engine_harness.dart';
import 'support/fake_sync_server.dart';
import 'support/test_db.dart';

const _scope = 'u1|t1';

void main() {
  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late ScenarioTransport transport;
  late SyncStateStore state;
  late SyncEngine engine;
  late CategoryService categories;
  late ProductService products;
  late ProductBloc bloc;
  late Directory base;
  final notifier = DbChangeNotifier();
  var clock = DateTime.utc(2026, 11, 17, 9);
  DateTime now() => clock;

  Future<SyncOutcome> sync() {
    clock = clock.add(const Duration(hours: 2));
    return engine.syncNow();
  }

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    base = await Directory.systemTemp.createTemp('catalog_pull_keeps');
    server = FakeSyncServer(now: now);
    transport = ScenarioTransport(server);
    final outbox = OutboxStore(odb, now: now);
    state = SyncStateStore(odb, now: now, scope: _scope);
    final writer = LocalWriter(
      odb,
      outbox,
      notifier,
      scopeProvider: () => _scope,
    );
    final registry = ChangeApplierRegistry()
      ..register(CategoryApplier(scopeProvider: () => _scope))
      ..register(ProductApplier())
      ..register(StockApplier());
    engine = SyncEngine(
      db: odb,
      transport: transport,
      outbox: outbox,
      state: state,
      scopeProvider: () => _scope,
      reachability: ServerReachability(transport, now: now),
      appliers: registry,
      notifier: notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(1)),
      now: now,
    );
    const actor = CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    final uploads = PendingUploadStore(baseDir: () async => base.path);
    categories = CategoryService(
      writer: writer,
      actor: () => actor,
      uploads: uploads,
      now: now,
    );
    products = ProductService(
      writer: writer,
      actor: () => actor,
      uploads: uploads,
      categories: categories,
      now: now,
    );
    await db.insert('sync_state', {
      'key': 'device_id',
      'value': 'abcd1234-0000-4000-8000-000000000000',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    await db.transaction((t) async {
      await state.setCursor(t, EngineHarness.seedCursor);
      await state.setBootstrapped(t, true);
    });
    bloc = ProductBloc(
      useCase: ProductUseCase(
        repository: ProductRepoImpl(service: () => products),
      ),
      categoryUseCase: CategoryUseCase(
        repository: CategoryRepoImpl(service: () => categories),
      ),
      offlineLocalCache: OfflineLocalCache(odb),
      changes: notifier.changes,
    );
  });

  tearDown(() async {
    await bloc.close();
    await engine.dispose();
    notifier.dispose();
    await db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  });

  Future<Map<String, dynamic>> productJson(String id) async =>
      jsonDecode(
            (await db.query(
                  'products',
                  where: 'id = ?',
                  whereArgs: [id],
                )).single['json']
                as String,
          )
          as Map<String, dynamic>;

  Future<int?> productVersion(String id) async =>
      (await db.query(
            'products',
            where: 'id = ?',
            whereArgs: [id],
          )).single['version']
          as int?;

  Future<ProductState> settle(bool Function(ProductState) test) async {
    if (test(bloc.state)) return bloc.state;
    return bloc.stream.firstWhere(test).timeout(const Duration(seconds: 5));
  }

  test('a pull bringing a newer server row while the local edit is pending '
      '(push answered retry) keeps the edit; the edit then lands and the '
      'two changes merge', () async {
    final cat = await categories.create(name: 'Drinks');
    final p = await products.create(
      AddProductRequestDto(
        name: 'Cola',
        price: '12.50',
        category: cat,
        unit: 'piece',
        trackInventory: true,
      ),
    );
    expect(await sync(), SyncOutcome.completed);
    expect(await productVersion(p), 1);

    // Another device changes the price on the server (version 2).
    final other = await server
        .forDevice('dev-2')
        .push(
          deviceId: 'dev-2',
          appVersion: '1.0.0',
          mutations: [
            OutboxEntry(
              seq: 1,
              mutationId: 'other-price',
              entity: 'product',
              op: 'update',
              entityId: p,
              baseVersion: 1,
              occurredAt: clock,
              payload: const {'price': '15.00'},
            ),
          ],
          scope: _scope,
        );
    expect(other.results.single.status, PushStatus.applied);

    // This device renames it offline-first (pending, base_version 1).
    await products.update(
      p,
      UpdateProductRequestDto(
        name: 'Cola Zero',
        price: '12.50',
        category: cat,
        unit: 'piece',
        trackInventory: true,
      ),
    );
    final edit = OutboxEntry.fromRow(
      (await db.query(
        'outbox',
        where: "entity = 'product' AND op = 'update'",
      )).single,
    );
    bloc.add(const OnProductInitial());
    await settle((s) => s.products.any((x) => x.name == 'Cola Zero'));

    // The push of the edit does not land (retry); the pull still runs and
    // brings the server's version 2 (old name, new price).
    transport.scripted[edit.mutationId] = PushResult(
      mutationId: edit.mutationId,
      status: PushStatus.retry,
      entityId: p,
      code: 'server_busy',
    );
    await sync();
    expect(transport.pullCalls, greaterThanOrEqualTo(2));
    expect(server.tables['product']![p]!['version'], 2);

    expect((await productJson(p))['name'], 'Cola Zero', reason: 'not erased');
    expect(await productVersion(p), 1, reason: 'not rolled forward');
    expect(
      OutboxEntry.fromRow(
        (await db.query(
          'outbox',
          where: 'mutation_id = ?',
          whereArgs: [edit.mutationId],
        )).single,
      ).status,
      OutboxStatus.pending,
    );
    final deferred =
        jsonDecode((await state.deferredPullJson(db))!) as Map<String, dynamic>;
    expect(deferred.keys, contains('product|$p'));
    // The list (SQLite) still shows the local edit, marked waiting.
    bloc.add(const OnProductInitial(force: true));
    final s = await settle(
      (s) => s.productStatus == ProductStatus.success && s.products.isNotEmpty,
    );
    final row = s.products.singleWhere((x) => x.id == p);
    expect(row.name, 'Cola Zero');
    expect(s.syncMarks.isPendingSync(p), isTrue);

    // The server takes the edit next time: name from here, price from the
    // other device, nothing lost.
    transport.scripted.clear();
    expect(await sync(), SyncOutcome.completed);
    final json = await productJson(p);
    expect(json['name'], 'Cola Zero');
    expect(json['price'], '15.00');
    expect(await productVersion(p), 3);
    expect(server.tables['product']![p]!['name'], 'Cola Zero');
    expect(server.tables['product']![p]!['price'], '15.00');
    final after = await settle(
      (s) => !s.syncMarks.isPendingSync(p) &&
          s.products.any((x) => x.id == p && x.price == '15.00'),
    );
    expect(after.products.singleWhere((x) => x.id == p).name, 'Cola Zero');
  });

  test('a pull while an unsent local create is pending (push answered '
      'retry) never erases it', () async {
    final cat = await categories.create(name: 'Drinks');
    expect(await sync(), SyncOutcome.completed);
    final p = await products.create(
      AddProductRequestDto(
        name: 'Local only',
        price: '1',
        category: cat,
        unit: 'piece',
        trackInventory: true,
      ),
    );
    final create = OutboxEntry.fromRow(
      (await db.query('outbox', where: "entity = 'product'")).single,
    );
    transport.scripted[create.mutationId] = PushResult(
      mutationId: create.mutationId,
      status: PushStatus.retry,
      entityId: p,
      code: 'server_busy',
    );
    await sync();
    expect((await productJson(p))['name'], 'Local only');
    expect(await productVersion(p), isNull);
    bloc.add(const OnProductInitial());
    final s = await settle(
      (s) => s.productStatus == ProductStatus.success && s.products.isNotEmpty,
    );
    expect(s.products.map((x) => x.id), [p]);
    expect(s.syncMarks.isPendingSync(p), isTrue);
  });
}
