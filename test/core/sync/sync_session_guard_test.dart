import 'dart:async';

import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:flutter_test/flutter_test.dart';

SyncStatus _blocked(SyncBlockReason r) =>
    SyncStatus(phase: SyncPhase.blocked, block: r);

void main() {
  group('map', () {
    test('explicit refresh rejection -> needsLogin', () {
      expect(
        SyncSessionGuard.map(_blocked(SyncBlockReason.tokenExpired)),
        SyncSessionEvent.needsLogin,
      );
    });

    test('account disabled / device revoked', () {
      expect(
        SyncSessionGuard.map(_blocked(SyncBlockReason.accountDisabled)),
        SyncSessionEvent.accountDisabled,
      );
      expect(
        SyncSessionGuard.map(_blocked(SyncBlockReason.deviceRevoked)),
        SyncSessionEvent.deviceRevoked,
      );
    });

    test('non-session blocks and transient states map to nothing', () {
      for (final s in [
        const SyncStatus(),
        _blocked(SyncBlockReason.appTooOld),
        _blocked(SyncBlockReason.maintenance),
        const SyncStatus(
          phase: SyncPhase.backoff,
          block: SyncBlockReason.maintenance,
        ),
        // A token problem during backoff (refresh transient) never logs out.
        const SyncStatus(phase: SyncPhase.backoff, lastError: 'token_expired'),
        const SyncStatus(phase: SyncPhase.pushing),
      ]) {
        expect(SyncSessionGuard.map(s), isNull, reason: '$s');
      }
    });
  });

  test('emits once per entry into a block; re-arms after leaving it',
      () async {
    final ctrl = StreamController<SyncStatus>.broadcast(sync: true);
    final guard = SyncSessionGuard(ctrl.stream)..start();
    final got = <SyncSessionEvent>[];
    guard.events.listen(got.add);

    ctrl.add(_blocked(SyncBlockReason.tokenExpired));
    ctrl.add(_blocked(SyncBlockReason.tokenExpired)); // count refresh
    ctrl.add(_blocked(SyncBlockReason.tokenExpired));
    await Future<void>.delayed(Duration.zero);
    expect(got, [SyncSessionEvent.needsLogin]);

    ctrl.add(const SyncStatus(phase: SyncPhase.pinging)); // next run
    ctrl.add(_blocked(SyncBlockReason.deviceRevoked));
    ctrl.add(const SyncStatus(phase: SyncPhase.pinging));
    ctrl.add(_blocked(SyncBlockReason.tokenExpired));
    await Future<void>.delayed(Duration.zero);
    expect(got, [
      SyncSessionEvent.needsLogin,
      SyncSessionEvent.deviceRevoked,
      SyncSessionEvent.needsLogin,
    ]);

    await guard.stop();
    ctrl.add(const SyncStatus(phase: SyncPhase.pinging));
    ctrl.add(_blocked(SyncBlockReason.accountDisabled));
    await Future<void>.delayed(Duration.zero);
    expect(got.length, 3, reason: 'nothing after stop()');
    await guard.dispose();
    await ctrl.close();
  });
}
