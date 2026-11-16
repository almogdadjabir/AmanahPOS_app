import 'dart:async';
import 'dart:developer' as developer;

import '../sync_engine.dart';
import '../transport/sync_auth_interceptor.dart';

/// What one background run achieved.
enum BackgroundSyncResult {
  /// Nobody is signed in on this device: nothing was built or sent.
  noSession,

  /// The server does not advertise the sync capabilities: legacy path,
  /// nothing to do in the background.
  skipped,

  /// The run completed (backlog drained, pull up to date or needs the
  /// foreground bootstrap).
  success,

  /// The time budget ran out: the run stopped between batches/pages (or was
  /// abandoned mid-call); the rest goes in a later run.
  partial,

  /// Another runner (the foreground app) holds the `sync_lock` lease.
  alreadyRunning,

  /// Backoff / blocked / unexpected failure: try again later.
  retryLater,
}

class BackgroundSyncReport {
  const BackgroundSyncReport(this.result, {this.outcome, this.error});

  final BackgroundSyncResult result;

  /// The engine's outcome; null when the engine did not run or was
  /// abandoned past the hard stop.
  final SyncOutcome? outcome;
  final Object? error;

  /// Whether the platform scheduler should re-run this work soon (Android
  /// WorkManager `Result.retry()` with its backoff).
  bool get shouldRetry =>
      result == BackgroundSyncResult.retryLater ||
      result == BackgroundSyncResult.partial;

  @override
  String toString() =>
      'BackgroundSyncReport(${result.name}, outcome=${outcome?.name}'
      '${error == null ? '' : ', error=$error'})';
}

/// The logic of one background sync run, free of any platform glue so it
/// is unit-tested; `background_entry.dart` only builds the dependencies.
///
/// Safety relies on the engine's own invariants: the `sync_lock` DB lease
/// keeps this run and a foreground run from ever pushing concurrently, the
/// scope is checked before every batch/page, and a run that is killed by the
/// OS mid-push is recovered by the claim lease expiry (results are matched
/// by `mutation_id`, so a replay is answered `duplicate`).
class BackgroundSyncRunner {
  BackgroundSyncRunner._();

  /// iOS gives an app-refresh task ~30 s; stop well before.
  static const Duration defaultBudget = Duration(seconds: 25);

  /// Extra time after [defaultBudget] for the call in flight to return
  /// before the run is abandoned (the OS may then kill the process; the
  /// claim lease recovers whatever was in flight).
  static const Duration defaultHardStopGrace = Duration(seconds: 3);

  /// Runs at most one engine sync for the signed-in session.
  ///
  /// * [readSessionKey]: `userId|tenantId` of the session stored on the
  ///   device, or null when nobody is signed in (see [storageSessionKey]).
  /// * [engineFactory]: builds the engine for that scope (same engine and
  ///   appliers as the foreground app).
  /// * [canSync]: optional gate (server capabilities); false = [skipped].
  /// * [budget]: after it, `engine.cancel()` stops the run between
  ///   batches/pages; after [budget] + [hardStopGrace] the run is abandoned.
  ///
  /// Never throws.
  static Future<BackgroundSyncReport> runOnce({
    required Future<String?> Function() readSessionKey,
    required Future<SyncEngine> Function(String scope) engineFactory,
    Future<bool> Function()? canSync,
    Duration budget = defaultBudget,
    Duration hardStopGrace = defaultHardStopGrace,
  }) async {
    String? scope;
    try {
      scope = await readSessionKey();
    } catch (e, st) {
      _log('reading the session failed', e, st);
      return BackgroundSyncReport(BackgroundSyncResult.retryLater, error: e);
    }
    if (scope == null || scope.isEmpty) {
      return const BackgroundSyncReport(BackgroundSyncResult.noSession);
    }

    if (canSync != null) {
      try {
        if (!await canSync()) {
          return const BackgroundSyncReport(BackgroundSyncResult.skipped);
        }
      } catch (e, st) {
        _log('sync gate failed', e, st);
        return BackgroundSyncReport(BackgroundSyncResult.retryLater, error: e);
      }
    }

    SyncEngine engine;
    try {
      engine = await engineFactory(scope);
    } catch (e, st) {
      _log('building the engine failed', e, st);
      return BackgroundSyncReport(BackgroundSyncResult.retryLater, error: e);
    }

    final budgetTimer = Timer(budget, engine.cancel);
    final hardStop = Completer<void>();
    final hardStopTimer = Timer(budget + hardStopGrace, () {
      if (!hardStop.isCompleted) hardStop.complete();
    });
    var abandoned = false;
    try {
      final run = engine.syncNow(reason: SyncReason.background);
      final first = await Future.any<Object?>([
        run.then<Object?>((o) => o, onError: (Object e) => e),
        hardStop.future.then<Object?>((_) => _hardStop),
      ]);
      if (identical(first, _hardStop)) {
        // The in-flight call outlived the budget. Leave the engine running
        // (it writes results only under its lease) and report back now.
        abandoned = true;
        unawaited(
          run.then<void>((_) => engine.dispose(), onError: (Object _) {}),
        );
        return const BackgroundSyncReport(BackgroundSyncResult.partial);
      }
      if (first is! SyncOutcome) {
        _log('sync failed', first);
        return BackgroundSyncReport(
          BackgroundSyncResult.retryLater,
          error: first,
        );
      }
      return BackgroundSyncReport(
        _map(first, moreToPull: engine.current.moreToPull),
        outcome: first,
      );
    } finally {
      budgetTimer.cancel();
      hardStopTimer.cancel();
      if (!abandoned) {
        try {
          await engine.dispose();
        } catch (_) {}
      }
    }
  }

  static const Object _hardStop = Object();

  static BackgroundSyncResult _map(
    SyncOutcome outcome, {
    required bool moreToPull,
  }) {
    switch (outcome) {
      case SyncOutcome.completed:
        return moreToPull
            ? BackgroundSyncResult.partial
            : BackgroundSyncResult.success;
      case SyncOutcome.needsBootstrap:
        // The push half ran; the bootstrap is a foreground job.
        return BackgroundSyncResult.success;
      case SyncOutcome.cancelled:
        return BackgroundSyncResult.partial;
      case SyncOutcome.alreadyRunning:
        return BackgroundSyncResult.alreadyRunning;
      case SyncOutcome.backoff:
      case SyncOutcome.blocked:
        return BackgroundSyncResult.retryLater;
    }
  }

  /// `userId|tenantId` of the session stored on the device: the bearer's
  /// `user_id` claim (decoded locally, like [SyncAuthInterceptor]) plus the
  /// stored `X-Tenant-ID`. Null when either is missing or undecodable. This
  /// is the same key the foreground derives from `AuthBloc` (profile id |
  /// default business id), which the interceptor already requires to match
  /// the token claim and tenant header.
  static String? storageSessionKey(String? accessToken, String? tenantId) {
    if (accessToken == null || accessToken.isEmpty) return null;
    if (tenantId == null || tenantId.isEmpty) return null;
    final userId = SyncAuthInterceptor.jwtUserId(accessToken);
    if (userId == null || userId.isEmpty) return null;
    return '$userId|$tenantId';
  }

  static void _log(String msg, [Object? e, StackTrace? st]) {
    developer.log(msg, name: 'BackgroundSync', error: e, stackTrace: st);
  }
}
