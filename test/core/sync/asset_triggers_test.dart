import 'dart:async';
import 'dart:io';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/sync/assets/asset_sync.dart';
import 'package:amana_pos/core/sync/assets/asset_sync_wiring.dart';
import 'package:amana_pos/core/sync/background/background_sync.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:amana_pos/core/sync/transport/sync_auth_interceptor.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/engine_harness.dart';

class _FakeEngine implements SyncEngine {
  final calls = <SyncReason>[];
  SyncOutcome outcome = SyncOutcome.completed;
  SyncStatus cur = const SyncStatus();

  @override
  SyncStatus get current => cur;

  @override
  void cancel() {}

  @override
  Future<SyncOutcome> syncNow({SyncReason reason = SyncReason.manual}) async {
    calls.add(reason);
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBootstrapper implements Bootstrapper {
  _FakeBootstrapper(this.engine);
  final _FakeEngine engine;
  int runs = 0;
  BootstrapOutcome outcome = BootstrapOutcome.completed;
  SyncOutcome afterComplete = SyncOutcome.completed;

  @override
  void cancel() {}

  @override
  Future<BootstrapOutcome> run() async {
    runs++;
    if (outcome == BootstrapOutcome.completed) engine.outcome = afterComplete;
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOutbox implements OutboxStore {
  @override
  Future<int> pendingCount({String? scope}) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNetwork implements NetworkMonitor {
  final ctrl = StreamController<bool>.broadcast(sync: true);

  @override
  Stream<bool> get onStatusChanged => ctrl.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records [run] calls; can throw (sync or async) or hang until released.
class _FakeAssets implements AssetSync {
  final runs = <bool>[];
  int cancels = 0;
  Object? throwSync;
  Object? throwAsync;
  Completer<void>? hold;

  @override
  Future<AssetSyncResult> run({
    int maxFiles = 40,
    int maxBytes = 20 * 1024 * 1024,
    bool thumbnailsOnly = false,
  }) {
    runs.add(thumbnailsOnly);
    final s = throwSync;
    if (s != null) throw s;
    return () async {
      final h = hold;
      if (h != null) await h.future;
      final a = throwAsync;
      if (a != null) throw a;
      return const AssetSyncResult(downloaded: 0, failed: 0, remaining: 0);
    }();
  }

  @override
  void cancel() {
    cancels++;
    final h = hold;
    if (h != null && !h.isCompleted) h.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('foreground triggers', () {
    late _FakeEngine engine;
    late _FakeAssets assets;
    late bool reachable;

    setUp(() {
      engine = _FakeEngine();
      assets = _FakeAssets();
      reachable = true;
    });

    SyncTriggers make({Bootstrapper? boot}) => SyncTriggers(
      engine,
      _FakeNetwork(),
      _FakeOutbox(),
      DbChangeNotifier(),
      bootstrapper: boot,
      assetSync: () async => assets,
      assetsReachable: () async => reachable,
    );

    test('a completed run starts AssetSync.run() (full, not thumbs only)', () {
      fakeAsync((async) {
        make().start();
        async.flushMicrotasks();
        expect(engine.calls, [SyncReason.resume]);
        expect(assets.runs, [false]);
      });
    });

    for (final o in [
      SyncOutcome.backoff,
      SyncOutcome.blocked,
      SyncOutcome.cancelled,
      SyncOutcome.alreadyRunning,
      SyncOutcome.needsBootstrap,
    ]) {
      test('no asset run after ${o.name}', () {
        fakeAsync((async) {
          engine.outcome = o;
          final t = make()..start();
          async.flushMicrotasks();
          expect(assets.runs, isEmpty);
          t.stop();
          async.flushMicrotasks();
        });
      });
    }

    test('bootstrap completion starts an asset run even when the engine '
        'follow-up does not complete', () {
      fakeAsync((async) {
        engine.outcome = SyncOutcome.needsBootstrap;
        final boot = _FakeBootstrapper(engine)
          ..afterComplete = SyncOutcome.backoff;
        final t = make(boot: boot)..start();
        async.flushMicrotasks();
        expect(boot.runs, 1);
        expect(assets.runs, [false]);
        t.stop();
        async.flushMicrotasks();
      });
    });

    test('interrupted bootstrap starts no asset run', () {
      fakeAsync((async) {
        engine.outcome = SyncOutcome.needsBootstrap;
        final boot = _FakeBootstrapper(engine)
          ..outcome = BootstrapOutcome.interrupted;
        make(boot: boot).start();
        async.flushMicrotasks();
        expect(assets.runs, isEmpty);
      });
    });

    test('server unreachable: no asset run', () {
      fakeAsync((async) {
        reachable = false;
        make().start();
        async.flushMicrotasks();
        expect(assets.runs, isEmpty);
      });
    });

    test('app resume starts an asset run', () {
      fakeAsync((async) {
        engine.outcome = SyncOutcome.backoff; // only the resume hook runs it
        final t = make()..start();
        async.flushMicrotasks();
        expect(assets.runs, isEmpty);
        t.onAppPaused();
        t.onAppResumed();
        async.flushMicrotasks();
        expect(assets.runs, [false]);
        t.stop();
        async.flushMicrotasks();
      });
    });

    test('syncNow is not awaited on the asset run', () {
      fakeAsync((async) {
        assets.hold = Completer<void>();
        final t = make()..start();
        async.flushMicrotasks();
        SyncOutcome? got;
        t.syncNow().then((o) => got = o);
        async.flushMicrotasks();
        expect(got, SyncOutcome.completed);
        assets.hold!.complete();
        async.flushMicrotasks();
      });
    });

    test('a throwing AssetSync never fails syncNow (sync throw)', () {
      fakeAsync((async) {
        assets.throwSync = StateError('boom');
        final t = make()..start();
        async.flushMicrotasks();
        SyncOutcome? got;
        t.syncNow().then((o) => got = o);
        async.flushMicrotasks();
        expect(got, SyncOutcome.completed);
        expect(assets.runs, hasLength(2));
      });
    });

    test('a throwing AssetSync never fails syncNow (async throw)', () {
      fakeAsync((async) {
        assets.throwAsync = const SocketException('down');
        final t = make()..start();
        async.flushMicrotasks();
        SyncOutcome? got;
        t.syncNow().then((o) => got = o);
        async.flushMicrotasks();
        expect(got, SyncOutcome.completed);
      });
    });

    test('a failing AssetSync provider never fails syncNow', () {
      fakeAsync((async) {
        final t = SyncTriggers(
          engine,
          _FakeNetwork(),
          _FakeOutbox(),
          DbChangeNotifier(),
          assetSync: () async => throw StateError('no dir'),
        )..start();
        async.flushMicrotasks();
        SyncOutcome? got;
        t.syncNow().then((o) => got = o);
        async.flushMicrotasks();
        expect(got, SyncOutcome.completed);
      });
    });
  });

  group('background worker', () {
    late EngineHarness h;

    setUp(() async {
      h = await EngineHarness.create();
    });
    tearDown(() => h.dispose());

    Future<SyncEngine> factory(String scope) async {
      h.activeScope = scope;
      return h.build();
    }

    Future<String?> session() async => EngineHarness.scope;

    test('after a completed sync it runs thumbnails only', () async {
      final assets = _FakeAssets();
      String? builtFor;
      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
        assetSyncFactory: (scope) async {
          builtFor = scope;
          return assets;
        },
      );
      expect(report.result, BackgroundSyncResult.success);
      expect(assets.runs, [true]);
      expect(builtFor, EngineHarness.scope);
    });

    test('an AssetSync failure never fails the worker', () async {
      final assets = _FakeAssets()..throwAsync = StateError('disk full');
      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
        assetSyncFactory: (_) async => assets,
      );
      expect(report.result, BackgroundSyncResult.success);
      expect(report.outcome, SyncOutcome.completed);

      final throwing = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
        assetSyncFactory: (_) async => throw StateError('no dir'),
      );
      expect(throwing.result, BackgroundSyncResult.success);
    });

    test('the asset run is cancelled with the budget', () async {
      final assets = _FakeAssets()..hold = Completer<void>();
      final sw = Stopwatch()..start();
      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
        assetSyncFactory: (_) async => assets,
        budget: const Duration(milliseconds: 400),
        hardStopGrace: const Duration(milliseconds: 200),
      );
      expect(report.result, BackgroundSyncResult.success);
      expect(assets.cancels, 1);
      expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test(
      'an asset run that ignores cancel is abandoned at the hard stop',
      () async {
        final hold = Completer<void>();
        // Hangs regardless of cancel.
        final hanging = _HangingAssets(hold);
        final report = await BackgroundSyncRunner.runOnce(
          readSessionKey: session,
          engineFactory: factory,
          assetSyncFactory: (_) async => hanging,
          budget: const Duration(milliseconds: 300),
          hardStopGrace: const Duration(milliseconds: 200),
        );
        expect(report.result, BackgroundSyncResult.success);
        expect(hanging.cancels, 1);
        hold.complete();
      },
    );

    test('no asset run when the sync did not complete', () async {
      final assets = _FakeAssets();
      await h.createWidget('w1');
      h.server.down = true;
      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
        assetSyncFactory: (_) async => assets,
      );
      expect(report.outcome, isNot(SyncOutcome.completed));
      expect(assets.runs, isEmpty);
    });
  });

  group('wiring', () {
    test('asset Dio is plain: no auth interceptor, no default headers', () {
      final dio = createAssetDio();
      expect(dio.interceptors, isEmpty);
      expect(dio.interceptors.whereType<SyncAuthInterceptor>(), isEmpty);
      expect(dio.options.headers, isEmpty);
      expect(dio.options.baseUrl, isEmpty);
    });

    test('BE headers are read at call time (token may change)', () async {
      String? token = 'a';
      String? tenant = 't1';
      final headers = assetBeHeaders(
        readAccessToken: () async => token,
        readTenantId: () async => tenant,
      );
      expect(await headers(), {
        'Authorization': 'Bearer a',
        'X-Tenant-ID': 't1',
      });
      token = 'b';
      expect((await headers())['Authorization'], 'Bearer b');
      token = null;
      tenant = '';
      expect(await headers(), isEmpty);
    });

    test('assets dir is <appSupport>/synced_assets', () {
      expect(
        syncedAssetsDir('/x/support').path,
        '/x/support${Platform.pathSeparator}synced_assets',
      );
    });

    group('DI', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('plugins.flutter.io/path_provider');

      setUp(() async {
        await getIt.reset();
        DependenciesProvider.build();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => '/tmp/amana_t');
      });
      tearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await getIt.reset();
      });

      test('AssetSync is a lazy singleton on the plain asset Dio', () async {
        expect(getIt.checkLazySingletonInstanceExists<AssetSync>(), isFalse);
        final dio = getIt<Dio>(instanceName: DependenciesProvider.assetDioName);
        expect(dio, isNot(same(getIt<Dio>())));
        expect(
          dio,
          isNot(
            same(getIt<Dio>(instanceName: DependenciesProvider.syncDioName)),
          ),
        );
        expect(dio.interceptors, isEmpty);
        expect(dio.options.headers, isEmpty);
        final a = await getIt.getAsync<AssetSync>();
        expect(identical(a, await getIt.getAsync<AssetSync>()), isTrue);
        // Building the triggers does not build AssetSync.
        await getIt.reset();
        DependenciesProvider.build();
        await getIt.getAsync<SyncTriggers>();
        expect(getIt.checkLazySingletonInstanceExists<AssetSync>(), isFalse);
      });

      test(
        'kill switch: startSyncIfEnabled builds no AssetSync',
        () async {
          await DependenciesProvider.startSyncIfEnabled();
          expect(getIt.checkLazySingletonInstanceExists<AssetSync>(), isFalse);
        },
        skip: kSyncEngineEnabled
            ? 'only with --dart-define=SYNC_ENGINE=false'
            : false,
      );
    });
  });
}

class _HangingAssets implements AssetSync {
  _HangingAssets(this.gate);
  final Completer<void> gate;
  int cancels = 0;

  @override
  Future<AssetSyncResult> run({
    int maxFiles = 40,
    int maxBytes = 20 * 1024 * 1024,
    bool thumbnailsOnly = false,
  }) async {
    await gate.future;
    return const AssetSyncResult(downloaded: 0, failed: 0, remaining: 0);
  }

  @override
  void cancel() => cancels++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
