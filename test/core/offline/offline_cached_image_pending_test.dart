import 'dart:async';
// Task 6: OfflineCachedImage shows a staged (pending_uploads) image of its
// entity first, before any synced_assets file or the network.
import 'dart:io';

import 'package:amana_pos/core/offline/data/local_image_resolver.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/core/sync/assets/asset_sync.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/images/pending_image_resolver.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../sync/support/test_db.dart';

const _scope = 'u1|t1';
const _url = 'https://api.amana.test/media/p1/thumb.webp?v=abc123';

void main() {
  late OfflineDb odb;
  late Database db;
  late DbChangeNotifier notifier;
  late Directory tmp;
  late PendingUploadStore store;
  late LocalImageResolver resolver;
  late PendingImageResolver pending;
  late File synced;
  late int loads;

  setUp(() async {
    await getIt.reset();
    odb = await openTestDb();
    db = await odb.database;
    notifier = DbChangeNotifier();
    tmp = Directory.systemTemp.createTempSync('ocip_');
    store = PendingUploadStore(baseDir: () async => tmp.path);
    getIt.registerSingleton<OfflineLocalCache>(OfflineLocalCache(odb));
    resolver = LocalImageResolver(
      changes: notifier.changes,
      load: () => getIt<OfflineLocalCache>().getSyncedAssetPaths(),
    );
    getIt.registerSingleton<LocalImageResolver>(resolver);
    loads = 0;
    pending = PendingImageResolver(
      changes: notifier.changes,
      load: () async {
        loads++;
        return PendingImageResolver.pathsOf(
          await store.all(db, scope: _scope),
        );
      },
    );
    getIt.registerSingleton<PendingImageResolver>(pending);
    synced = File(p.join(tmp.path, 'as_product_p1_thumb_abc.webp'))
      ..writeAsBytesSync(List<int>.filled(32, 1));
  });

  tearDown(() async {
    resolver.dispose();
    pending.dispose();
    await getIt.reset();
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<PendingUpload> stage(String id, {String scope = _scope}) async {
    final src = File(p.join(tmp.path, 'pick_$id.jpg'))
      ..writeAsBytesSync(List<int>.generate(64, (i) => i));
    final img = await store.prepare(
      entity: 'product',
      entityId: id,
      source: src,
    );
    final r = await db.transaction((t) => store.stage(t, img, scope: scope));
    return r.upload;
  }

  Future<void> syncedRow() => db.insert(kSyncedAssetsTable, {
    'type': 'product',
    'id': 'p1',
    'variant': 'thumb',
    'url': _url,
    'expected_hash': 'abc',
    'local_path': synced.path,
    'local_hash': 'abc',
    'bytes': 32,
    'state': 'ok',
    'attempts': 0,
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Widget app({String? url, String? id = 'p1'}) => MaterialApp(
    home: Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: OfflineCachedImage(
          imageUrl: url,
          entityType: 'product',
          entityId: id,
          placeholder: const SizedBox(key: Key('ph')),
          errorWidget: const SizedBox(key: Key('err')),
        ),
      ),
    ),
  );

  /// The file behind the shown image (unwraps the cacheWidth resize).
  String? shownFile(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    if (images.isEmpty) return null;
    var provider = images.first.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    return provider is FileImage ? provider.file.path : null;
  }

  testWidgets('a pending upload without any url shows the staged file, '
      'decoded small', (tester) async {
    final up = (await tester.runAsync(() => stage('p1')))!;
    await tester.pumpWidget(app());
    await settle(tester);
    expect(shownFile(tester), up.localPath);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, lessThanOrEqualTo(40 * 3));
  });

  testWidgets('the staged file wins over a synced_assets file and the network', (
    tester,
  ) async {
    final up = (await tester.runAsync(() async {
      await syncedRow();
      return stage('p1');
    }))!;
    await tester.pumpWidget(app(url: _url));
    await settle(tester);
    expect(shownFile(tester), up.localPath);
  });

  testWidgets('no pending row: the synced file as before; no url: the error '
      'widget', (tester) async {
    await tester.runAsync(syncedRow);
    await tester.pumpWidget(app(url: _url));
    await settle(tester);
    expect(shownFile(tester), synced.path);

    await tester.pumpWidget(app(id: 'p2'));
    await settle(tester);
    expect(find.byKey(const Key('err')), findsOneWidget);
  });

  testWidgets('another scope\'s upload is not shown', (tester) async {
    await tester.runAsync(() => stage('p1', scope: 'u2|t2'));
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.byKey(const Key('err')), findsOneWidget);
  });

  testWidgets('re-resolves on a pending_uploads notify (staged, then '
      'uploaded and removed)', (tester) async {
    await tester.runAsync(syncedRow);
    await tester.pumpWidget(app(url: _url));
    await settle(tester);
    expect(shownFile(tester), synced.path);

    final up = (await tester.runAsync(() => stage('p1')))!;
    notifier.notify(const {SyncTables.pendingUploads});
    await settle(tester);
    expect(shownFile(tester), up.localPath);

    await tester.runAsync(
      () => db.transaction((t) => store.cancel(t, 'product', 'p1')),
    );
    notifier.notify(const {SyncTables.pendingUploads});
    await settle(tester);
    expect(shownFile(tester), synced.path);
  });

  testWidgets('one load for many widgets; other tables do not reload', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (var i = 0; i < 5; i++)
              SizedBox(
                width: 10,
                height: 10,
                child: OfflineCachedImage(
                  imageUrl: null,
                  entityType: 'product',
                  entityId: 'p$i',
                  placeholder: const SizedBox(),
                  errorWidget: const SizedBox(),
                ),
              ),
          ],
        ),
      ),
    );
    await settle(tester);
    expect(loads, 1);
    notifier.notify(const {'products'});
    await settle(tester);
    expect(loads, 1);
    notifier.notify(const {SyncTables.pendingUploads});
    await settle(tester);
    expect(loads, 2);
    await tester.pumpWidget(const SizedBox());
    expect(pending.debugSubscribers, 0);
  });

  testWidgets('without entity ids the widget behaves exactly as before', (
    tester,
  ) async {
    await tester.runAsync(() => stage('p1'));
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 40,
          height: 40,
          child: OfflineCachedImage(
            imageUrl: _url,
            placeholder: SizedBox(),
            errorWidget: SizedBox(),
          ),
        ),
      ),
    );
    await settle(tester);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images.single.image, isA<NetworkImage>());
    expect(loads, 0);
  });

  testWidgets('T6 M4: before the first staged-image load finishes, the '
      'placeholder shows (no flash of the url / error tile)', (tester) async {
    final gate = Completer<void>();
    pending.dispose();
    pending = PendingImageResolver(
      changes: notifier.changes,
      load: () async {
        await gate.future;
        return const {};
      },
    );
    await getIt.unregister<PendingImageResolver>();
    getIt.registerSingleton<PendingImageResolver>(pending);
    await tester.pumpWidget(app(id: 'p2'));
    await tester.pump();
    expect(find.byKey(const Key('ph')), findsOneWidget);
    expect(find.byKey(const Key('err')), findsNothing);
    gate.complete();
    await settle(tester);
    expect(find.byKey(const Key('err')), findsOneWidget);
  });

  test('T6 M3: after a user switch the next acquire never shows the previous '
      'scope\'s map; it reloads for the new scope', () async {
    var scope = 'u1|t1';
    final loadedFor = <String>[];
    final r = PendingImageResolver(
      changes: notifier.changes,
      scopeOf: () => scope,
      load: () async {
        loadedFor.add(scope);
        return {'product|p1': '/staged/$scope'};
      },
    );
    addTearDown(r.dispose);
    final paths = r.acquire();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(paths.value, {'product|p1': '/staged/u1|t1'});
    r.release();

    scope = 'u2|t1'; // same tenant, other user; no pending_uploads notify
    r.acquire();
    expect(paths.value, isNull, reason: 'the old map is never shown');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(paths.value, {'product|p1': '/staged/u2|t1'});
    expect(loadedFor, ['u1|t1', 'u2|t1']);
    r.release();
  });
}
