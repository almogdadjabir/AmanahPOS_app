// Task 6 (Phase 3): ImageUploader against the FakeSyncServer (BE image PUT
// semantics) through the real SyncEngine, services and appliers.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/appliers/applier_support.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/core/sync/appliers/product_applier.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/images/image_uploader.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/transport/image_upload_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'support/engine_harness.dart';
import 'support/fake_sync_server.dart';
import 'support/test_db.dart';

const _scope = 'u1|t1';

/// Counts calls and can throw before reaching the server.
class _Transport implements ImageUploadTransport {
  _Transport(this.inner);
  final ImageUploadTransport inner;
  int calls = 0;
  final failures = <SyncTransportException>[];

  /// Runs after the server answered, before the answer is returned.
  Future<void> Function()? beforeReturn;

  /// Thrown after [beforeReturn] instead of returning the answer.
  SyncTransportException? failAfterReturn;

  @override
  Future<ImageUploadResult> putImage({
    required String entity,
    required String entityId,
    required List<int> bytes,
    required String sha256,
    required String scope,
  }) {
    calls++;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return () async {
      final r = await inner.putImage(
        entity: entity,
        entityId: entityId,
        bytes: bytes,
        sha256: sha256,
        scope: scope,
      );
      final hook = beforeReturn;
      beforeReturn = null;
      if (hook != null) await hook();
      final f = failAfterReturn;
      failAfterReturn = null;
      if (f != null) throw f;
      return r;
    }();
  }
}

class _Device {
  _Device._();

  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late _Transport images;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  late SyncEngine engine;
  late CategoryService categories;
  late ProductService products;
  late PendingUploadStore store;
  late ImageUploader uploader;
  late Directory base;
  String curScope = _scope;
  final notifier = DbChangeNotifier();
  final notified = <String>{};
  final registry = ChangeApplierRegistry();
  int refreshes = 0;
  DateTime clock = DateTime.utc(2026, 11, 17, 9);
  DateTime now() => clock;

  static Future<_Device> create() async {
    final d = _Device._();
    d.odb = await openTestDb();
    d.db = await d.odb.database;
    d.base = await Directory.systemTemp.createTemp('image_uploader');
    d.server = FakeSyncServer(now: d.now);
    final transport = ScenarioTransport(d.server);
    d.images = _Transport(d.server);
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
      ..register(ProductApplier());
    d.engine = SyncEngine(
      db: d.odb,
      transport: transport,
      outbox: d.outbox,
      state: d.state,
      scopeProvider: () => _scope,
      reachability: ServerReachability(transport, now: d.now),
      appliers: d.registry,
      notifier: d.notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(1)),
      now: d.now,
      refreshToken: () async {
        d.refreshes++;
        return RefreshOutcome.refreshed;
      },
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
    d.store = PendingUploadStore(baseDir: () async => d.base.path, now: d.now);
    d.products = ProductService(
      writer: d.writer,
      actor: () => actor,
      uploads: d.store,
      categories: d.categories,
      now: d.now,
    );
    d.uploader = ImageUploader(
      db: d.odb,
      store: d.store,
      transport: d.images,
      notifier: d.notifier,
      scopeProvider: () => d.curScope,
      authedFor: d.engine.authedFor,
      now: d.now,
    );
    d.notifier.changes.listen(d.notified.addAll);
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

  Future<PickedAppImage> pick(List<int> bytes, [String name = 'a.jpg']) async {
    final f = File(p.join(base.path, 'picker', '${bytes.hashCode}_$name'));
    await f.create(recursive: true);
    await f.writeAsBytes(bytes);
    return PickedAppImage(file: f, path: f.path, name: name);
  }

  Future<String> productWithImage(List<int> bytes, {String? category}) async {
    final cat = category ?? await categories.create(name: 'Drinks');
    return products.create(
      AddProductRequestDto(
        name: 'Cola',
        price: '12.50',
        category: cat,
        unit: 'piece',
        trackInventory: true,
        imageUpload: await pick(bytes),
      ),
    );
  }

  Future<Map<String, Object?>?> row(String table, String id) async {
    final r = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.single;
  }

  Future<PendingUpload?> upload(String id) => store.get(db, 'product', id);

  /// Stages a new pick of product [id] (as ProductService.update would).
  Future<PendingUpload> stagePick(
    String id,
    List<int> bytes, {
    String scope = _scope,
  }) async {
    final img = await store.prepare(
      entity: 'product',
      entityId: id,
      source: (await pick(bytes)).file,
    );
    final r = await db.transaction((t) => store.stage(t, img, scope: scope));
    await store.deleteFiles(r.obsoleteFiles); // as ProductService does
    return r.upload;
  }

  Future<Map<String, dynamic>> serverRow(String id) async =>
      server.tables['product']![id]!;
}

String _sha(List<int> b) => crypto.sha256.convert(b).toString();

void main() {
  late _Device d;
  final bytes = List<int>.generate(4000, (i) => i % 241);

  setUp(() async => d = await _Device.create());
  tearDown(() => d.dispose());

  test('uploads after the create is done and not before', () async {
    final id = await d.productWithImage(bytes);
    final staged = (await d.upload(id))!;
    expect(File(staged.localPath).existsSync(), isTrue);

    var report = await d.uploader.run();
    expect(d.images.calls, 0, reason: 'the create is still pending');
    expect(report.waiting, 1);
    expect(await d.upload(id), isNotNull);

    expect(await d.sync(), SyncOutcome.completed);
    d.notified.clear();
    report = await d.uploader.run();
    expect(report.uploaded, 1);
    expect(d.images.calls, 1);

    final server = await d.serverRow(id);
    expect(server['image_hash'], _sha(bytes));
    final local = (await d.row('products', id))!;
    expect(local['image_hash'], _sha(bytes));
    expect(local['image_url'], server['image']);
    expect(local['thumbnail_url'], server['thumbnail_url']);
    expect(local['version'], server['version']);
    final json = jsonDecode(local['json'] as String) as Map;
    expect(json['image'], server['image']);
    expect(json['thumbnail_url'], server['thumbnail_url']);
    final sj = jsonDecode(local['server_json'] as String) as Map;
    expect(sj['version'], server['version']);
    expect(sj['image_hash'], _sha(bytes));

    final assets = await d.db.query(
      kSyncedAssetsTable,
      where: 'type = ? AND id = ?',
      whereArgs: ['product', id],
    );
    expect(assets.map((r) => r['variant']).toSet(), {'thumb', 'full'});
    expect(assets.every((r) => r['expected_hash'] == _sha(bytes)), isTrue);
    expect(assets.every((r) => r['state'] == 'pending'), isTrue);

    expect(await d.upload(id), isNull);
    expect(File(staged.localPath).existsSync(), isFalse);
    expect(
      d.notified,
      containsAll(['products', kSyncedAssetsTable, SyncTables.pendingUploads]),
    );

    // A later pull of the same change keeps the row as is (version guard).
    expect(await d.sync(), SyncOutcome.completed);
    final after = (await d.row('products', id))!;
    expect(after['version'], server['version']);
    expect(after['image_hash'], _sha(bytes));
    expect(after['image_url'], server['image']);
  });

  test('lost response then retry results in one server image and image_hash '
      'equals local sha256 (Review Focus 3)', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    d.server.dropImageResponseAfterApply = 1;

    var report = await d.uploader.run();
    expect(report.uploaded, 0);
    expect(report.retrying, 1);
    final up = (await d.upload(id))!;
    expect(up.attempts, 1);
    expect(File(up.localPath).existsSync(), isTrue);
    expect(d.server.imageStores, 1);

    d.clock = d.clock.add(const Duration(minutes: 2));
    report = await d.uploader.run();
    expect(report.uploaded, 1);
    expect(d.server.imageStores, 1, reason: 'the retry is a no-op');
    expect(d.images.calls, 2);

    final server = await d.serverRow(id);
    final local = (await d.row('products', id))!;
    expect(server['image_hash'], _sha(bytes));
    expect(local['image_hash'], _sha(bytes));
    expect(local['version'], server['version']);
    expect(await d.upload(id), isNull);

    expect(await d.sync(), SyncOutcome.completed);
    final after = (await d.row('products', id))!;
    expect(after['image_hash'], _sha(bytes));
    expect(after['version'], server['version']);
  });

  test('a newer row pulled while the answer is in flight is never reverted '
      '(version guard)', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    d.images.beforeReturn = () async {
      // Another device renames the product after the image landed (v3);
      // this device pulls it before the upload answer is handled.
      final v = d.server.tables['product']![id]!['version'] as int;
      final r = await d.server
          .forDevice('dev-2')
          .push(
            deviceId: 'dev-2',
            appVersion: '1.0.0',
            mutations: [
              OutboxEntry(
                seq: 1,
                mutationId: 'o-rename-$id',
                entity: 'product',
                op: 'update',
                entityId: id,
                baseVersion: v,
                occurredAt: d.clock,
                payload: {'name': 'Theirs'},
              ),
            ],
            scope: _scope,
          );
      expect(r.results.single.status, PushStatus.applied);
      expect(await d.sync(), SyncOutcome.completed);
      await Future<void>.delayed(Duration.zero);
      d.notified.clear();
    };
    expect((await d.uploader.run()).uploaded, 1);
    final local = (await d.row('products', id))!;
    final server = await d.serverRow(id);
    expect(local['version'], server['version']);
    expect(local['name'], 'Theirs');
    expect(local['image_hash'], _sha(bytes));
    expect(await d.upload(id), isNull);
    // T6 M6: the row was not written (older answer): only the removed
    // upload is announced, not products / synced_assets.
    await Future<void>.delayed(Duration.zero);
    expect(d.notified, {SyncTables.pendingUploads});
  });

  test('network failure backs off and keeps the file', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    d.server.down = true;

    final report = await d.uploader.run();
    expect(report.retrying, 1);
    final up = (await d.upload(id))!;
    expect(up.state, PendingUpload.waiting);
    expect(up.attempts, 1);
    expect(
      DateTime.parse(up.nextAttemptAt!),
      d.clock.add(const Duration(minutes: 1)),
    );
    expect(File(up.localPath).existsSync(), isTrue);

    // Not due yet: no call.
    final calls = d.images.calls;
    await d.uploader.run();
    expect(d.images.calls, calls);

    // Second failure doubles the wait; never gives up.
    d.clock = d.clock.add(const Duration(minutes: 1));
    await d.uploader.run();
    final up2 = (await d.upload(id))!;
    expect(up2.attempts, 2);
    expect(
      DateTime.parse(up2.nextAttemptAt!),
      d.clock.add(const Duration(minutes: 2)),
    );

    d.server.down = false;
    d.clock = d.clock.add(const Duration(minutes: 3));
    expect((await d.uploader.run()).uploaded, 1);
    expect(await d.upload(id), isNull);
  });

  test('5xx and 429 back off like a network failure', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    d.images.failures.add(
      SyncTransportException(kind: SyncTransportKind.server, httpStatus: 502),
    );
    await d.uploader.run();
    expect((await d.upload(id))!.attempts, 1);
    expect((await d.upload(id))!.state, PendingUpload.waiting);
    d.clock = d.clock.add(const Duration(minutes: 2));
    d.images.failures.add(
      SyncTransportException(
        kind: SyncTransportKind.server,
        httpStatus: 429,
        code: 'rate_limited',
      ),
    );
    await d.uploader.run();
    expect((await d.upload(id))!.attempts, 2);
    expect((await d.upload(id))!.state, PendingUpload.waiting);
  });

  test('403 parks as failed; retryFailed sends it again', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    d.server.role = 'cashier';

    final report = await d.uploader.run();
    expect(report.failed, 1);
    final up = (await d.upload(id))!;
    expect(up.state, PendingUpload.failed);
    expect(up.lastError, isNotNull);
    expect(File(up.localPath).existsSync(), isTrue);

    // Parked: later runs do not send it.
    d.clock = d.clock.add(const Duration(days: 2));
    await d.uploader.run();
    expect(d.images.calls, 1);

    d.server.role = 'owner';
    expect(await d.uploader.retryFailed('product', id), isTrue);
    expect((await d.upload(id))!.state, PendingUpload.waiting);
    expect((await d.uploader.run()).uploaded, 1);
    expect((await d.row('products', id))!['image_hash'], _sha(bytes));
  });

  for (final (status, kind) in [
    (404, SyncTransportKind.server),
    (413, SyncTransportKind.tooLarge),
  ]) {
    test('$status parks as failed', () async {
      final id = await d.productWithImage(bytes);
      expect(await d.sync(), SyncOutcome.completed);
      d.images.failures.add(
        SyncTransportException(kind: kind, httpStatus: status),
      );
      await d.uploader.run();
      expect((await d.upload(id))!.state, PendingUpload.failed);
    });
  }

  test('edit pending blocks upload until the update is done', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    // The first image goes up.
    expect((await d.uploader.run()).uploaded, 1);

    final second = List<int>.generate(3000, (i) => (i * 7) % 253);
    await d.products.update(
      id,
      UpdateProductRequestDto(price: '15', imageUpload: await d.pick(second)),
    );
    expect((await d.uploader.run()).waiting, 1);
    expect(d.images.calls, 1);

    expect(await d.sync(), SyncOutcome.completed);
    expect((await d.uploader.run()).uploaded, 1);
    expect(d.images.calls, 2);
    final local = (await d.row('products', id))!;
    expect(local['image_hash'], _sha(second));
    expect(local['price'], '15');
    expect((await d.serverRow(id))['image_hash'], _sha(second));
  });

  test('a rejected create parks the upload; nothing is sent', () async {
    d.server.productLimit = 0;
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    final report = await d.uploader.run();
    expect(report.waiting, 1);
    expect(d.images.calls, 0);
    expect((await d.upload(id))!.state, PendingUpload.waiting);
  });

  test('entity deleted while waiting cancels upload and file', () async {
    final id = await d.productWithImage(bytes);
    final staged = (await d.upload(id))!;
    // The row is gone (e.g. merged / discarded) while the upload waits.
    await d.db.delete('products', where: 'id = ?', whereArgs: [id]);
    await d.db.delete('outbox', where: 'entity_id = ?', whereArgs: [id]);

    d.notified.clear();
    final report = await d.uploader.run();
    expect(report.cancelled, 1);
    expect(d.images.calls, 0);
    expect(await d.upload(id), isNull);
    expect(File(staged.localPath).existsSync(), isFalse);
    expect(d.notified, contains(SyncTables.pendingUploads));
  });

  test('a never-synced row whose create is gone cancels the upload', () async {
    final id = await d.productWithImage(bytes);
    await d.db.delete('outbox', where: 'entity_id = ?', whereArgs: [id]);
    expect((await d.uploader.run()).cancelled, 1);
    expect(await d.upload(id), isNull);
  });

  test('hash_mismatch recomputes from the file and retries once', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    final up = (await d.upload(id))!;
    final changed = List<int>.generate(1000, (i) => (i * 3) % 199);
    await File(up.localPath).writeAsBytes(changed, flush: true);

    final report = await d.uploader.run();
    expect(report.uploaded, 1);
    expect(d.images.calls, 2);
    expect((await d.row('products', id))!['image_hash'], _sha(changed));
    expect((await d.serverRow(id))['image_hash'], _sha(changed));
  });

  test('an unreadable staged file parks as failed', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    await File((await d.upload(id))!.localPath).delete();
    final report = await d.uploader.run();
    expect(report.failed, 1);
    expect(d.images.calls, 0);
    expect((await d.upload(id))!.state, PendingUpload.failed);
  });

  test(
    '401 token_expired refreshes once through authedFor and uploads',
    () async {
      final id = await d.productWithImage(bytes);
      expect(await d.sync(), SyncOutcome.completed);
      d.images.failures.add(
        SyncTransportException(
          kind: SyncTransportKind.tokenExpired,
          httpStatus: 401,
          code: 'token_expired',
        ),
      );
      final report = await d.uploader.run();
      expect(report.uploaded, 1);
      expect(d.refreshes, 1);
      expect(await d.upload(id), isNull);
    },
  );

  test('401 account_disabled stops the run quietly, rows untouched', () async {
    final a = await d.productWithImage(bytes);
    final b = await d.productWithImage(
      List<int>.filled(50, 9),
      category: (await d.row('products', a))!['category_id'] as String,
    );
    expect(await d.sync(), SyncOutcome.completed);
    d.images.failures.add(
      SyncTransportException(
        kind: SyncTransportKind.accountDisabled,
        httpStatus: 401,
        code: 'account_disabled',
      ),
    );
    final report = await d.uploader.run();
    expect(report.stopped, isTrue);
    expect(d.images.calls, 1, reason: 'no further request after the stop');
    for (final id in [a, b]) {
      final up = (await d.upload(id))!;
      expect(up.attempts, 0);
      expect(up.state, PendingUpload.waiting);
    }
  });

  test('a category upload uses the categories row', () async {
    final cat = await d.categories.create(name: 'Snacks');
    expect(await d.sync(), SyncOutcome.completed);
    final staged = await d.store.prepare(
      entity: 'category',
      entityId: cat,
      source: (await d.pick(bytes)).file,
    );
    await d.db.transaction((t) => d.store.stage(t, staged, scope: _scope));
    expect((await d.uploader.run()).uploaded, 1);
    final local = (await d.row('categories', cat))!;
    expect(local['image_hash'], _sha(bytes));
    final json = jsonDecode(local['json'] as String) as Map;
    expect(json['image'], isNotNull);
    expect(local['version'], d.server.tables['category']![cat]!['version']);
  });

  test('sweeps orphan staged files at most once per hour', () async {
    final orphan = File(p.join(d.base.path, 'pending_images', 'x', 'old'));
    await orphan.create(recursive: true);
    await orphan.setLastModified(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    d.clock = DateTime.now().toUtc();
    await d.uploader.run();
    expect(orphan.existsSync(), isFalse);

    await orphan.create(recursive: true);
    await orphan.setLastModified(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    d.clock = d.clock.add(const Duration(minutes: 30));
    await d.uploader.run();
    expect(orphan.existsSync(), isTrue, reason: 'inside the hour');
    d.clock = d.clock.add(const Duration(minutes: 31));
    await d.uploader.run();
    expect(orphan.existsSync(), isFalse);
  });

  test('CatalogSupport is untouched by an upload (no outbox row)', () async {
    final id = await d.productWithImage(bytes);
    expect(await d.sync(), SyncOutcome.completed);
    final before = await d.db.query('outbox');
    await d.uploader.run();
    expect(await d.db.query('outbox'), hasLength(before.length));
    expect(await CatalogSupport.loadRow(d.db, 'products', id), isNotNull);
  });

  group('fix round 1', () {
    final newer = List<int>.generate(2500, (i) => (i * 11) % 251);

    void expectUntouched(PendingUpload? got, PendingUpload staged) {
      expect(got, isNotNull);
      expect(got!.relativePath, staged.relativePath);
      expect(got.sha256, _sha(newer));
      expect(got.state, PendingUpload.waiting);
      expect(got.attempts, 0);
      expect(got.nextAttemptAt, isNull);
      expect(got.lastError, isNull);
      expect(File(staged.localPath).existsSync(), isTrue);
    }

    test('a newer pick staged during an in-flight upload survives the old '
        'upload\'s success', () async {
      final id = await d.productWithImage(bytes);
      expect(await d.sync(), SyncOutcome.completed);
      final old = (await d.upload(id))!;
      late PendingUpload staged;
      d.images.beforeReturn = () async => staged = await d.stagePick(id, newer);

      final report = await d.uploader.run();
      expect(report.uploaded, 0, reason: 'the old row was replaced');
      // The entity mirrors what the server stored (the old image).
      expect((await d.row('products', id))!['image_hash'], _sha(bytes));
      expectUntouched(await d.upload(id), staged);
      expect(
        File(old.localPath).existsSync(),
        isFalse,
        reason: 'stage() reported it obsolete; deleted by its caller',
      );

      // The newer pick goes up next.
      expect((await d.uploader.run()).uploaded, 1);
      expect((await d.row('products', id))!['image_hash'], _sha(newer));
    });

    for (final (label, failure) in [
      ('network', SyncTransportException(kind: SyncTransportKind.network)),
      (
        '403',
        SyncTransportException(
          kind: SyncTransportKind.server,
          httpStatus: 403,
          code: 'forbidden',
        ),
      ),
      (
        'hash_mismatch',
        SyncTransportException(
          kind: SyncTransportKind.server,
          httpStatus: 400,
          code: 'hash_mismatch',
        ),
      ),
    ]) {
      test('a newer pick staged during an in-flight upload is untouched by '
          'the old upload\'s $label failure', () async {
        final id = await d.productWithImage(bytes);
        expect(await d.sync(), SyncOutcome.completed);
        late PendingUpload staged;
        d.images.beforeReturn = () async =>
            staged = await d.stagePick(id, newer);
        d.images.failAfterReturn = failure;
        await d.uploader.run();
        expectUntouched(await d.upload(id), staged);
      });
    }

    test('two concurrent runs: single flight, one request', () async {
      final id = await d.productWithImage(bytes);
      expect(await d.sync(), SyncOutcome.completed);
      ImageUploadReport? second;
      d.images.beforeReturn = () async => second = await d.uploader.run();
      final first = await d.uploader.run();
      expect(second!.skipped, isTrue);
      expect(first.uploaded, 1);
      expect(d.images.calls, 1);
      expect(d.server.imageStores, 1);
      expect(await d.upload(id), isNull);
    });

    test('another scope\'s row is never uploaded', () async {
      final cat = await d.categories.create(name: 'Drinks');
      final id = await d.products.create(
        AddProductRequestDto(
          name: 'Cola',
          price: '12.50',
          category: cat,
          unit: 'piece',
          trackInventory: true,
        ),
      );
      expect(await d.sync(), SyncOutcome.completed);
      final other = await d.stagePick(id, bytes, scope: 'u2|t2');
      final report = await d.uploader.run();
      expect(d.images.calls, 0);
      expect(report.uploaded + report.waiting + report.cancelled, 0);
      final got = (await d.upload(id))!;
      expect(got.scope, 'u2|t2');
      expect(got.attempts, 0);
      expect(File(other.localPath).existsSync(), isTrue);
    });

    test('an untyped 401 (AUTHENTICATION_FAILED, non-sync endpoint) refreshes '
        'once and retries the upload', () async {
      final id = await d.productWithImage(bytes);
      expect(await d.sync(), SyncOutcome.completed);
      d.images.failures.add(
        SyncTransportException(
          kind: SyncTransportKind.unauthorized,
          httpStatus: 401,
          code: 'AUTHENTICATION_FAILED',
        ),
      );
      final report = await d.uploader.run();
      expect(d.refreshes, 1);
      expect(d.images.calls, 2);
      expect(report.uploaded, 1);
      expect(await d.upload(id), isNull);
    });

    test(
      'scope changed while the request was out: nothing is written',
      () async {
        final id = await d.productWithImage(bytes);
        expect(await d.sync(), SyncOutcome.completed);
        d.images.beforeReturn = () async => d.curScope = 'u2|t2';
        final report = await d.uploader.run();
        expect(report.stopped, isTrue);
        expect(report.uploaded, 0);
        expect((await d.row('products', id))!['image_hash'], isNull);
        final up = (await d.upload(id))!;
        expect(up.attempts, 0);
        expect(File(up.localPath).existsSync(), isTrue);

        // Failure path too.
        d.curScope = _scope;
        d.images.beforeReturn = () async => d.curScope = 'u2|t2';
        d.images.failAfterReturn = SyncTransportException(
          kind: SyncTransportKind.network,
        );
        await d.uploader.run();
        final up2 = (await d.upload(id))!;
        expect(up2.attempts, 0);
        expect(up2.nextAttemptAt, isNull);
      },
    );
  });
}
