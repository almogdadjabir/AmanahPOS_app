import 'dart:async';

import 'sync_engine.dart';

/// Session-ending conditions reported by the sync engine.
enum SyncSessionEvent {
  /// The refresh token was explicitly rejected (`SyncStatus.needsLogin`).
  needsLogin,

  /// The server says this account is disabled (`account_disabled`).
  accountDisabled,

  /// This device was revoked by the owner (`device_revoked`).
  deviceRevoked,
}

/// Maps the engine's [SyncStatus] stream to [SyncSessionEvent]s.
///
/// Emits once when the engine ENTERS a session-ending block; repeats of the
/// same block are swallowed until the engine leaves the blocked state (or
/// the reason changes), so one bad session can never cause a logout loop.
///
/// The guard only reports. What happens next is the app's decision (see
/// `SyncCoordinator`): it signs the user out through the existing forced
/// logout path and NEVER deletes outbox / sales rows.
class SyncSessionGuard {
  SyncSessionGuard(this._status);

  final Stream<SyncStatus> _status;
  final _events = StreamController<SyncSessionEvent>.broadcast();
  StreamSubscription<SyncStatus>? _sub;
  SyncSessionEvent? _last;

  Stream<SyncSessionEvent> get events => _events.stream;

  /// Pure mapping, exposed for tests and UI.
  static SyncSessionEvent? map(SyncStatus s) {
    if (s.needsLogin) return SyncSessionEvent.needsLogin;
    if (s.phase != SyncPhase.blocked) return null;
    switch (s.block) {
      case SyncBlockReason.accountDisabled:
        return SyncSessionEvent.accountDisabled;
      case SyncBlockReason.deviceRevoked:
        return SyncSessionEvent.deviceRevoked;
      case SyncBlockReason.tokenExpired: // covered by needsLogin above
      case SyncBlockReason.appTooOld: // update prompt, not a logout
      case SyncBlockReason.maintenance:
      case SyncBlockReason.none:
        return null;
    }
  }

  void start() {
    _sub ??= _status.listen(_onStatus);
  }

  void _onStatus(SyncStatus s) {
    final e = map(s);
    if (e == null) {
      // Only an engine that left the blocked state re-arms the guard; an
      // unrelated status emission (counts, idle) while still blocked does
      // not.
      if (s.phase != SyncPhase.blocked) _last = null;
      return;
    }
    if (e == _last) return;
    _last = e;
    if (!_events.isClosed) _events.add(e);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _last = null;
  }

  Future<void> dispose() async {
    await stop();
    if (!_events.isClosed) await _events.close();
  }
}
