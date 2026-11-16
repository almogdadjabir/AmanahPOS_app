import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'outbox/outbox_store.dart';
import 'sync_device_registrar.dart';
import 'sync_session_guard.dart';
import 'sync_state_store.dart';
import 'sync_triggers.dart';

/// Who is signed in, as far as sync cares. `null` = no ready session.
@immutable
class SyncSession {
  const SyncSession({required this.userId, required this.tenantId});

  final String userId;
  final String tenantId;

  String get key => '$userId|$tenantId';

  @override
  bool operator ==(Object other) =>
      other is SyncSession &&
      other.userId == userId &&
      other.tenantId == tenantId;

  @override
  int get hashCode => Object.hash(userId, tenantId);

  @override
  String toString() => 'SyncSession($key)';
}

/// App glue for the sync core. Only created when `kSyncEngineEnabled`.
///
///  * session ready (signed in + business selected) -> [SyncTriggers.start]
///    and a best-effort device registration;
///  * session gone (logout) -> [SyncTriggers.stop]; then sync bookkeeping
///    (`SyncStateStore.clear`: cursor, capabilities, last sync) is cleared
///    ONLY when the outbox has no unsynced row. Outbox rows are never
///    deleted here. The same rule applies when the tenant changes;
///  * app lifecycle -> resume / pause for the triggers;
///  * [SyncSessionGuard] events -> [onSessionEnded] (the app's existing
///    forced-logout path, which keeps offline data and unsent sales).
class SyncCoordinator with WidgetsBindingObserver {
  SyncCoordinator({
    required SyncTriggers triggers,
    required SyncSessionGuard guard,
    required SyncDeviceRegistrar registrar,
    required OutboxStore outbox,
    required SyncStateStore state,
    required Stream<SyncSession?> sessions,
    required SyncSession? initialSession,
    required Future<void> Function(SyncSessionEvent event) onSessionEnded,
  }) : _triggers = triggers,
       _guard = guard,
       _registrar = registrar,
       _outbox = outbox,
       _state = state,
       _sessions = sessions,
       _initial = initialSession,
       _onSessionEnded = onSessionEnded;

  final SyncTriggers _triggers;
  final SyncSessionGuard _guard;
  final SyncDeviceRegistrar _registrar;
  final OutboxStore _outbox;
  final SyncStateStore _state;
  final Stream<SyncSession?> _sessions;
  final SyncSession? _initial;
  final Future<void> Function(SyncSessionEvent event) _onSessionEnded;

  StreamSubscription<SyncSession?>? _sessionSub;
  StreamSubscription<SyncSessionEvent>? _eventSub;
  SyncSession? _current;
  Future<void> _queue = Future.value();
  bool _attached = false;
  bool _observing = false;

  SyncSession? get currentSession => _current;

  /// Starts listening. [observeLifecycle] is false only in unit tests.
  Future<void> attach({bool observeLifecycle = true}) {
    if (_attached) return _queue;
    _attached = true;
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _guard.start();
    _eventSub = _guard.events.listen(_handleSessionEvent);
    _sessionSub = _sessions.listen(_enqueue);
    _enqueue(_initial);
    return _queue;
  }

  Future<void> detach() async {
    if (!_attached) return;
    _attached = false;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    await _sessionSub?.cancel();
    await _eventSub?.cancel();
    _sessionSub = null;
    _eventSub = null;
    await _guard.stop();
    await _queue;
    await _triggers.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _triggers.onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _triggers.onAppPaused();
      case AppLifecycleState.inactive:
        break; // transient (dialogs, app switcher): keep the timers
    }
  }

  // Session changes are applied strictly in order.
  void _enqueue(SyncSession? s) {
    _queue = _queue.then((_) => _apply(s)).catchError((Object e, StackTrace st) {
      _log('session change failed', e, st);
    });
  }

  Future<void> _apply(SyncSession? next) async {
    if (!_attached || next == _current) return;
    final previous = _current;
    _current = next;
    if (previous != null) {
      await _triggers.stop();
      if (next == null || next.tenantId != previous.tenantId) {
        await _clearSyncStateIfOutboxEmpty();
      }
    }
    if (next != null) {
      _triggers.start();
      unawaited(_registrar.registerIfNeeded(userKey: next.key));
    }
  }

  /// Rule: sync bookkeeping is reset on logout / tenant change only when
  /// nothing is waiting in the outbox. Unsynced rows (pending, inflight,
  /// blocked, rejected) keep their context so the same user can push them
  /// after signing in again; they are NEVER deleted here.
  Future<void> _clearSyncStateIfOutboxEmpty() async {
    try {
      if (await _outbox.unsyncedCount() == 0) await _state.clear();
    } catch (e, st) {
      _log('sync state clear skipped', e, st);
    }
  }

  Future<void> _handleSessionEvent(SyncSessionEvent e) async {
    // TODO(sync-phase-1): accountDisabled / deviceRevoked with unsynced
    // outbox rows must offer the quarantine/export flow (spec "Logout with
    // unsynced data", open question 2) before any local data is removed.
    // Until then the sign-out below keeps every outbox / sales row and never
    // calls OfflineDb.clearAllLocalOfflineData.
    try {
      await _onSessionEnded(e);
    } catch (err, st) {
      _log('session end handler failed for ${e.name}', err, st);
    }
  }

  void _log(String msg, Object e, StackTrace st) {
    developer.log(msg, name: 'SyncCoordinator', error: e, stackTrace: st);
  }
}
