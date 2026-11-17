import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEngine implements SyncEngine {
  final calls = <SyncReason>[];
  SyncOutcome outcome = SyncOutcome.completed;
  Duration runFor = Duration.zero;
  SyncStatus cur = const SyncStatus();

  @override
  SyncStatus get current => cur;

  @override
  void cancel() {}

  bool busy = false;
  _FakeBootstrapper? boot;

  @override
  Future<SyncOutcome> syncNow({SyncReason reason = SyncReason.manual}) async {
    calls.add(reason);
    if (boot?.busy ?? false) boot!.overlapped = true;
    busy = true;
    try {
      if (runFor > Duration.zero) await Future<void>.delayed(runFor);
    } finally {
      busy = false;
    }
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records runs; [busy] is true while a run is in flight so tests can check
/// the engine and the bootstrapper never overlap.
class _FakeBootstrapper implements Bootstrapper {
  _FakeBootstrapper(this.engine);
  final _FakeEngine engine;
  int runs = 0;
  int cancels = 0;
  bool busy = false;
  bool overlapped = false;
  BootstrapOutcome outcome = BootstrapOutcome.completed;
  Duration runFor = Duration.zero;

  /// Outcome the engine returns once this bootstrap completed.
  SyncOutcome afterComplete = SyncOutcome.completed;

  /// Status after the last run (what the triggers read on `blocked`).
  BootstrapStatus last = const BootstrapStatus();

  @override
  BootstrapStatus get current => last;

  @override
  void cancel() => cancels++;

  @override
  Future<BootstrapOutcome> run() async {
    runs++;
    if (engine.busy) overlapped = true;
    busy = true;
    try {
      if (runFor > Duration.zero) await Future<void>.delayed(runFor);
    } finally {
      busy = false;
    }
    if (outcome == BootstrapOutcome.completed) engine.outcome = afterComplete;
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOutbox implements OutboxStore {
  int pending = 1;

  @override
  Future<int> pendingCount({String? scope}) async => pending;

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

void main() {
  final t0 = DateTime.utc(2026, 11, 16, 9);

  late _FakeEngine engine;
  late _FakeOutbox outbox;
  late _FakeNetwork network;
  late DbChangeNotifier notifier;

  setUp(() {
    engine = _FakeEngine();
    outbox = _FakeOutbox();
    network = _FakeNetwork();
    notifier = DbChangeNotifier();
  });

  SyncTriggers make(FakeAsync async, {Future<bool> Function()? gate}) =>
      SyncTriggers(
        engine,
        network,
        outbox,
        notifier,
        now: () => t0.add(async.elapsed),
        canSync: gate,
      );

  /// Starts the triggers and swallows the initial kick so each test counts
  /// only the triggers it exercises.
  SyncTriggers started(FakeAsync async, {Future<bool> Function()? gate}) {
    final t = make(async, gate: gate)..start();
    async.flushMicrotasks();
    expect(engine.calls, [SyncReason.resume], reason: 'initial kick');
    engine.calls.clear();
    return t;
  }

  test('nothing fires before start()', () {
    fakeAsync((async) {
      make(async);
      notifier.notify({SyncTables.outbox});
      network.ctrl.add(false);
      network.ctrl.add(true);
      async.elapse(const Duration(minutes: 30));
      expect(engine.calls, isEmpty);
    });
  });

  test('start() kicks one sync', () {
    fakeAsync((async) {
      make(async).start();
      async.flushMicrotasks();
      expect(engine.calls, [SyncReason.resume]);
    });
  });

  test('10 outbox notifications within 5 s -> one syncNow', () {
    fakeAsync((async) {
      started(async);
      for (var i = 0; i < 10; i++) {
        notifier.notify({SyncTables.outbox});
        async.elapse(const Duration(milliseconds: 400));
      }
      async.elapse(const Duration(seconds: 5));
      expect(engine.calls, [SyncReason.afterWrite]);
    });
  });

  test('outbox notification without pending rows does not sync', () {
    fakeAsync((async) {
      started(async);
      outbox.pending = 0; // e.g. the engine's own result writes
      notifier.notify({SyncTables.outbox});
      async.elapse(const Duration(seconds: 6));
      expect(engine.calls, isEmpty);
    });
  });

  test('notifications for other tables are ignored', () {
    fakeAsync((async) {
      started(async);
      notifier.notify({'products'});
      async.elapse(const Duration(seconds: 6));
      expect(engine.calls, isEmpty);
    });
  });

  test('resume triggers one', () {
    fakeAsync((async) {
      final t = started(async);
      t.onAppResumed();
      async.flushMicrotasks();
      expect(engine.calls, [SyncReason.resume]);
    });
  });

  test('connectivity false -> true triggers one; repeats do not', () {
    fakeAsync((async) {
      started(async);
      network.ctrl.add(false);
      async.flushMicrotasks();
      expect(engine.calls, isEmpty);
      network.ctrl.add(true);
      async.flushMicrotasks();
      network.ctrl.add(true); // duplicate event from connectivity_plus
      async.flushMicrotasks();
      expect(engine.calls, [SyncReason.connectivity]);
    });
  });

  test('periodic fires while foreground, not while paused', () {
    fakeAsync((async) {
      final t = started(async);
      async.elapse(const Duration(minutes: 5));
      expect(engine.calls, [SyncReason.periodic]);
      t.onAppPaused();
      async.elapse(const Duration(minutes: 30));
      expect(engine.calls, [SyncReason.periodic]);
      t.onAppResumed();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 5));
      expect(engine.calls, [
        SyncReason.periodic,
        SyncReason.resume,
        SyncReason.periodic,
      ]);
    });
  });

  test('stop() cancels timers and listeners', () {
    fakeAsync((async) {
      final t = started(async);
      notifier.notify({SyncTables.outbox}); // debounce timer armed
      t.stop();
      async.flushMicrotasks();
      network.ctrl.add(false);
      network.ctrl.add(true);
      t.onAppResumed();
      async.elapse(const Duration(hours: 1));
      expect(engine.calls, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('triggers during an own run coalesce into one follow-up run', () {
    fakeAsync((async) {
      final t = started(async);
      engine.runFor = const Duration(seconds: 10);
      t.onAppResumed();
      async.flushMicrotasks();
      t.onAppResumed();
      t.onAppResumed();
      network.ctrl.add(false);
      network.ctrl.add(true);
      async.elapse(const Duration(seconds: 10)); // first run completes
      async.elapse(const Duration(seconds: 10)); // the single follow-up
      expect(engine.calls, [SyncReason.resume, SyncReason.resume]);
      // No timer storm left behind.
      async.elapse(const Duration(minutes: 4));
      expect(engine.calls.length, 2);
    });
  });

  test('alreadyRunning (other runner) schedules exactly one retry after the '
      'lock TTL', () {
    fakeAsync((async) {
      final t = started(async);
      t.onAppPaused(); // no periodic noise
      engine.outcome = SyncOutcome.alreadyRunning;
      t.onAppResumed();
      t.onAppPaused();
      async.flushMicrotasks();
      notifier.notify({SyncTables.outbox});
      async.elapse(
        const Duration(seconds: 5),
      ); // afterWrite also alreadyRunning
      expect(engine.calls, [SyncReason.resume, SyncReason.afterWrite]);
      engine.outcome = SyncOutcome.completed;
      async.elapse(const Duration(seconds: 100));
      expect(engine.calls.length, 2, reason: 'no tight loop');
      async.elapse(const Duration(seconds: 20)); // t = 2 min
      expect(engine.calls.length, 3);
      async.elapse(const Duration(minutes: 10));
      expect(engine.calls.length, 3, reason: 'exactly one retry');
    });
  });

  test('backoff honours nextRetryAt instead of firing immediately', () {
    fakeAsync((async) {
      final t = started(async);
      engine.outcome = SyncOutcome.backoff;
      engine.cur = SyncStatus(
        phase: SyncPhase.backoff,
        nextRetryAt: t0.add(const Duration(seconds: 90)),
      );
      t.syncNow();
      async.flushMicrotasks();
      expect(engine.calls, [SyncReason.manual]);
      engine.outcome = SyncOutcome.completed;

      notifier.notify({SyncTables.outbox});
      t.onAppResumed();
      async.elapse(const Duration(seconds: 60));
      expect(engine.calls, [SyncReason.manual], reason: 'deferred');

      async.elapse(const Duration(seconds: 31));
      expect(engine.calls.length, 2, reason: 'one run at nextRetryAt');
      async.elapse(const Duration(minutes: 3));
      expect(engine.calls.length, 2);
    });
  });

  test(
    'connectivity regained bypasses a network backoff but not maintenance',
    () {
      fakeAsync((async) {
        final t = started(async);
        t.onAppPaused();
        engine.outcome = SyncOutcome.backoff;
        engine.cur = SyncStatus(
          phase: SyncPhase.backoff,
          block: SyncBlockReason.maintenance,
          nextRetryAt: t0.add(const Duration(minutes: 10)),
        );
        t.syncNow();
        async.flushMicrotasks();
        network.ctrl.add(false);
        network.ctrl.add(true);
        async.flushMicrotasks();
        expect(engine.calls, [SyncReason.manual], reason: 'maintenance wins');

        engine.cur = SyncStatus(
          phase: SyncPhase.backoff,
          nextRetryAt: t0.add(const Duration(minutes: 10)),
        );
        t.syncNow();
        async.flushMicrotasks();
        network.ctrl.add(false);
        network.ctrl.add(true);
        async.flushMicrotasks();
        expect(engine.calls, [
          SyncReason.manual,
          SyncReason.manual,
          SyncReason.connectivity,
        ]);
      });
    },
  );

  test('gate (session/capabilities) false -> engine never called', () {
    fakeAsync((async) {
      var allowed = false;
      final t = make(async, gate: () async => allowed)..start();
      async.flushMicrotasks();
      t.onAppResumed();
      notifier.notify({SyncTables.outbox});
      async.elapse(const Duration(minutes: 6));
      expect(engine.calls, isEmpty);
      allowed = true;
      t.onAppResumed();
      async.flushMicrotasks();
      expect(engine.calls, [SyncReason.resume]);
    });
  });

  test('manual syncNow returns null before start and the outcome after', () {
    fakeAsync((async) {
      final t = make(async);
      SyncOutcome? before = SyncOutcome.completed;
      t.syncNow().then((v) => before = v);
      async.flushMicrotasks();
      expect(before, isNull);
      t.start();
      async.flushMicrotasks();
      SyncOutcome? after;
      t.syncNow().then((v) => after = v);
      async.flushMicrotasks();
      expect(after, SyncOutcome.completed);
    });
  });

  group('background work hook', () {
    late int requests;
    SyncTriggers withHook(FakeAsync async, {Set<String> refresh = const {}}) {
      requests = 0;
      final t = SyncTriggers(
        engine,
        network,
        outbox,
        notifier,
        now: () => t0.add(async.elapsed),
        onBackgroundWork: () => requests++,
        resumeRefreshTables: refresh,
      )..start();
      async.flushMicrotasks();
      engine.calls.clear();
      return t;
    }

    test('paused with pending rows requests the worker once', () {
      fakeAsync((async) {
        final t = withHook(async);
        t.onAppPaused();
        async.flushMicrotasks();
        notifier.notify({SyncTables.outbox});
        async.flushMicrotasks();
        t.onAppPaused();
        async.flushMicrotasks();
        expect(requests, 1);
      });
    });

    test('paused without pending rows requests nothing', () {
      fakeAsync((async) {
        outbox.pending = 0;
        final t = withHook(async);
        t.onAppPaused();
        async.flushMicrotasks();
        expect(requests, 0);
      });
    });

    test('foreground writes never request the worker', () {
      fakeAsync((async) {
        withHook(async);
        notifier.notify({SyncTables.outbox});
        async.elapse(const Duration(seconds: 6));
        expect(requests, 0);
      });
    });

    test('a write while paused requests it; resume re-arms', () {
      fakeAsync((async) {
        outbox.pending = 0;
        final t = withHook(async);
        t.onAppPaused();
        async.flushMicrotasks();
        expect(requests, 0);
        outbox.pending = 1;
        notifier.notify({SyncTables.outbox});
        async.flushMicrotasks();
        expect(requests, 1);
        t.onAppResumed();
        async.flushMicrotasks();
        t.onAppPaused();
        async.flushMicrotasks();
        expect(requests, 2);
      });
    });

    test('resume notifies the refresh tables', () {
      fakeAsync((async) {
        final seen = <Set<String>>[];
        notifier.changes.listen(seen.add);
        final t = withHook(async, refresh: {'sales', 'stock'});
        t.onAppPaused();
        t.onAppResumed();
        async.flushMicrotasks();
        expect(seen, contains(equals({'sales', 'stock'})));
      });
    });
  });

  // ------------------------------------------------- phase 2 (Task 7)
  group('bootstrap on needsBootstrap', () {
    late _FakeBootstrapper boot;

    SyncTriggers withBoot(FakeAsync async, {bool swallowKick = true}) {
      boot = _FakeBootstrapper(engine);
      engine.boot = boot;
      final t = SyncTriggers(
        engine,
        network,
        outbox,
        notifier,
        now: () => t0.add(async.elapsed),
        bootstrapper: boot,
      );
      return t;
    }

    test('needsBootstrap -> bootstrapper runs, then the engine runs once '
        'more and its outcome is returned', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        t.start();
        async.flushMicrotasks();
        expect(boot.runs, 1);
        expect(engine.calls, [SyncReason.resume, SyncReason.resume]);
        SyncOutcome? out;
        t.syncNow().then((o) => out = o);
        async.flushMicrotasks();
        expect(out, SyncOutcome.completed);
        expect(boot.runs, 1, reason: 'no bootstrap when not needed');
      });
    });

    test('the re-run happens once even if the engine still says '
        'needsBootstrap', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.afterComplete = SyncOutcome.needsBootstrap;
        t.start();
        async.elapse(const Duration(minutes: 1));
        expect(boot.runs, 1);
        expect(engine.calls.length, 2);
      });
    });

    test('engine and bootstrapper never overlap; triggers during the '
        'bootstrap coalesce into one follow-up', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        engine.runFor = const Duration(seconds: 1);
        boot.runFor = const Duration(seconds: 30);
        t.start();
        async.elapse(const Duration(seconds: 5)); // inside the bootstrap
        expect(boot.busy, isTrue);
        t.onAppResumed();
        network.ctrl.add(false);
        network.ctrl.add(true);
        t.syncNow();
        async.flushMicrotasks();
        expect(engine.calls, [SyncReason.resume], reason: 'single flight');
        async.elapse(const Duration(minutes: 1));
        expect(boot.overlapped, isFalse);
        // resume, re-run after the bootstrap, ONE follow-up.
        expect(engine.calls.length, 3);
        expect(boot.runs, 1);
      });
    });

    test('interrupted (offline): no engine re-run; connectivity and resume '
        'retry it', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.outcome = BootstrapOutcome.interrupted;
        t.start();
        async.flushMicrotasks();
        expect(boot.runs, 1);
        expect(engine.calls.length, 1);
        network.ctrl.add(false);
        network.ctrl.add(true);
        async.flushMicrotasks();
        expect(boot.runs, 2);
        t.onAppResumed();
        async.flushMicrotasks();
        expect(boot.runs, 3);
        boot.outcome = BootstrapOutcome.completed;
        t.onAppResumed();
        async.flushMicrotasks();
        expect(boot.runs, 4);
        expect(engine.calls.last, SyncReason.resume);
        expect(engine.calls.length, 5, reason: '4 runs + 1 re-run');
      });
    });

    test('blocked (serverNotReady/token/account) is not retried by timers, '
        'resume or connectivity; only a manual sync retries it', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.outcome = BootstrapOutcome.blocked;
        t.start();
        async.flushMicrotasks();
        expect(boot.runs, 1);
        async.elapse(const Duration(minutes: 11)); // 2 periodic runs
        notifier.notify({SyncTables.outbox});
        async.elapse(const Duration(seconds: 6)); // afterWrite
        t.onAppResumed();
        network.ctrl.add(false);
        network.ctrl.add(true);
        async.flushMicrotasks();
        expect(boot.runs, 1, reason: 'held while blocked');
        expect(engine.calls.length, greaterThan(3), reason: 'push still runs');
        t.syncNow();
        async.flushMicrotasks();
        expect(boot.runs, 2, reason: 'manual retry');
      });
    });

    // Ledger T7 M1: "server not ready" may be fixed by a server deploy while
    // the app sits in the background; app resume retries it. Token / account
    // blocks keep the hold (manual / new session only).
    test('blocked serverNotReady: app resume clears the hold (timers and '
        'connectivity still do not)', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.outcome = BootstrapOutcome.blocked;
        boot.last = const BootstrapStatus(outcome: BootstrapOutcome.blocked);
        expect(boot.last.serverNotReady, isTrue);
        t.start();
        async.flushMicrotasks();
        expect(boot.runs, 1);
        async.elapse(const Duration(minutes: 11));
        network.ctrl.add(false);
        network.ctrl.add(true);
        async.flushMicrotasks();
        expect(boot.runs, 1, reason: 'held for timers/connectivity');
        t.onAppResumed();
        async.flushMicrotasks();
        expect(boot.runs, 2, reason: 'resume retries serverNotReady');
      });
    });

    test('blocked tokenExpired / accountDisabled: resume keeps the hold', () {
      for (final reason in [
        SyncBlockReason.tokenExpired,
        SyncBlockReason.accountDisabled,
      ]) {
        fakeAsync((async) {
          final t = withBoot(async);
          engine.outcome = SyncOutcome.needsBootstrap;
          boot.outcome = BootstrapOutcome.blocked;
          boot.last = BootstrapStatus(
            outcome: BootstrapOutcome.blocked,
            block: reason,
          );
          t.start();
          async.flushMicrotasks();
          t.onAppResumed();
          t.onAppResumed();
          async.flushMicrotasks();
          expect(boot.runs, 1, reason: '$reason held on resume');
          t.syncNow();
          async.flushMicrotasks();
          expect(boot.runs, 2, reason: 'manual retry');
        });
      }
    });

    test('a new session (start after stop) clears the blocked hold', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.outcome = BootstrapOutcome.blocked;
        t.start();
        async.flushMicrotasks();
        t.stop();
        async.flushMicrotasks();
        t.start();
        async.flushMicrotasks();
        expect(boot.runs, 2);
      });
    });

    test('bootstrap alreadyRunning (other runner) -> one retry after the '
        'lock TTL', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.outcome = BootstrapOutcome.alreadyRunning;
        t.start();
        t.onAppPaused(); // no periodic noise; resume kick already queued
        async.flushMicrotasks();
        expect(boot.runs, 0, reason: 'paused: no bootstrap (foreground only)');
        t.onAppResumed();
        t.onAppPaused();
        async.flushMicrotasks();
        expect(boot.runs, 0);
        t.onAppResumed();
        async.flushMicrotasks();
        expect(boot.runs, 1);
        t.onAppPaused();
        engine.outcome = SyncOutcome.completed;
        async.elapse(const Duration(minutes: 2));
        expect(engine.calls.length, 4, reason: 'one retry after the TTL');
        async.elapse(const Duration(minutes: 10));
        expect(engine.calls.length, 4);
      });
    });

    // (That stop() waits for the bootstrap is covered with real time in
    // bootstrap_integration_test: subscription cancels resolve outside
    // fakeAsync.)
    test('stop() during a bootstrap cancels it at once; no engine re-run '
        'follows it', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        boot.runFor = const Duration(seconds: 30);
        t.start();
        async.elapse(const Duration(seconds: 1));
        expect(boot.busy, isTrue);
        t.stop();
        expect(boot.cancels, 1);
        async.elapse(const Duration(seconds: 30));
        expect(boot.busy, isFalse);
        expect(engine.calls.length, 1, reason: 'no re-run after stop');
      });
    });

    test('stop() while the engine runs: no bootstrap starts afterwards', () {
      fakeAsync((async) {
        final t = withBoot(async);
        engine.outcome = SyncOutcome.needsBootstrap;
        engine.runFor = const Duration(seconds: 5);
        t.start();
        async.elapse(const Duration(seconds: 1));
        t.stop();
        async.elapse(const Duration(seconds: 10));
        expect(boot.runs, 0);
      });
    });
  });
}
