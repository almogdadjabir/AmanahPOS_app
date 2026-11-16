import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/engine_harness.dart';

class _Net implements NetworkMonitor {
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

const _a = SyncSession(userId: 'u1', tenantId: 't1');

Future<void> _until(bool Function() ok) async {
  for (var i = 0; i < 400 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(ok(), isTrue, reason: 'condition not reached in time');
}

Future<void> _pause([int ms = 150]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late EngineHarness h;
  late SyncEngine engine;
  late SyncTriggers triggers;

  setUp(() async {
    h = await EngineHarness.create();
    engine = h.build();
    triggers = SyncTriggers(engine, _Net(), h.outbox, h.notifier);
  });

  tearDown(() async {
    await triggers.stop();
    SyncScope.current = null;
    await h.dispose();
  });

  test('stop() waits for a slow in-flight run and cancels it', () async {
    final gate = Completer<void>();
    var inPull = false;
    h.transport.onBeforeSend = (op) async {
      if (op == 'pull') {
        inPull = true;
        await gate.future;
      }
    };
    triggers.start();
    await _until(() => inPull);

    var stopped = false;
    final stopFuture = triggers.stop().then((_) => stopped = true);
    await _pause();
    expect(stopped, isFalse, reason: 'stop must wait for the run');

    gate.complete();
    await stopFuture;
    expect(h.engine!.current.phase, isNot(SyncPhase.pulling));
  });

  test('logout: no cursor is written after the sync state clear', () async {
    final gate = Completer<void>();
    var inPull = false;
    h.transport.onBeforeSend = (op) async {
      if (op == 'pull') {
        inPull = true;
        await gate.future;
      }
    };
    await h.otherDevice('x'); // a page that would move the cursor
    final sessions = StreamController<SyncSession?>.broadcast();
    final guardStatus = StreamController<SyncStatus>.broadcast();
    final coordinator = SyncCoordinator(
      triggers: triggers,
      guard: SyncSessionGuard(guardStatus.stream),
      registrar: _Registrar(),
      outbox: h.outbox,
      state: h.state,
      sessions: sessions.stream,
      initialSession: _a,
      onSessionEnded: (_) async {},
    );
    await coordinator.attach(observeLifecycle: false);
    await _until(() => inPull);

    sessions.add(null);
    await _pause();
    gate.complete();
    await _pause(400);

    expect(
      await h.state.cursor(),
      isNull,
      reason: 'a stale run wrote the cursor after clear()',
    );
    await coordinator.detach();
    await sessions.close();
    await guardStatus.close();
  });

  test('stop() then start() starts a fresh run', () async {
    final gate = Completer<void>();
    var inPush = false;
    h.transport.onBeforeSend = (op) async {
      if (op == 'push' && !inPush) {
        inPush = true;
        await gate.future;
      }
    };
    await h.createWidget('w1');
    triggers.start();
    await _until(() => inPush);
    final stopFuture = triggers.stop();
    gate.complete();
    await stopFuture;
    final pullsAfterStop = h.transport.pullCalls;
    expect(pullsAfterStop, 0, reason: 'cancelled run must not pull');

    triggers.start();
    await _until(() => h.transport.pullCalls > pullsAfterStop);
    await triggers.stop();
  });

  test('cancel mid-run releases the claim without an attempt bump', () async {
    await h.createWidget('w1');
    final id = (await h.db.query('outbox')).single['mutation_id'] as String;
    // 1st read: top of the push loop, 2nd: right after the batch was claimed.
    h.onSessionRead = (n) {
      if (n == 2) engine.cancel();
    };
    final outcome = await engine.syncNow();
    expect(outcome, SyncOutcome.cancelled);
    final row = await h.outboxRow(id);
    expect(row['status'], 'pending');
    expect(row['attempts'], 0);
    expect(h.transport.pushCalls, 0);
    expect(h.serverProductCount, 0);

    // The flag is per run: the next run pushes normally.
    h.onSessionRead = null;
    expect(await engine.syncNow(), SyncOutcome.completed);
    expect(h.serverProductCount, 1);
  });

  group('session guard', () {
    test('ignores engine events while the session is null', () async {
      final ctrl = StreamController<SyncStatus>.broadcast(sync: true);
      var session = true;
      final guard = SyncSessionGuard(ctrl.stream, hasSession: () => session)
        ..start();
      final events = <SyncSessionEvent>[];
      guard.events.listen(events.add);

      session = false;
      ctrl.add(
        const SyncStatus(
          phase: SyncPhase.blocked,
          block: SyncBlockReason.tokenExpired,
        ),
      );
      await _pause(20);
      expect(events, isEmpty);

      session = true;
      ctrl.add(
        const SyncStatus(
          phase: SyncPhase.blocked,
          block: SyncBlockReason.tokenExpired,
        ),
      );
      await _pause(20);
      expect(events, [SyncSessionEvent.needsLogin]);
      await guard.dispose();
      await ctrl.close();
    });
  });

  test('a second concurrent stop() also waits for the in-flight run', () async {
    final gate = Completer<void>();
    var inPull = false;
    h.transport.onBeforeSend = (op) async {
      if (op == 'pull') {
        inPull = true;
        await gate.future;
      }
    };
    triggers.start();
    await _until(() => inPull);

    var firstDone = false;
    var secondDone = false;
    final first = triggers.stop().then((_) => firstDone = true);
    final second = triggers.stop().then((_) => secondDone = true);
    await _pause();
    expect(firstDone, isFalse);
    expect(secondDone, isFalse, reason: 'second stop returned early');

    gate.complete();
    await Future.wait([first, second]);
    expect(secondDone, isTrue);
  });
}
