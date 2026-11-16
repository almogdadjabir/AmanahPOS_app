import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
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
  Future<SyncOutcome> syncNow({SyncReason reason = SyncReason.manual}) async {
    calls.add(reason);
    if (runFor > Duration.zero) await Future<void>.delayed(runFor);
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOutbox implements OutboxStore {
  int pending = 1;

  @override
  Future<int> pendingCount() async => pending;

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
      async.elapse(const Duration(seconds: 5)); // afterWrite also alreadyRunning
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

  test('connectivity regained bypasses a network backoff but not maintenance',
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
  });

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
}
