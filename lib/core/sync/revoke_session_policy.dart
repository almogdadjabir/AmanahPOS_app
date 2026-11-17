import 'dart:developer' as developer;

import 'outbox/outbox_store.dart';
import 'sync_session_guard.dart';
import 'sync_state_store.dart';

/// What happens when the sync engine reports a session-ending condition.
///
/// `needsLogin`: sign out only. `accountDisabled` / `deviceRevoked`: when NO
/// scope on the device has an unsynced outbox row (rejected counts as
/// unsynced) the local data is wiped (the wipe covers every scope, so the
/// check must too); otherwise it is kept and a [RevokeMarker] tells the login
/// screen. [logout] always runs.
class RevokeSessionPolicy {
  RevokeSessionPolicy({
    required OutboxStore outbox,
    required SyncStateStore state,
    required Future<void> Function() wipe,
    required Future<void> Function() logout,
    DateTime Function()? now,
  }) : _outbox = outbox,
       _state = state,
       _wipe = wipe,
       _logout = logout,
       _now = now ?? DateTime.now;

  final OutboxStore _outbox;
  final SyncStateStore _state;
  final Future<void> Function() _wipe;
  final Future<void> Function() _logout;
  final DateTime Function() _now;

  Future<void> handle(SyncSessionEvent e) async {
    try {
      if (e != SyncSessionEvent.needsLogin) await _applyDataPolicy(e);
    } catch (err, st) {
      developer.log(
        'revoke data policy failed for ${e.name}',
        name: 'RevokeSessionPolicy',
        error: err,
        stackTrace: st,
      );
    } finally {
      await _logout();
    }
  }

  Future<void> _applyDataPolicy(SyncSessionEvent e) async {
    final pending = await _outbox.unsyncedCount();
    if (pending == 0) {
      // Nothing left to protect: a marker from an earlier revoke is stale.
      await _state.setRevokeMarker(null);
      await _wipe();
      return;
    }
    await _state.setRevokeMarker(
      RevokeMarker(reason: e.name, pendingCount: pending, at: _now()),
    );
  }
}
