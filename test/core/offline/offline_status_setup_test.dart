import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrap_controller.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNet implements NetworkMonitor {
  bool online = true;
  final ctrl = StreamController<bool>.broadcast(sync: true);

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> get onStatusChanged => ctrl.stream;

  @override
  void start() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the Task 7 controller: progress stream, `bootstrapped`
/// flag of the current scope, manual retry.
class _FakeSetup implements BootstrapController {
  final ctrl = StreamController<BootstrapStatus>.broadcast(sync: true);
  bool bootstrapped = false;

  /// Another user of the same tenant finished first setup (ruling T11-a).
  bool otherUserOfTenantBootstrapped = false;
  BootstrapStatus cur = const BootstrapStatus(scope: 'u1|t1');
  int retries = 0;
  String? scope = 'u1|t1';

  /// Called inside the readiness read (simulates a run finishing then).
  void Function()? duringRead;
  Object? retryResult = SyncOutcome.needsBootstrap;

  void push(BootstrapStatus s) {
    cur = s;
    ctrl.add(s);
  }

  @override
  Stream<BootstrapStatus> get status => ctrl.stream;

  @override
  BootstrapStatus get current => cur;

  @override
  Future<bool> isTenantBootstrapped() async {
    final v = bootstrapped || otherUserOfTenantBootstrapped;
    final hook = duringRead;
    duringRead = null;
    hook?.call();
    return v; // the value read BEFORE the hook ran
  }

  @override
  String? get liveScope => scope;

  @override
  Future<Object?> retry() async {
    retries++;
    return retryResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _running = BootstrapStatus(
  scope: 'u1|t1',
  currentEntity: 'product',
  entityIndex: 3,
  entityCount: 15,
  rowsApplied: 120,
);

void main() {
  late _FakeNet net;
  late _FakeSetup setup;
  late List<OfflineStatusState> seen;

  setUp(() {
    net = _FakeNet();
    setup = _FakeSetup();
    seen = [];
  });

  OfflineStatusBloc make({bool killSwitch = false}) {
    final b = OfflineStatusBloc(
      networkMonitor: net,
      outboxUnsyncedCount: () async => 0,
      firstSetup: killSwitch ? null : () async => setup,
    );
    b.stream.listen(seen.add);
    return b;
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('initial state is checking and does not block', () {
    final b = make();
    expect(b.state.setupStatus, const FirstSetupStatus.checking());
    expect(b.state.setupStatus.blocksApp, isFalse);
  });

  test(
    'required -> running -> done; readiness only once bootstrapped',
    () async {
      final b = make();
      b.add(const OnOfflineStatusStarted());
      await settle();
      expect(b.state.setupStatus, const FirstSetupStatus.required());
      expect(b.state.setupStatus.blocksApp, isTrue);
      expect(b.state.hasCache, isFalse);
      expect(b.state.canUseAppOffline, isFalse);

      setup.push(_running);
      await settle();
      expect(
        b.state.setupStatus,
        const FirstSetupStatus.running(
          entity: 'product',
          index: 3,
          count: 15,
          rowsApplied: 120,
        ),
      );
      expect(b.state.setupStatus.blocksApp, isTrue);
      expect(b.state.hasCache, isFalse);

      setup.bootstrapped = true;
      setup.push(
        const BootstrapStatus(
          scope: 'u1|t1',
          outcome: BootstrapOutcome.completed,
          currentEntity: 'notification',
          entityIndex: 14,
          entityCount: 15,
        ),
      );
      await settle();
      expect(b.state.setupStatus, const FirstSetupStatus.done());
      expect(b.state.hasCache, isTrue);
      expect(b.state.canUseAppOffline, isTrue);
      expect(b.state.bootstrapStatus, OfflineBootstrapStatus.success);
      await b.close();
    },
  );

  test('offline + not bootstrapped -> blockedOffline; back online -> '
      'required', () async {
    net.online = false;
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.blockedOffline());
    expect(b.state.hasCache, isFalse);
    expect(b.state.errorMessage, isNull, reason: 'no hard-coded text');

    net.online = true;
    net.ctrl.add(true);
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.required());
    await b.close();
  });

  test('bootstrap interrupted because the server is unreachable -> '
      'blockedOffline even when the device has a network', () async {
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    setup.push(
      const BootstrapStatus(
        scope: 'u1|t1',
        outcome: BootstrapOutcome.interrupted,
        offline: true,
      ),
    );
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.blockedOffline());
    await b.close();
  });

  test('serverNotReady -> blockedServer; retry calls the controller', () async {
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    setup.push(
      const BootstrapStatus(scope: 'u1|t1', outcome: BootstrapOutcome.blocked),
    );
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.blockedServer());
    expect(b.state.bootstrapStatus, OfflineBootstrapStatus.failure);

    b.add(const OnOfflineStatusRefreshRequested());
    await settle();
    expect(setup.retries, 1);
    await b.close();
  });

  test('a manual retry the sync gate refuses (no run at all) -> '
      'blockedServer', () async {
    setup.retryResult = null;
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    b.add(const OnOfflineStatusRefreshRequested());
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.blockedServer());
    // A real run afterwards clears it.
    setup.push(_running);
    await settle();
    expect(b.state.setupStatus.phase, FirstSetupPhase.running);
    await b.close();
  });

  test('bootstrapped + cursor reset (refresh) never produces a blocking '
      'status; only a small refreshing flag', () async {
    setup.bootstrapped = true;
    net.online = false;
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    net.online = true;
    net.ctrl.add(true);
    setup.push(const BootstrapStatus(scope: 'u1|t1'));
    setup.push(_running);
    await settle();
    expect(b.state.setupRefreshing, isTrue);
    setup.push(
      const BootstrapStatus(
        scope: 'u1|t1',
        outcome: BootstrapOutcome.interrupted,
        offline: true,
      ),
    );
    setup.push(
      const BootstrapStatus(scope: 'u1|t1', outcome: BootstrapOutcome.blocked),
    );
    net.ctrl.add(false);
    await settle();
    expect(seen, isNotEmpty);
    for (final s in seen) {
      expect(s.setupStatus.blocksApp, isFalse, reason: '$s');
      expect(s.canUseAppOffline, isTrue);
    }
    expect(b.state.setupStatus, const FirstSetupStatus.done());
    expect(b.state.setupRefreshing, isFalse);
    await b.close();
  });

  test('kill switch (no controller): never blocks', () async {
    final b = make(killSwitch: true);
    b.add(const OnOfflineStatusStarted());
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.done());
    expect(b.state.canUseAppOffline, isTrue);
    await b.close();
  });

  test(
    'reset -> checking; progress before the next start is ignored',
    () async {
      final b = make();
      b.add(const OnOfflineStatusStarted());
      await settle();
      b.add(const OnOfflineStatusResetRequested());
      await settle();
      expect(b.state.setupStatus, const FirstSetupStatus.checking());
      setup.push(_running);
      await settle();
      expect(b.state.setupStatus, const FirstSetupStatus.checking());
      await b.close();
    },
  );

  test('relaunch mid-setup resumes: started while a run is in flight shows '
      'it running', () async {
    setup.cur = _running;
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    expect(b.state.setupStatus.phase, FirstSetupPhase.running);
    await b.close();
  });

  // Review M1: a run that completes while Started is reading the flag is
  // not lost (subscribe before the read, re-read after an outcome).
  test('completed emitted during the first readiness read -> done', () async {
    setup.duringRead = () {
      setup.bootstrapped = true;
      setup.push(
        const BootstrapStatus(
          scope: 'u1|t1',
          outcome: BootstrapOutcome.completed,
        ),
      );
    };
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.done());
    expect(b.state.canUseAppOffline, isTrue);
    await b.close();
  });

  // Review M2: the bootstrapper status is process-wide; a status of another
  // scope (previous session) is never shown for this one.
  test('stale status of a previous scope is ignored -> required', () async {
    setup.cur = const BootstrapStatus(
      scope: 'u0|t9',
      outcome: BootstrapOutcome.blocked,
    );
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.required());
    setup.push(
      const BootstrapStatus(
        scope: 'u0|t9',
        currentEntity: 'product',
        entityIndex: 1,
        entityCount: 15,
      ),
    );
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.required());
    await b.close();
  });

  test('re-login: new scope after reset starts from required', () async {
    final b = make();
    b.add(const OnOfflineStatusStarted());
    await settle();
    setup.push(
      const BootstrapStatus(scope: 'u1|t1', outcome: BootstrapOutcome.blocked),
    );
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.blockedServer());
    b.add(const OnOfflineStatusResetRequested());
    await settle();
    setup.scope = 'u2|t2';
    b.add(const OnOfflineStatusStarted());
    await settle();
    expect(b.state.setupStatus, const FirstSetupStatus.required());
    await b.close();
  });

  // Ruling T11-a: the gate is per tenant (shared catalog tables).
  group('tenant-level gate', () {
    test(
      'second user of the same tenant, offline, no own bootstrap -> done',
      () async {
        setup.otherUserOfTenantBootstrapped = true;
        net.online = false;
        final b = make();
        b.add(const OnOfflineStatusStarted());
        await settle();
        expect(b.state.setupStatus, const FirstSetupStatus.done());
        expect(b.state.hasCache, isTrue);
        expect(b.state.canUseAppOffline, isTrue);
        await b.close();
      },
    );

    test(
      'same tenant online: own bootstrap runs as a non-blocking refresh',
      () async {
        setup.otherUserOfTenantBootstrapped = true;
        final b = make();
        b.add(const OnOfflineStatusStarted());
        await settle();
        setup.push(_running);
        await settle();
        expect(b.state.setupStatus, const FirstSetupStatus.done());
        expect(b.state.setupRefreshing, isTrue);
        setup.bootstrapped = true;
        setup.push(
          const BootstrapStatus(
            scope: 'u1|t1',
            outcome: BootstrapOutcome.completed,
          ),
        );
        await settle();
        expect(b.state.setupRefreshing, isFalse);
        for (final s in seen) {
          expect(s.setupStatus.blocksApp, isFalse, reason: '$s');
        }
        await b.close();
      },
    );

    test('different tenant with no bootstrapped scope still blocks', () async {
      net.online = false;
      final b = make();
      b.add(const OnOfflineStatusStarted());
      await settle();
      expect(b.state.setupStatus, const FirstSetupStatus.blockedOffline());
      expect(b.state.canUseAppOffline, isFalse);
      await b.close();
    });
  });

  group('FirstSetupStatus.derive', () {
    test('bootstrapped wins over everything', () {
      for (final boot in [
        null,
        _running,
        const BootstrapStatus(
          scope: 'u1|t1',
          outcome: BootstrapOutcome.blocked,
        ),
      ]) {
        expect(
          FirstSetupStatus.derive(
            bootstrapped: true,
            offline: true,
            boot: boot,
            gateRefused: true,
          ),
          const FirstSetupStatus.done(),
        );
      }
    });

    // F7: an account/session block is its own phase (distinct message),
    // never the generic 'required' nor 'server not ready'.
    for (final reason in [
      SyncBlockReason.tokenExpired,
      SyncBlockReason.accountDisabled,
      SyncBlockReason.deviceRevoked,
      SyncBlockReason.noSession,
    ]) {
      test('blocked for ${reason.name} -> blockedAccount(${reason.name})', () {
        final s = FirstSetupStatus.derive(
          bootstrapped: false,
          offline: false,
          boot: BootstrapStatus(
            scope: 'u1|t1',
            outcome: BootstrapOutcome.blocked,
            block: reason,
          ),
        );
        expect(s, FirstSetupStatus.blockedAccount(reason));
        expect(s.phase, FirstSetupPhase.blockedAccount);
        expect(s.blockReason, reason);
        expect(s.blocksApp, isTrue);
        expect(s, isNot(const FirstSetupStatus.required()));
      });
    }

    test('offline still wins over an account block (connect first)', () {
      expect(
        FirstSetupStatus.derive(
          bootstrapped: false,
          offline: true,
          boot: const BootstrapStatus(
            scope: 'u1|t1',
            outcome: BootstrapOutcome.blocked,
            block: SyncBlockReason.tokenExpired,
          ),
        ),
        const FirstSetupStatus.blockedOffline(),
      );
    });

    test('two account blocks with different reasons differ', () {
      expect(
        FirstSetupStatus.blockedAccount(SyncBlockReason.tokenExpired),
        isNot(FirstSetupStatus.blockedAccount(SyncBlockReason.deviceRevoked)),
      );
    });
  });
}
