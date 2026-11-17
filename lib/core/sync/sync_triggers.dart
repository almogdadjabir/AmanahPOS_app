import 'dart:async';
import 'dart:developer' as developer;

import '../network/network_monitor.dart';
import 'assets/asset_sync.dart';
import 'bootstrap/bootstrapper.dart';
import 'db_change_notifier.dart';
import 'outbox/outbox_store.dart';
import 'sync_engine.dart';
import 'sync_schema.dart';
import 'sync_scope.dart';

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
/// First setup (spec 2026-11-16 phase 2, section 2): when the engine answers
/// `needsBootstrap` and a [Bootstrapper] is given, the same run (still the
/// one in-flight run, so engine and bootstrapper never overlap; both also
/// hold `sync_lock`) runs it while the app is in the foreground and then
/// runs the engine ONCE more (`completed` / `notNeeded`). Outcomes:
///  * `interrupted` (offline, server error, cancel): any later trigger
///    retries it (connectivity regained and resume included);
///  * `blocked` (server not ready, refresh rejected, account disabled, ...):
///    held; only a manual [syncNow] (or a new session, [start]) retries it.
///    Exception: "server not ready" is also retried by app resume (T7 M1).
///    The engine itself still runs (pushes) on every trigger;
///  * `alreadyRunning`: handled like the engine's (one retry after the TTL).
///
/// [canSync] gates every run (session present, server capabilities); when
/// it says no, nothing is scheduled.
///
/// Images (spec phase 2, section 4): [assetSync] (`AssetSync.run()`) is
/// started after a run that ends `completed`, once after a bootstrap
/// `completed`, and on app resume, only while [assetsReachable] says the
/// server answers. Fire-and-forget: never awaited by the run, never changes
/// its outcome, every failure is swallowed and logged. AssetSync is
/// single-flight itself, so overlapping starts collapse.
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
    this.onBackgroundWork,
    this.resumeRefreshTables = const {},
    Bootstrapper? bootstrapper,
    Future<AssetSync?> Function()? assetSync,
    Future<bool> Function()? assetsReachable,
  }) : _canSync = canSync,
       _now = now ?? DateTime.now,
       _bootstrapper = bootstrapper,
       _assetSync = assetSync,
       _assetsReachable = assetsReachable;

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
  final Bootstrapper? _bootstrapper;
  final Future<AssetSync?> Function()? _assetSync;
  final Future<bool> Function()? _assetsReachable;

  /// The last bootstrap ended `blocked`: only manual runs retry it (and app
  /// resume when the block is "server not ready", see [onAppResumed]).
  bool _bootstrapBlocked = false;

  /// The held block is the server's missing `bootstrap_paged` capability:
  /// a server deploy can fix it while the app is away, so app resume
  /// clears this hold (ledger T7 M1). Token / account blocks stay held.
  bool _bootstrapBlockedServerNotReady = false;

  /// Optional: asks the OS background worker for a sync soon. Called at most
  /// once per background period, when the app is paused (or written to
  /// while paused) with `pending` outbox rows: Dart timers do not run once
  /// the OS suspends the app.
  final void Function()? onBackgroundWork;

  /// Notified on resume: a background run (another isolate, another
  /// notifier) may have changed them while the app was away.
  final Set<String> resumeRefreshTables;
  bool _backgroundRequested = false;

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
  Completer<void>? _runDone;
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
    _bootstrapBlocked = false;
    _bootstrapBlockedServerNotReady = false;
    _netSub = _network.onStatusChanged.listen(_onConnectivity);
    _dbSub = _notifier.changes.listen(_onTablesChanged);
    _startPeriodic();
    _kick(SyncReason.resume);
  }

  Future<void> stop() async {
    if (!_started) {
      // A concurrent second stop(): the first one is already winding the run
      // down; this caller must also not return before it is finished.
      final pending = _runDone;
      if (pending != null && !pending.isCompleted) await pending.future;
      return;
    }
    _started = false;
    _generation++;
    _cancelTimers();
    _followUpRequested = false;
    _backoffUntil = null;
    // Ask the run in flight (engine or bootstrap) to stop right away, before
    // any await, so it winds down while the listeners are detached.
    final running = _runDone;
    if (running != null && !running.isCompleted) {
      _engine.cancel();
      _bootstrapper?.cancel();
    }
    final net = _netSub;
    final db = _dbSub;
    _netSub = null;
    _dbSub = null;
    await net?.cancel();
    await db?.cancel();
    // Cooperative: the engine stops between batches/pages, so this returns
    // within about one network call. Callers may clear sync state afterwards
    // knowing no stale cursor/result write can still land.
    final done = _runDone;
    if (done != null && !done.isCompleted) {
      _engine.cancel();
      _bootstrapper?.cancel();
      await done.future;
    }
  }

  void onAppResumed() {
    if (!_started) return;
    _foreground = true;
    _backgroundRequested = false;
    if (_bootstrapBlocked && _bootstrapBlockedServerNotReady) {
      _bootstrapBlocked = false;
      _bootstrapBlockedServerNotReady = false;
    }
    if (resumeRefreshTables.isNotEmpty) _notifier.notify(resumeRefreshTables);
    _startPeriodic();
    _kick(SyncReason.resume);
    _kickAssets('resume');
  }

  void onAppPaused() {
    _foreground = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _requestBackgroundWork();
  }

  void _requestBackgroundWork() {
    final hook = onBackgroundWork;
    if (hook == null || !_started || _foreground || _backgroundRequested) {
      return;
    }
    final gen = _generation;
    unawaited(() async {
      int pending;
      try {
        pending = await _outbox.pendingCount(scope: SyncScope.current);
      } catch (e, st) {
        _log('pendingCount failed', e, st);
        return;
      }
      if (gen != _generation || _foreground || _backgroundRequested) return;
      if (pending == 0) return;
      _backgroundRequested = true;
      try {
        hook();
      } catch (e, st) {
        _log('onBackgroundWork failed', e, st);
      }
    }());
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
    final maintenance = _engine.current.block == SyncBlockReason.maintenance;
    _kick(SyncReason.connectivity, bypassBackoff: !maintenance);
  }

  void _onTablesChanged(Set<String> tables) {
    if (!tables.contains(SyncTables.outbox)) return;
    if (!_foreground) _requestBackgroundWork();
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
      pending = await _outbox.pendingCount(scope: SyncScope.current);
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
    _periodicTimer = Timer.periodic(
      periodic,
      (_) => _kick(SyncReason.periodic),
    );
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
    final done = _runDone = Completer<void>();
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
        if (outcome == SyncOutcome.needsBootstrap) {
          outcome = await _bootstrapThenSync(reason, gen);
        }
      } catch (e, st) {
        _log('syncNow threw', e, st);
        outcome = null;
      }
    } finally {
      _inFlight = false;
      if (identical(_runDone, done)) _runDone = null;
      done.complete();
    }
    if (gen != _generation || !_started) return outcome;
    _afterRun(outcome);
    return outcome;
  }

  /// Runs the bootstrapper (foreground only, not while held `blocked`
  /// unless manual), then the engine once more. Returns the run's outcome.
  Future<SyncOutcome> _bootstrapThenSync(SyncReason reason, int gen) async {
    final boot = _bootstrapper;
    if (boot == null || !_started || gen != _generation || !_foreground) {
      return SyncOutcome.needsBootstrap;
    }
    if (_bootstrapBlocked && reason != SyncReason.manual) {
      return SyncOutcome.needsBootstrap;
    }
    _bootstrapBlocked = false;
    _bootstrapBlockedServerNotReady = false;
    final r = await boot.run();
    switch (r) {
      case BootstrapOutcome.completed:
        if (!_started || gen != _generation) return SyncOutcome.cancelled;
        _kickAssets('bootstrap completed');
        return _engine.syncNow(reason: reason);
      case BootstrapOutcome.notNeeded:
        if (!_started || gen != _generation) return SyncOutcome.cancelled;
        return _engine.syncNow(reason: reason);
      case BootstrapOutcome.blocked:
        _bootstrapBlocked = true;
        _bootstrapBlockedServerNotReady = boot.current.serverNotReady;
        return SyncOutcome.needsBootstrap;
      case BootstrapOutcome.interrupted:
        return SyncOutcome.needsBootstrap;
      case BootstrapOutcome.alreadyRunning:
        return SyncOutcome.alreadyRunning;
    }
  }

  void _afterRun(SyncOutcome? outcome) {
    final followUp = _followUpRequested;
    final followUpReason = followUp ? _followUpReason : SyncReason.afterWrite;
    _followUpRequested = false;
    switch (outcome) {
      case SyncOutcome.completed:
        _kickAssets('sync completed');
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
      case SyncOutcome.cancelled:
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

  /// Starts an image run without waiting for it. Never throws.
  void _kickAssets(String why) {
    final provider = _assetSync;
    if (provider == null || !_started) return;
    final gen = _generation;
    unawaited(() async {
      try {
        final gate = _assetsReachable;
        if (gate != null && !await gate()) return;
        if (!_started || gen != _generation) return;
        final assets = await provider();
        if (assets == null) return;
        await assets.run();
      } catch (e, st) {
        _log('asset sync ($why) failed', e, st);
      }
    }());
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
