import 'dart:async';

import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Triggers implements SyncTriggers {
  final log = <String>[];

  @override
  void start() => log.add('start');

  @override
  Future<void> stop() async => log.add('stop');

  @override
  void onAppResumed() => log.add('resumed');

  @override
  void onAppPaused() => log.add('paused');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Boot implements Bootstrapper {
  _Boot(this.log);
  final List<String> log;

  @override
  void cancel() => log.add('cancelBootstrap');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Registrar implements SyncDeviceRegistrar {
  final users = <String>[];

  @override
  Future<bool> registerIfNeeded({String userKey = ''}) async {
    users.add(userKey);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Outbox implements OutboxStore {
  int unsynced = 0;

  @override
  Future<int> unsyncedCount({String? scope}) async => unsynced;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _State implements SyncStateStore {
  int clears = 0;

  @override
  SyncStateStore forScope(String scope) => this;

  @override
  Future<void> clear() async => clears++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _a = SyncSession(userId: 'u1', tenantId: 't1');
const _b = SyncSession(userId: 'u2', tenantId: 't1');
const _c = SyncSession(userId: 'u3', tenantId: 't2');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Triggers triggers;
  late _Registrar registrar;
  late _Outbox outbox;
  late _State state;
  late StreamController<SyncSession?> sessions;
  late StreamController<SyncStatus> status;
  late List<SyncSessionEvent> ended;

  setUp(() {
    triggers = _Triggers();
    registrar = _Registrar();
    outbox = _Outbox();
    state = _State();
    sessions = StreamController<SyncSession?>.broadcast();
    status = StreamController<SyncStatus>.broadcast();
    ended = [];
  });

  SyncCoordinator make({SyncSession? initial}) => SyncCoordinator(
    triggers: triggers,
    guard: SyncSessionGuard(status.stream),
    registrar: registrar,
    outbox: outbox,
    state: state,
    sessions: sessions.stream,
    initialSession: initial,
    onSessionEnded: (e) async => ended.add(e),
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('nothing starts without a session', () async {
    await make().attach(observeLifecycle: false);
    await settle();
    expect(triggers.log, isEmpty);
    expect(registrar.users, isEmpty);
  });

  test('existing session at launch starts triggers and registers', () async {
    await make(initial: _a).attach(observeLifecycle: false);
    await settle();
    expect(triggers.log, ['start']);
    expect(registrar.users, ['u1|t1']);
  });

  test('logout with an empty outbox stops and clears sync state', () async {
    final c = make(initial: _a);
    await c.attach(observeLifecycle: false);
    sessions.add(null);
    await settle();
    await settle();
    expect(triggers.log, ['start', 'stop']);
    expect(state.clears, 1);
  });

  test(
    'logout with unsynced rows keeps sync state (never deletes rows)',
    () async {
      outbox.unsynced = 3;
      final c = make(initial: _a);
      await c.attach(observeLifecycle: false);
      sessions.add(null);
      await settle();
      await settle();
      expect(triggers.log, ['start', 'stop']);
      expect(state.clears, 0);
    },
  );

  test('user switch in the same tenant restarts without clearing; tenant '
      'change clears', () async {
    final c = make(initial: _a);
    await c.attach(observeLifecycle: false);
    sessions.add(_b);
    await settle();
    await settle();
    expect(triggers.log, ['start', 'stop', 'start']);
    expect(state.clears, 0);
    expect(registrar.users, ['u1|t1', 'u2|t1']);
    sessions.add(_c);
    await settle();
    await settle();
    expect(state.clears, 1);
    expect(registrar.users.last, 'u3|t2');
  });

  test('repeated identical session emissions are ignored', () async {
    final c = make(initial: _a);
    await c.attach(observeLifecycle: false);
    sessions
      ..add(_a)
      ..add(_a);
    await settle();
    await settle();
    expect(triggers.log, ['start']);
  });

  test('guard events reach the logout handler once per block', () async {
    final c = make(initial: _a);
    await c.attach(observeLifecycle: false);
    const blocked = SyncStatus(
      phase: SyncPhase.blocked,
      block: SyncBlockReason.deviceRevoked,
    );
    status
      ..add(blocked)
      ..add(blocked);
    await settle();
    expect(ended, [SyncSessionEvent.deviceRevoked]);
    expect(state.clears, 0, reason: 'a forced sign-out never wipes sync data');
  });

  test('lifecycle maps to resume / pause', () async {
    final c = make(initial: _a);
    await c.attach(observeLifecycle: false);
    c
      ..didChangeAppLifecycleState(AppLifecycleState.paused)
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(triggers.log, ['start', 'paused', 'resumed']);
  });

  test('detach stops the triggers', () async {
    final c = make(initial: _a);
    await c.attach(observeLifecycle: false);
    await c.detach();
    expect(triggers.log, ['start', 'stop']);
  });

  group('bootstrapper (Task 7)', () {
    SyncCoordinator withBoot({SyncSession? initial}) => SyncCoordinator(
      triggers: triggers,
      guard: SyncSessionGuard(status.stream),
      registrar: registrar,
      outbox: outbox,
      state: state,
      sessions: sessions.stream,
      initialSession: initial,
      onSessionEnded: (e) async => ended.add(e),
      bootstrapper: _Boot(triggers.log),
    );

    test('logout mid-bootstrap cancels it before the triggers stop', () async {
      final c = withBoot(initial: _a);
      await c.attach(observeLifecycle: false);
      sessions.add(null);
      await settle();
      await settle();
      expect(triggers.log, ['start', 'cancelBootstrap', 'stop']);
    });

    test('a scope change (user or tenant) cancels it', () async {
      final c = withBoot(initial: _a);
      await c.attach(observeLifecycle: false);
      sessions.add(_b);
      await settle();
      await settle();
      sessions.add(_c);
      await settle();
      await settle();
      expect(triggers.log, [
        'start',
        'cancelBootstrap',
        'stop',
        'start',
        'cancelBootstrap',
        'stop',
        'start',
      ]);
    });

    // Ledger T7 M2: logout stops sync BEFORE the table wipe, so no bootstrap
    // of the outgoing scope can land after the wipe.
    test('pauseForWipe cancels the bootstrap and stops the triggers; the '
        'later logout does not restart them', () async {
      final c = withBoot(initial: _a);
      await c.attach(observeLifecycle: false);
      await c.pauseForWipe();
      expect(triggers.log, ['start', 'cancelBootstrap', 'stop']);
      sessions.add(null);
      await settle();
      await settle();
      expect(triggers.log.where((e) => e == 'start').length, 1);
      c.resumeAfterFailedWipe(); // no session any more: nothing to resume
      expect(triggers.log.where((e) => e == 'start').length, 1);
    });

    test(
      'a failed logout after pauseForWipe restarts the triggers once',
      () async {
        final c = withBoot(initial: _a);
        await c.attach(observeLifecycle: false);
        await c.pauseForWipe();
        c
          ..resumeAfterFailedWipe()
          ..resumeAfterFailedWipe();
        expect(triggers.log, ['start', 'cancelBootstrap', 'stop', 'start']);
      },
    );

    test('pauseForWipe without a session does nothing', () async {
      final c = withBoot();
      await c.attach(observeLifecycle: false);
      await c.pauseForWipe();
      c.resumeAfterFailedWipe();
      expect(triggers.log, isEmpty);
    });

    test('detach cancels it', () async {
      final c = withBoot(initial: _a);
      await c.attach(observeLifecycle: false);
      await c.detach();
      expect(triggers.log, ['start', 'cancelBootstrap', 'stop']);
    });
  });
}
