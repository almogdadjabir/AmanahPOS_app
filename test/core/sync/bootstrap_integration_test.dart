import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/background/background_sync.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bootstrap_harness.dart';

class _Network implements NetworkMonitor {
  final ctrl = StreamController<bool>.broadcast(sync: true);

  @override
  Stream<bool> get onStatusChanged => ctrl.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Registrar implements SyncDeviceRegistrar {
  @override
  Future<bool> registerIfNeeded({String userKey = ''}) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Task 7: engine + triggers + bootstrapper + coordinator wired together on
/// a real in-memory DB and the FakeSyncServer.
void main() {
  late BootHarness h;
  late SyncEngine engine;
  late Bootstrapper boot;
  late SyncTriggers triggers;
  late List<BootstrapStatus> statuses;
  late List<FlutterErrorDetails> reported;
  var gateOpen = false;
  final network = _Network();
  FlutterExceptionHandler? prevOnError;

  setUp(() async {
    h = await BootHarness.create();
    engine = h.buildEngine();
    boot = h.build(); // pageSize 2, authedFor = engine.authedFor
    statuses = [];
    boot.status.listen(statuses.add);
    gateOpen = false;
    triggers = SyncTriggers(
      engine,
      network,
      OutboxStore(h.odb, now: h.now),
      h.notifier,
      now: h.now,
      canSync: () async => gateOpen,
      bootstrapper: boot,
    );
    reported = [];
    prevOnError = FlutterError.onError;
    FlutterError.onError = reported.add;
  });

  tearDown(() async {
    FlutterError.onError = prevOnError;
    await triggers.stop();
    SyncScope.current = null;
    await h.dispose();
  });

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  /// Started triggers whose initial kick was gated off; manual syncs next.
  Future<void> startQuiet() async {
    triggers.start();
    await pump();
    gateOpen = true;
  }

  Future<SyncOutcome?> firstSetup() async {
    h.seedStandard();
    await startQuiet();
    return triggers.syncNow();
  }

  Future<int> outboxCount() async =>
      (await h.db.rawQuery('SELECT COUNT(*) c FROM outbox')).first['c'] as int;

  Future<void> rejectedOutboxRow() => h.db.insert('outbox', {
    'mutation_id': 'm-rejected',
    'entity': 'sale',
    'op': 'create',
    'entity_id': 'sale-1',
    'occurred_at': h.clock.toIso8601String(),
    'payload_json': '{}',
    'status': 'rejected',
    'created_at': h.clock.toIso8601String(),
    'scope': BootHarness.scope,
  });

  Future<Map<String, Object?>> outboxRow() async =>
      (await h.db.query('outbox', where: "mutation_id = 'm-rejected'")).single;

  test('no cursor + online: engine says needsBootstrap, the triggers run the '
      'bootstrapper, then the engine pulls the rows written meanwhile and '
      'ends completed', () async {
    h.server.onBootstrapPage = (entity, i) {
      if (entity == 'category' && i == 0) {
        h.server.onBootstrapPage = null;
        h.seedProduct('p9'); // after the snapshot: only pull delivers it
      }
    };
    expect(await firstSetup(), SyncOutcome.completed);
    expect(h.transport.manifestCalls, 1);
    expect(statuses.last.outcome, BootstrapOutcome.completed);
    expect(await h.scoped.isBootstrapped(), isTrue);
    expect(await h.scoped.cursor(), isNotNull);
    expect(await h.progress(), isNull);
    expect(await h.ids('products'), ['p1', 'p2', 'p3', 'p4', 'p5', 'p9']);
    expect(engine.current.phase, SyncPhase.idle);
    expect(engine.current.lastSyncedAt, isNotNull);
  });

  test('full_resync_required later: bootstrapped, local rows and the outbox '
      'are kept, the app re-bootstraps with a NEW snapshot', () async {
    expect(await firstSetup(), SyncOutcome.completed);
    final firstCursor = await h.scoped.cursor();
    await rejectedOutboxRow();
    final row = await outboxRow();

    h.advance(const Duration(hours: 2));
    h.seedProduct('p10'); // head moves: the next snapshot differs
    h.server.fullResyncRequired = true;
    // The engine alone: reset, refresh needed, nothing lost.
    expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
    expect(await h.scoped.cursor(), isNull);
    expect(await h.scoped.isBootstrapped(), isTrue, reason: 'non-blocking');
    expect(await h.ids('products'), hasLength(5), reason: 'rows stay visible');
    expect(await outboxRow(), row);

    h.server.fullResyncRequired = false;
    expect(await triggers.syncNow(), SyncOutcome.completed);
    expect(h.transport.manifestCalls, 2);
    final secondCursor = await h.scoped.cursor();
    expect(secondCursor, isNot(firstCursor), reason: 'a NEW snapshot');
    expect(await h.ids('products'), hasLength(6));
    expect(await h.scoped.isBootstrapped(), isTrue);
    expect(await outboxRow(), row);
    expect(await outboxCount(), 1);
  });

  test('a bootstrap whose first pull answers full_resync_required again '
      '(within 10 min) backs off loudly instead of restarting', () async {
    h.seedStandard();
    h.server.fullResyncRequired = true; // e.g. it spanned a prune window
    await startQuiet();
    expect(await triggers.syncNow(), SyncOutcome.backoff);
    expect(h.transport.manifestCalls, 1, reason: 'no immediate restart');
    expect(await h.scoped.isBootstrapped(), isTrue);
    expect(await h.scoped.cursor(), isNotNull, reason: 'not reset yet');
    expect(engine.current.phase, SyncPhase.backoff);
    expect(engine.current.nextRetryAt, isNotNull);
    expect(reported, hasLength(1));

    // Bounded restart: once the window has passed, the reset happens.
    h.advance(const Duration(minutes: 11));
    expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
    expect(await h.scoped.cursor(), isNull);
  });

  test('logout mid-bootstrap: the coordinator cancels it after the page in '
      'flight; nothing after it is requested or written', () async {
    h.seedStandard();
    final sessions = StreamController<SyncSession?>.broadcast();
    final status = StreamController<SyncStatus>.broadcast();
    addTearDown(sessions.close);
    addTearDown(status.close);
    final coordinator = SyncCoordinator(
      triggers: triggers,
      guard: SyncSessionGuard(status.stream),
      registrar: _Registrar(),
      outbox: OutboxStore(h.odb, now: h.now),
      state: h.state,
      sessions: sessions.stream,
      initialSession: const SyncSession(userId: 'u1', tenantId: 't1'),
      onSessionEnded: (_) async {},
      bootstrapper: boot,
    );
    final cancelled = Completer<void>();
    h.transport.beforePage = (n, _) async {
      if (n != 2) return;
      sessions.add(null); // logout while page 2 is on the wire
      await pump();
      cancelled.complete();
    };
    gateOpen = true;
    await coordinator.attach(observeLifecycle: false);
    await cancelled.future;
    for (var i = 0; i < 20 && triggers.isStarted; i++) {
      await pump();
    }
    await coordinator.detach();
    expect(triggers.isStarted, isFalse);
    expect(statuses.last.outcome, BootstrapOutcome.interrupted);
    expect(h.transport.pageRequests, hasLength(2));
    expect(await h.ids('categories'), ['c1', 'c2', 'c3']);
    expect(await h.ids('products'), isEmpty);
    // Empty outbox: the logout reset drops the scope's progress (the
    // logout table wipe drops the rows too, ruling T1-d).
    expect(await h.progress(), isNull);
    expect(await h.scoped.isBootstrapped(), isFalse);
    expect(await h.scoped.cursor(), isNull);
  });

  for (final wipe in <String, Future<void> Function(BootHarness)>{
    'clearAllOnLogout': (h) => OfflineLocalCache(h.odb).clearAllOnLogout(),
    'clearAllLocalOfflineData': (h) => h.odb.clearAllLocalOfflineData(),
  }.entries) {
    test('${wipe.key} (table wipe) clears cursor + bootstrapped of every scope '
        'together; outbox, refunds and the device id are kept', () async {
      expect(await firstSetup(), SyncOutcome.completed);
      final other = h.state.forScope('u2|t2');
      await h.db.transaction((t) async {
        await other.setCursor(t, 'c-other');
        await other.setBootstrapped(t, true);
      });
      final deviceId = await h.state.deviceId();
      await rejectedOutboxRow();
      final row = await outboxRow();
      await h.db.insert('sale_refunds', {
        'id': 'r1',
        'sale_id': 'sale-1',
        'shop_id': 's1',
        'total': '1.000',
        'occurred_at': '2026-11-16T10:00:00Z',
        'method': 'cash',
        'json': '{}',
      });

      await triggers.stop();
      await wipe.value(h);

      for (final s in [h.scoped, other]) {
        expect(await s.cursor(), isNull);
        expect(await s.isBootstrapped(), isFalse);
        expect(await s.bootstrapProgress(h.db), isNull);
      }
      expect(await h.ids('products'), isEmpty);
      expect(await outboxRow(), row);
      expect(await h.ids('sale_refunds'), ['r1']);
      expect(await h.state.deviceId(), deviceId);

      // The next sign-in sets up again (blocking first setup).
      gateOpen = false;
      await startQuiet();
      expect(await triggers.syncNow(), SyncOutcome.completed);
      expect(h.transport.manifestCalls, 2);
      expect(await h.ids('products'), hasLength(5));
    });
  }

  test('the background worker never bootstraps: it reports success on '
      'needsBootstrap and leaves first setup to the app', () async {
    h.seedStandard();
    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: () async => BootHarness.scope,
      engineFactory: (_) async => h.buildEngine(),
    );
    expect(report.outcome, SyncOutcome.needsBootstrap);
    expect(report.result, BackgroundSyncResult.success);
    expect(h.server.bootstrapManifestCalls, 0);
    expect(h.server.bootstrapPageCalls, 0);
    expect(await h.scoped.isBootstrapped(), isFalse);
  });
}
