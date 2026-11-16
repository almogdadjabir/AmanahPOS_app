import 'dart:async';

import 'sync_engine.dart';
import 'sync_scope.dart';

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
  /// [hasSession] tells whether someone is signed in. While it says no,
  /// engine events are dropped: a run that was still winding down at logout
  /// must not trigger a forced logout of nobody. Null = always signed in.
  SyncSessionGuard(this._status, {bool Function()? hasSession})
    : _hasSession = hasSession;

  final Stream<SyncStatus> _status;
  final bool Function()? _hasSession;
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
      case SyncBlockReason.noSession: // no one signed in: nothing to end
      case SyncBlockReason.none:
        return null;
    }
  }

  void start() {
    _sub ??= _status.listen(_onStatus);
  }

  void _onStatus(SyncStatus s) {
    if (_hasSession != null && !_hasSession()) return;
    // A run of the previous session (its scope differs from the live one)
    // must not end the new user's session.
    final runScope = s.scope;
    if (runScope != null && runScope != SyncScope.current) return;
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
