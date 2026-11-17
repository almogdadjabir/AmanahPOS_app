import 'dart:io';

import 'package:amana_pos/core/offline/data/local_image_resolver.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/core/sync/assets/asset_sync.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/support/test_db.dart';

const _url = 'https://api.amana.test/media/p1/thumb.webp?v=abc123';

void main() {
  late OfflineDb odb;
  late DbChangeNotifier notifier;
  late Directory tmp;
  late File file;
  late LocalImageResolver resolver;
  late int queries;

  setUp(() async {
    await getIt.reset();
    odb = await openTestDb();
    notifier = DbChangeNotifier();
    queries = 0;
    getIt.registerSingleton<OfflineLocalCache>(OfflineLocalCache(odb));
    getIt.registerSingleton<DbChangeNotifier>(notifier);
    // One shared resolver; counts its synced_assets queries (F5).
    resolver = LocalImageResolver(
      changes: notifier.changes,
      load: () {
        queries++;
        return getIt<OfflineLocalCache>().getSyncedAssetPaths();
      },
    );
    getIt.registerSingleton<LocalImageResolver>(resolver);
    tmp = Directory.systemTemp.createTempSync('oci_');
    file = File('${tmp.path}/as_product_p1_thumb_abc.webp')
      ..writeAsBytesSync(List<int>.filled(32, 1));
  });

  tearDown(() async {
    resolver.dispose();
    await getIt.reset();
    final db = await odb.database;
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> putRow({
    String url = _url,
    String state = 'ok',
    String? localPath,
    bool noFile = false,
    String id = 'p1',
  }) async {
    final db = await odb.database;
    await db.insert(kSyncedAssetsTable, {
      'type': 'product',
      'id': id,
      'variant': 'thumb',
      'url': url,
      'expected_hash': 'abc',
      'local_path': noFile ? null : (localPath ?? file.path),
      'local_hash': 'abc',
      'bytes': 32,
      'state': state,
      'attempts': 0,
    });
  }

  /// Lets the real (ffi) DB queries finish, then rebuilds.
  /// Each awaited DB/file step completes in real time but continues in the
  /// test zone, so alternate real waits and pumps a few times.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Widget app(String? url) => MaterialApp(
    home: SizedBox(
      width: 40,
      height: 40,
      child: OfflineCachedImage(
        imageUrl: url,
        placeholder: const SizedBox(key: Key('ph')),
        errorWidget: const SizedBox(key: Key('err')),
      ),
    ),
  );

  ImageProvider? provider(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    return images.isEmpty ? null : images.first.image;
  }

  testWidgets('synced_assets ok row + file: shows the local file', (
    tester,
  ) async {
    await tester.runAsync(() => putRow());
    await tester.pumpWidget(app(_url));
    await settle(tester);
    final p = provider(tester);
    expect(p, isA<FileImage>());
    expect((p! as FileImage).file.path, file.path);
  });

  testWidgets('matches the url without its ?v= query', (tester) async {
    await tester.runAsync(
      () => putRow(url: 'https://api.amana.test/media/p1/thumb.webp?v=new'),
    );
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(provider(tester), isA<FileImage>());
  });

  testWidgets('no row: network image', (tester) async {
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(provider(tester), isA<NetworkImage>());
  });

  testWidgets('pending row that still holds the previous file: local file '
      '(token changed, new file not downloaded yet)', (tester) async {
    await tester.runAsync(() => putRow(state: 'pending'));
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(provider(tester), isA<FileImage>());
  });

  testWidgets('pending row without a file: network image', (tester) async {
    await tester.runAsync(() => putRow(state: 'pending', noFile: true));
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(provider(tester), isA<NetworkImage>());
  });

  group('same path, other ?v=', () {
    late File older;
    late File newer;
    const base = 'https://api.amana.test/media/p1/thumb.webp';

    Future<void> twoRows() async {
      older = File('${tmp.path}/as_old.webp')..writeAsBytesSync([1, 2]);
      newer = File('${tmp.path}/as_new.webp')..writeAsBytesSync([3, 4]);
      await putRow(id: 'a', url: '$base?v=old', localPath: older.path);
      await putRow(id: 'b', url: '$base?v=new', localPath: newer.path);
    }

    testWidgets('no exact match: the newest row wins', (tester) async {
      await tester.runAsync(twoRows);
      await tester.pumpWidget(app('$base?v=other'));
      await settle(tester);
      expect((provider(tester)! as FileImage).file.path, newer.path);
    });

    testWidgets('an exact url match wins over a newer row', (tester) async {
      await tester.runAsync(twoRows);
      await tester.pumpWidget(app('$base?v=old'));
      await settle(tester);
      expect((provider(tester)! as FileImage).file.path, older.path);
    });
  });

  testWidgets('row ok but file missing: network image', (tester) async {
    await tester.runAsync(() => putRow(localPath: '${tmp.path}/as_gone.webp'));
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(provider(tester), isA<NetworkImage>());
  });

  testWidgets('swaps to the local file after a synced_assets notify', (
    tester,
  ) async {
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(provider(tester), isA<NetworkImage>());

    await tester.runAsync(() => putRow());
    notifier.notify(const {kSyncedAssetsTable});
    await settle(tester);
    expect(provider(tester), isA<FileImage>());
  });

  testWidgets('a lookup failure falls back to the network, never throws', (
    tester,
  ) async {
    await tester.runAsync(() => putRow());
    // The cache cannot be resolved: every lookup throws.
    await getIt.unregister<OfflineLocalCache>();
    await tester.pumpWidget(app(_url));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(provider(tester), isA<NetworkImage>());
  });

  testWidgets('empty url: error widget', (tester) async {
    await tester.pumpWidget(app(''));
    expect(find.byKey(const Key('err')), findsOneWidget);
  });

  group('shared resolver (F5)', () {
    Widget many(int n) => MaterialApp(
      home: Column(
        children: [
          for (var i = 0; i < n; i++)
            SizedBox(
              width: 10,
              height: 10,
              child: OfflineCachedImage(
                imageUrl: 'https://api.amana.test/media/p$i/thumb.webp',
                placeholder: const SizedBox(),
                errorWidget: const SizedBox(),
              ),
            ),
        ],
      ),
    );

    testWidgets('N widgets: one query to resolve, then ONE per notify', (
      tester,
    ) async {
      await tester.pumpWidget(many(6));
      await settle(tester);
      expect(queries, 1);

      notifier.notify(const {kSyncedAssetsTable});
      notifier.notify(const {kSyncedAssetsTable}); // a burst coalesces
      await settle(tester);
      expect(queries, 2);

      notifier.notify(const {'products'}); // other tables: no query
      await settle(tester);
      expect(queries, 2);
    });

    testWidgets('only the notified widget swaps to its local file', (
      tester,
    ) async {
      await tester.pumpWidget(many(3));
      await settle(tester);
      await tester.runAsync(
        () =>
            putRow(id: 'p1', url: 'https://api.amana.test/media/p1/thumb.webp'),
      );
      notifier.notify(const {kSyncedAssetsTable});
      await settle(tester);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(3));
      expect(images[0].image, isA<NetworkImage>());
      expect(images[1].image, isA<FileImage>());
      expect(images[2].image, isA<NetworkImage>());
    });

    testWidgets('disposed widgets release their subscriptions: no leak, no '
        'query on a later notify', (tester) async {
      await tester.pumpWidget(many(4));
      await settle(tester);
      expect(resolver.debugSubscribedUrls, 4);

      await tester.pumpWidget(const SizedBox());
      expect(resolver.debugSubscribedUrls, 0);
      final before = queries;
      notifier.notify(const {kSyncedAssetsTable});
      await settle(tester);
      expect(queries, before);
    });

    testWidgets('a url change moves the subscription', (tester) async {
      await tester.pumpWidget(app(_url));
      await settle(tester);
      await tester.pumpWidget(app('https://api.amana.test/media/zz.webp'));
      await settle(tester);
      expect(resolver.debugSubscribedUrls, 1);
      expect(provider(tester), isA<NetworkImage>());
    });
  });
}
