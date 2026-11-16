import 'dart:async';
import 'dart:developer' as developer;

import '../network/network_monitor.dart';
import 'db_change_notifier.dart';
import 'outbox/outbox_store.dart';
import 'sync_engine.dart';
import 'sync_schema.dart';

/// Decides WHEN the [SyncEngine] runs. The engine decides what a run does.
///
/// Triggers (only between [start] and [stop]):
///  * [start] itself (one kick, e.g. right after login),
///  * app resume ([onAppResumed]),
///  * connectivity regained (`NetworkMonitor.onStatusChanged` false -> true),
///  * outbox change: the first `outbox` notification arms a timer of
///    [afterWriteDebounce]; later notifications inside that window join it
///    (bounded latency, no starvation under continuous writes). When it
///    fires, the sync only runs if rows are actually `pending` (so the
///    engine's own result writes never cause a sync loop),
///  * periodic every [periodic] while in the foreground ([onAppPaused] stops
///    it, [onAppResumed] restarts it),
///  * manual [syncNow].
///
/// Coalescing / pacing:
///  * at most one engine call in flight from here; triggers arriving during
///    it collapse into ONE follow-up run after a `completed` outcome;
///  * `alreadyRunning` with no own run in flight (another runner holds the
///    DB lease) schedules exactly ONE retry after [alreadyRunningRetry]
///    (the lock TTL), never a tight loop;
///  * `backoff` defers every automatic trigger until the engine's
///    `nextRetryAt` (one timer). Manual always runs; connectivity regained
///    may cut a network backoff short but never a maintenance window;
///  * `blocked` / `needsBootstrap` schedule nothing.
///
/// [canSync] gates every run (session present, server capabilities); when
/// it says no, nothing is scheduled.
class SyncTriggers {
  SyncTriggers(
    this._engine,
    this._network,
    this._outbox,
    this._notifier, {
    this.afterWriteDebounce = const Duration(seconds: 5),
    this.periodic = const Duration(minutes: 5),
    this.alreadyRunningRetry = const Duration(minutes: 2),
    this.backoffFallback = const Duration(minutes: 2),
    this.maxBackoffWait = const Duration(hours: 1),
    Future<bool> Function()? canSync,
    DateTime Function()? now,
  }) : _canSync = canSync,
       _now = now ?? DateTime.now;

  final SyncEngine _engine;
  final NetworkMonitor _network;
  final OutboxStore _outbox;
  final DbChangeNotifier _notifier;
  final Duration afterWriteDebounce;
  final Duration periodic;

  /// Wait before retrying when another runner holds the lock (lock TTL).
  final Duration alreadyRunningRetry;

  /// Used when the engine reports `backoff` without a `nextRetryAt`.
  final Duration backoffFallback;

  /// Upper bound for a backoff wait (guards against a wrong clock).
  final Duration maxBackoffWait;
  final Future<bool> Function()? _canSync;
  final DateTime Function() _now;

  bool _started = false;
  bool _foreground = true;
  int _generation = 0;

  StreamSubscription<bool>? _netSub;
  StreamSubscription<Set<String>>? _dbSub;
  Timer? _periodicTimer;
  Timer? _writeTimer;
  Timer? _retryTimer;
  Timer? _backoffTimer;
  Timer? _followUpTimer;

  bool? _lastOnline;
  bool _inFlight = false;
  bool _followUpRequested = false;
  SyncReason _followUpReason = SyncReason.afterWrite;
  DateTime? _backoffUntil;

  bool get isStarted => _started;

  void start() {
    if (_started) return;
    _started = true;
    _generation++;
    _foreground = true;
    _lastOnline = null;
    _netSub = _network.onStatusChanged.listen(_onConnectivity);
    _dbSub = _notifier.changes.listen(_onTablesChanged);
    _startPeriodic();
    _kick(SyncReason.resume);
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _generation++;
    _cancelTimers();
    _followUpRequested = false;
    _backoffUntil = null;
    final net = _netSub;
    final db = _dbSub;
    _netSub = null;
    _dbSub = null;
    await net?.cancel();
    await db?.cancel();
  }

  void onAppResumed() {
    if (!_started) return;
    _foreground = true;
    _startPeriodic();
    _kick(SyncReason.resume);
  }

  void onAppPaused() {
    _foreground = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Manual sync. Returns null when not started or gated off.
  Future<SyncOutcome?> syncNow({SyncReason reason = SyncReason.manual}) {
    if (!_started) return Future.value(null);
    return _fire(reason, bypassBackoff: true);
  }

  // ------------------------------------------------------------ sources

  void _onConnectivity(bool online) {
    final was = _lastOnline;
    _lastOnline = online;
    if (!online || was == true) return;
    final maintenance =
        _engine.current.block == SyncBlockReason.maintenance;
    _kick(SyncReason.connectivity, bypassBackoff: !maintenance);
  }

  void _onTablesChanged(Set<String> tables) {
    if (!tables.contains(SyncTables.outbox)) return;
    if (_writeTimer != null) return; // join the open window
    _writeTimer = Timer(afterWriteDebounce, () {
      _writeTimer = null;
      unawaited(_afterWrite());
    });
  }

  Future<void> _afterWrite() async {
    if (!_started) return;
    final gen = _generation;
    int pending;
    try {
      pending = await _outbox.pendingCount();
    } catch (e, st) {
      _log('pendingCount failed', e, st);
      return;
    }
    if (gen != _generation || pending == 0) return;
    _kick(SyncReason.afterWrite);
  }

  void _startPeriodic() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    if (!_started || !_foreground) return;
    _periodicTimer = Timer.periodic(periodic, (_) => _kick(SyncReason.periodic));
  }

  // ------------------------------------------------------------ running

  void _kick(SyncReason reason, {bool bypassBackoff = false}) {
    unawaited(_fire(reason, bypassBackoff: bypassBackoff));
  }

  bool _inBackoff() {
    final until = _backoffUntil;
    return until != null && _now().isBefore(until);
  }

  Future<SyncOutcome?> _fire(
    SyncReason reason, {
    bool bypassBackoff = false,
  }) async {
    if (!_started) return null;
    if (!bypassBackoff && _inBackoff()) return null; // backoff timer pending
    if (_inFlight) {
      if (!_followUpRequested) _followUpReason = reason;
      _followUpRequested = true;
      return SyncOutcome.alreadyRunning;
    }
    _inFlight = true;
    final gen = _generation;
    SyncOutcome? outcome;
    try {
      final gate = _canSync;
      if (gate != null) {
        bool ok;
        try {
          ok = await gate();
        } catch (e, st) {
          _log('sync gate failed', e, st);
          ok = false;
        }
        if (!ok || gen != _generation) return null;
      }
      try {
        outcome = await _engine.syncNow(reason: reason);
      } catch (e, st) {
        _log('syncNow threw', e, st);
        outcome = null;
      }
    } finally {
      _inFlight = false;
    }
    if (gen != _generation || !_started) return outcome;
    _afterRun(outcome);
    return outcome;
  }

  void _afterRun(SyncOutcome? outcome) {
    final followUp = _followUpRequested;
    final followUpReason = followUp ? _followUpReason : SyncReason.afterWrite;
    _followUpRequested = false;
    switch (outcome) {
      case SyncOutcome.completed:
        _backoffUntil = null;
        _backoffTimer?.cancel();
        _backoffTimer = null;
        _retryTimer?.cancel();
        _retryTimer = null;
        if (followUp || _engine.current.moreToPull) {
          _followUpTimer?.cancel();
          _followUpTimer = Timer(Duration.zero, () {
            _followUpTimer = null;
            _kick(followUpReason);
          });
        }
      case SyncOutcome.alreadyRunning:
        // Another runner (e.g. a background worker) holds the lease. One
        // retry after the lock TTL; never a tight loop.
        _retryTimer ??= Timer(alreadyRunningRetry, () {
          _retryTimer = null;
          _kick(SyncReason.periodic);
        });
      case SyncOutcome.backoff:
        _scheduleBackoff();
      case SyncOutcome.blocked:
      case SyncOutcome.needsBootstrap:
      case null:
        _retryTimer?.cancel();
        _retryTimer = null;
    }
  }

  void _scheduleBackoff() {
    final now = _now();
    var wait = backoffFallback;
    final next = _engine.current.nextRetryAt;
    if (next != null) wait = next.difference(now);
    if (wait < Duration.zero) wait = Duration.zero;
    if (wait > maxBackoffWait) wait = maxBackoffWait;
    _backoffUntil = now.add(wait);
    _backoffTimer?.cancel();
    _backoffTimer = Timer(wait, () {
      _backoffTimer = null;
      _backoffUntil = null;
      _kick(SyncReason.periodic);
    });
  }

  void _cancelTimers() {
    for (final t in [
      _periodicTimer,
      _writeTimer,
      _retryTimer,
      _backoffTimer,
      _followUpTimer,
    ]) {
      t?.cancel();
    }
    _periodicTimer = null;
    _writeTimer = null;
    _retryTimer = null;
    _backoffTimer = null;
    _followUpTimer = null;
  }

  void _log(String msg, Object e, StackTrace st) {
    developer.log(msg, name: 'SyncTriggers', error: e, stackTrace: st);
  }
}
