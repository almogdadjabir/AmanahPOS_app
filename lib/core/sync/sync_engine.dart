import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../offline/offline_db.dart';
import 'change_applier.dart';
import 'contract/sync_contract.dart';
import 'db_change_notifier.dart';
import 'outbox/outbox_entry.dart';
import 'outbox/outbox_store.dart';
import 'reachability.dart';
import 'sync_schema.dart';
import 'sync_state_store.dart';
import 'transport/sync_transport.dart';

enum SyncPhase { idle, pinging, pushing, pulling, backoff, blocked }

enum SyncBlockReason {
  none,
  appTooOld,
  tokenExpired,
  accountDisabled,
  deviceRevoked,
  maintenance,

  /// No signed-in scope (`userId|tenantId`): nothing may be pushed.
  noSession,
}

enum SyncOutcome {
  completed,
  alreadyRunning,
  needsBootstrap,
  blocked,
  backoff,

  /// [SyncEngine.cancel] stopped the run between batches/pages.
  cancelled,
}

enum SyncReason {
  resume,
  connectivity,
  afterWrite,
  periodic,
  manual,
  background,
}

enum RefreshOutcome { refreshed, rejected, transient }

/// Thrown by test hooks to simulate the process dying at that point. The
/// engine rethrows it WITHOUT any cleanup (no lease release, no lock
/// release), exactly like a killed process.
class CrashSimulation implements Exception {
  CrashSimulation([this.where = '']);
  final String where;

  @override
  String toString() => 'CrashSimulation($where)';
}

/// Test seams for crash injection.
class SyncHooks {
  const SyncHooks({
    this.beforeResultWrite,
    this.afterPushApplied,
    this.beforePullPageCommit,
  });

  /// After a push response arrived, before its results are written.
  final Future<void> Function(List<OutboxEntry> batch, PushResponse response)?
  beforeResultWrite;

  /// After a batch's results transaction committed.
  final Future<void> Function(List<OutboxEntry> batch)? afterPushApplied;

  /// Inside the page transaction, after changes were applied and before the
  /// cursor is written / the transaction commits.
  final Future<void> Function(PullResponse page)? beforePullPageCommit;
}

/// Exponential backoff: [base] x [factor]^(attempt-1), capped at [max], with
/// +-[jitter] randomisation. The result never exceeds [max].
class Backoff {
  Backoff({
    this.base = const Duration(seconds: 2),
    this.factor = 2,
    this.max = const Duration(minutes: 5),
    this.jitter = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  final Duration base;
  final double factor;
  final Duration max;
  final double jitter;
  final Random _random;

  Duration delay(int attempt) {
    final a = attempt < 1 ? 1 : attempt;
    final cap = max.inMilliseconds.toDouble();
    var ms = base.inMilliseconds.toDouble();
    for (var i = 1; i < a && ms < cap; i++) {
      ms *= factor;
    }
    if (ms > cap) ms = cap;
    final j = 1 + (_random.nextDouble() * 2 - 1) * jitter;
    var out = (ms * j).round();
    if (out > cap) out = cap.round();
    if (out < 0) out = 0;
    return Duration(milliseconds: out);
  }
}

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.block = SyncBlockReason.none,
    this.pending = 0,
    this.rejected = 0,
    this.lastSyncedAt,
    this.serverReachable = false,
    this.lastError,
    this.nextRetryAt,
    this.moreToPull = false,
    this.scope,
  });

  final SyncPhase phase;
  final SyncBlockReason block;

  /// Outbox rows not yet confirmed (pending + inflight + blocked).
  final int pending;

  /// Outbox rows parked as rejected (need user action).
  final int rejected;
  final DateTime? lastSyncedAt;
  final bool serverReachable;
  final String? lastError;

  /// When the engine-level backoff ends (set in the backoff phase).
  final DateTime? nextRetryAt;

  /// The last run stopped at the per-run page cap with more changes left on
  /// the server; another run should follow.
  final bool moreToPull;

  /// Scope (`userId|tenantId`) of the run that produced this status; null
  /// before any run. Lets consumers drop events of a stale run.
  final String? scope;

  /// The refresh token was explicitly rejected: the UI should ask the user
  /// to sign in again. The engine itself never logs out.
  bool get needsLogin =>
      phase == SyncPhase.blocked && block == SyncBlockReason.tokenExpired;

  static const Object _keep = Object();

  SyncStatus copyWith({
    SyncPhase? phase,
    SyncBlockReason? block,
    int? pending,
    int? rejected,
    Object? lastSyncedAt = _keep,
    bool? serverReachable,
    Object? lastError = _keep,
    Object? nextRetryAt = _keep,
    bool? moreToPull,
    String? scope,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    block: block ?? this.block,
    pending: pending ?? this.pending,
    rejected: rejected ?? this.rejected,
    lastSyncedAt: identical(lastSyncedAt, _keep)
        ? this.lastSyncedAt
        : lastSyncedAt as DateTime?,
    serverReachable: serverReachable ?? this.serverReachable,
    lastError: identical(lastError, _keep)
        ? this.lastError
        : lastError as String?,
    nextRetryAt: identical(nextRetryAt, _keep)
        ? this.nextRetryAt
        : nextRetryAt as DateTime?,
    moreToPull: moreToPull ?? this.moreToPull,
    scope: scope ?? this.scope,
  );

  @override
  String toString() =>
      'SyncStatus(${phase.name}, block=${block.name}, pending=$pending, '
      'rejected=$rejected, reachable=$serverReachable, error=$lastError)';
}

class _Blocked implements Exception {
  _Blocked(this.reason);
  final SyncBlockReason reason;
}

class _LockLost implements Exception {}

class _Cancelled implements Exception {}

enum _Cleanup { none, retry, restore }

/// Push/pull orchestrator. See docs/superpowers/specs/
/// 2026-11-16-offline-first-sync-design.md (SyncEngine).
///
/// Invariants:
///  * single flight: in-process flag + `sync_lock` DB lease renewed per
///    batch/page and right before every results write; a runner that lost
///    the lease writes nothing.
///  * every outbox write for a claimed row is guarded by the exact lease the
///    row was claimed under, so a stale runner can never overwrite another
///    runner's claim.
///  * results are matched by `mutation_id`; a missing result is a retry.
///  * every batch's results (including retry scheduling) are written in ONE
///    transaction; every pull page and its cursor in ONE transaction.
///  * claimed rows never stay `inflight` after an error (except a simulated
///    crash, where the lease expiry recovers them).
///  * the engine never logs out and never orders by wall clock.
class SyncEngine {
  SyncEngine({
    required OfflineDb db,
    required SyncTransport transport,
    required OutboxStore outbox,
    required SyncStateStore state,
    required String? Function() scopeProvider,
    Future<String?> Function()? readSessionKey,
    required ServerReachability reachability,
    required ChangeApplierRegistry appliers,
    required DbChangeNotifier notifier,
    required String appVersion,
    Backoff? backoff,
    DateTime Function()? now,
    SyncHooks? hooks,
    Future<RefreshOutcome> Function()? refreshToken,
    bool requireBootstrapWhenNoCursor = true,
    int pullPageSize = defaultPullPageSize,
    Duration lockTtl = const Duration(minutes: 2),
    Duration claimLease = const Duration(minutes: 3),
    Uuid? uuid,
  }) : _db = db,
       _transport = transport,
       _outbox = outbox,
       _state = state,
       _scopeProvider = scopeProvider,
       _readSessionKey = readSessionKey,
       _reachability = reachability,
       _appliers = appliers,
       _notifier = notifier,
       _appVersion = appVersion,
       _backoff = backoff ?? Backoff(),
       _now = now ?? DateTime.now,
       _hooks = hooks ?? const SyncHooks(),
       _refreshToken = refreshToken,
       _requireBootstrapWhenNoCursor = requireBootstrapWhenNoCursor,
       _pullPageSize = pullPageSize,
       _lockTtl = lockTtl,
       _claimLease = claimLease,
       _holder = (uuid ?? const Uuid()).v4() {
    _notifierSub = _notifier.changes.listen((tables) {
      if (tables.contains(SyncTables.outbox)) unawaited(_publish());
    });
  }

  static const int pushBatchSize = 100;
  static const int defaultPullPageSize = 500;
  static const int maxPullPagesPerRun = 200;

  /// Extra cycles run when syncNow was requested during a run.
  static const int maxExtraCycles = 2;

  /// Upper bound for any per-row retry delay (also used to detect a clock
  /// that moved backwards).
  static const Duration maxRowDelay = Duration(hours: 1);

  final OfflineDb _db;
  final SyncTransport _transport;
  final OutboxStore _outbox;
  final SyncStateStore _state;
  final String? Function() _scopeProvider;

  /// Live auth session key (`userId|tenantId`), like the transport's
  /// interceptor reads it. [_scopeProvider] is the delayed published scope.
  final Future<String?> Function()? _readSessionKey;

  /// Scope and scoped state view of the run in progress (runs are serial).
  String _scope = '';
  late SyncStateStore _st = _state;
  final ServerReachability _reachability;
  final ChangeApplierRegistry _appliers;
  final DbChangeNotifier _notifier;
  final String _appVersion;
  final Backoff _backoff;
  final DateTime Function() _now;
  final SyncHooks _hooks;
  final Future<RefreshOutcome> Function()? _refreshToken;
  final bool _requireBootstrapWhenNoCursor;
  final int _pullPageSize;
  final Duration _lockTtl;
  final Duration _claimLease;
  final String _holder;

  final _statusCtrl = StreamController<SyncStatus>.broadcast();
  StreamSubscription<Set<String>>? _notifierSub;
  SyncStatus _status = const SyncStatus();
  int _countsGen = 0;

  bool _running = false;
  bool _cancelRequested = false;
  bool _rerun = false;
  bool _refreshAttempted = false;
  int _failures = 0;
  int _pushLimit = pushBatchSize;

  Stream<SyncStatus> get status => _statusCtrl.stream;
  SyncStatus get current => _status;

  Future<void> dispose() async {
    await _notifierSub?.cancel();
    _notifierSub = null;
    if (!_statusCtrl.isClosed) await _statusCtrl.close();
  }

  /// Cooperative cancel of the run in progress: checked between push batches
  /// and pull pages (and right after a batch was claimed, which then returns
  /// to `pending` with no attempt bump). A response already received is still
  /// written. Reset at the start of every run, so a later run is unaffected.
  void cancel() => _cancelRequested = true;

  void _checkCancelled() {
    if (_cancelRequested) throw _Cancelled();
  }

  // ------------------------------------------------------------- entry

  /// Runs a sync. A call made while a run is in progress returns
  /// [SyncOutcome.alreadyRunning] and asks the running call to do (at most
  /// [maxExtraCycles]) more cycles once it completes, so writes made during
  /// a run are not left waiting for the next trigger.
  Future<SyncOutcome> syncNow({SyncReason reason = SyncReason.manual}) async {
    if (_running) {
      _rerun = true; // checked before any await
      return SyncOutcome.alreadyRunning;
    }
    _running = true;
    _rerun = false;
    _cancelRequested = false;
    try {
      _refreshAttempted = false; // once per syncNow, across its cycles
      _pushLimit = pushBatchSize;
      var outcome = await _cycle(reason);
      var extra = 0;
      while (outcome == SyncOutcome.completed &&
          _rerun &&
          extra < maxExtraCycles) {
        _rerun = false;
        extra++;
        outcome = await _cycle(reason);
      }
      if (outcome != SyncOutcome.completed) _rerun = false;
      return outcome;
    } finally {
      _running = false;
    }
  }

  /// One locked cycle: ping, push, pull.
  Future<SyncOutcome> _cycle(SyncReason reason) async {
    var lockHeld = false;
    var crashed = false;
    try {
      if (!await _state.acquireLock(_holder, _lockTtl)) {
        return SyncOutcome.alreadyRunning;
      }
      lockHeld = true;
      return await _run(reason);
    } on CrashSimulation {
      crashed = true;
      rethrow;
    } on _LockLost {
      lockHeld = false;
      await _setPhase(SyncPhase.idle);
      return SyncOutcome.alreadyRunning;
    } on _Cancelled {
      await _setPhase(SyncPhase.idle);
      return SyncOutcome.cancelled;
    } on _Blocked catch (b) {
      return _blocked(b.reason);
    } on SyncTransportException catch (e) {
      return _onTransportError(e);
    } catch (e, st) {
      _log('sync failed', e, st);
      return _enterBackoff(error: e.toString());
    } finally {
      if (lockHeld && !crashed) {
        try {
          await _state.releaseLock(_holder);
        } catch (e, st) {
          _log('releaseLock failed', e, st);
        }
      }
    }
  }

  Future<SyncOutcome> _run(SyncReason reason) async {
    final scope = _scopeProvider();
    if (scope == null || scope.isEmpty) {
      return _blocked(SyncBlockReason.noSession);
    }
    _scope = scope;
    _st = _state.forScope(scope);
    _status = _status.copyWith(
      lastSyncedAt: await _state.lastSyncedAt(),
      lastError: null,
      scope: scope,
    );
    await _setPhase(SyncPhase.pinging, block: SyncBlockReason.none);

    // (2) ping gate.
    final ping = await _reachability.check(force: true);
    if (ping == null) {
      _status = _status.copyWith(serverReachable: false);
      return _enterBackoff(error: 'server_unreachable');
    }
    _status = _status.copyWith(serverReachable: true);
    if (_isAppTooOld(ping.minAppVersion)) {
      return _blocked(SyncBlockReason.appTooOld);
    }
    if (ping.maintenance) {
      return _enterBackoff(
        error: 'maintenance',
        retryAfter: ping.retryAfterSeconds,
        block: SyncBlockReason.maintenance,
      );
    }
    // Informational only: never used to reorder or reject mutations.
    final skew = _reachability.clockSkew;
    if (skew != null) await _state.setClockSkew(skew);
    await _state.setCapabilities(ping.capabilities);
    final deviceId = await _state.deviceId();

    // (3) recover rows leased by a dead runner (or a clock moved back).
    await _outbox.releaseExpiredLeases(maxLease: _claimLease);

    // (4) push.
    await _setPhase(SyncPhase.pushing);
    while (true) {
      _checkCancelled();
      await _ensureLock();
      await _assertScope();
      final batch = await _outbox.claimBatch(
        scope: scope,
        limit: _pushLimit,
        lease: _claimLease,
        maxRetryDelay: maxRowDelay,
      );
      if (batch.isEmpty) break;
      final progressed = await _pushBatch(deviceId, batch);
      if (!progressed) break; // all retry/missing: wait for their backoff
    }

    // (5) pull. Without a cursor the device has never bootstrapped: pulling
    // from the start of the feed is not a substitute for the bootstrap.
    var cursor = await _st.cursor();
    if ((cursor == null || cursor.isEmpty) && _requireBootstrapWhenNoCursor) {
      _failures = 0;
      await _setPhase(SyncPhase.idle, block: SyncBlockReason.none);
      return SyncOutcome.needsBootstrap;
    }
    await _setPhase(SyncPhase.pulling);
    var pages = 0;
    var moreToPull = false;
    while (true) {
      if (pages >= maxPullPagesPerRun) {
        moreToPull = true;
        break;
      }
      _checkCancelled();
      await _ensureLock();
      await _assertScope();
      final sent = cursor;
      final page = await _authed(
        () =>
            _transport.pull(cursor: sent, limit: _pullPageSize, scope: _scope),
      );
      pages++;
      _reachability.reportSuccess();
      if (page.fullResyncRequired) {
        await _resetForBootstrap();
        _failures = 0;
        await _setPhase(SyncPhase.idle);
        return SyncOutcome.needsBootstrap;
      }
      await _assertScope();
      final touched = await _applyPage(page);
      if (touched.isNotEmpty) _notifier.notify(touched);
      cursor = page.nextCursor;
      if (!page.hasMore) break;
      if (page.nextCursor == sent) break; // no progress: stop, retry later
    }
    if (moreToPull) _rerun = true;

    // (6) done.
    final at = _now().toUtc();
    await _state.setLastSyncedAt(at);
    _notifier.notify({SyncTables.syncState});
    _failures = 0;
    _status = _status.copyWith(
      lastSyncedAt: at,
      lastError: null,
      nextRetryAt: null,
      serverReachable: true,
      moreToPull: moreToPull,
    );
    await _setPhase(SyncPhase.idle, block: SyncBlockReason.none);
    return SyncOutcome.completed;
  }

  // ------------------------------------------------------------- pull

  /// Applies one page and its cursor in ONE transaction. A change whose
  /// (entity, id) still has a non-done outbox row is deferred (kept in
  /// sync_state, latest seq wins) when its applier asks for that. Deferred
  /// changes are applied only in the LAST page of a pull run (has_more ==
  /// false): a newer row for the same entity may sit on a later page, and an
  /// intermediate commit must never expose the older one. A newer applied
  /// row on any page drops the entry, and an entry whose version is not newer
  /// than the local row is dropped without applying.
  Future<Set<String>> _applyPage(PullResponse page) async {
    final touched = <String>{};
    await (await _db.database).transaction((txn) async {
      final raw = await _st.deferredPullJson(txn);
      final deferred = _decodeDeferred(raw);
      // A corrupt blob decodes to null: drop it (rewrite) and flag repair,
      // so it is reported once rather than on every page.
      var dirty = deferred == null;
      final pending = deferred ?? <String, PullChange>{};
      if (deferred == null) await _st.setRepairNeeded(txn);

      for (final change in page.changes) {
        final applier = _appliers.of(change.entity);
        if (applier == null) continue; // unknown entity: skip, advance
        final key = '${change.entity}|${change.id}';
        if (applier.skipWhenLocalPending &&
            await _hasLocalPending(txn, change)) {
          final prev = pending[key];
          if (prev == null || prev.seq < change.seq) {
            pending[key] = change;
            dirty = true;
          }
          continue;
        }
        await applier.apply(txn, change);
        touched.addAll(applier.tables);
        if (pending.remove(key) != null) dirty = true;
      }

      if (!page.hasMore) {
        for (final key in pending.keys.toList()) {
          final change = pending[key]!;
          final applier = _appliers.of(change.entity);
          if (applier == null) {
            pending.remove(key);
            dirty = true;
            continue;
          }
          if (applier.skipWhenLocalPending &&
              await _hasLocalPending(txn, change)) {
            continue;
          }
          final local = await applier.localVersion(txn, change);
          final v = change.version;
          if (!(v != null && local != null && v <= local)) {
            await applier.apply(txn, change);
            touched.addAll(applier.tables);
          }
          pending.remove(key);
          dirty = true;
        }
      }

      final hook = _hooks.beforePullPageCommit;
      if (hook != null) await hook(page);
      await _assertScope(); // throwing rolls the whole page back
      if (dirty) {
        await _st.setDeferredPullJson(
          txn,
          pending.isEmpty
              ? null
              : jsonEncode({
                  for (final e in pending.entries) e.key: e.value.toJson(),
                }),
        );
      }
      await _st.setCursor(txn, page.nextCursor);
    });
    return touched;
  }

  Future<bool> _hasLocalPending(Transaction txn, PullChange change) async {
    final rows = await txn.rawQuery(
      'SELECT 1 FROM ${SyncTables.outbox} WHERE entity = ? AND entity_id = ? '
      "AND scope = ? AND status IN ('pending','inflight','blocked') LIMIT 1",
      [change.entity, change.id, _scope],
    );
    return rows.isNotEmpty;
  }

  /// Null when the stored blob is unreadable (reported here).
  Map<String, PullChange>? _decodeDeferred(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          e.key: PullChange.fromJson(Map<String, dynamic>.from(e.value as Map)),
      };
    } catch (e, st) {
      _report(e, st, 'deferred pull changes unreadable; dropped');
      return null;
    }
  }

  // ------------------------------------------------------------- push

  /// Pushes one claimed batch. Returns true when the loop should continue
  /// (at least one terminal result, or a smaller batch should be tried).
  Future<bool> _pushBatch(String deviceId, List<OutboxEntry> batch) async {
    var cleanup = _Cleanup.retry;
    int? retryAfter;
    var written = false;
    try {
      await _assertScope();
      _checkCancelled(); // claimed rows go back untouched (restore)
      final resp = await _authed(
        () => _transport.push(
          deviceId: deviceId,
          appVersion: _appVersion,
          mutations: batch,
          scope: _scope,
        ),
      );
      _reachability.reportSuccess();
      final beforeWrite = _hooks.beforeResultWrite;
      if (beforeWrite != null) await beforeWrite(batch, resp);
      await _assertScope();

      // Match by mutation_id; ignore ids we did not send; first one wins.
      final sent = {for (final e in batch) e.mutationId};
      final byId = <String, PushResult>{};
      for (final r in resp.results) {
        if (sent.contains(r.mutationId)) {
          byId.putIfAbsent(r.mutationId, () => r);
        }
      }

      // A runner that lost the lease writes nothing; rows stay for lease
      // recovery by the current holder.
      await _ensureLock();

      final touched = <String>{SyncTables.outbox};
      bool progressed;
      try {
        progressed = await (await _db.database).transaction((txn) async {
          var p = false;
          for (final e in batch) {
            if (await _writeResult(txn, e, byId[e.mutationId], touched)) {
              p = true;
            }
          }
          return p;
        });
      } catch (err, st) {
        if (err is CrashSimulation) rethrow;
        _log('batch result write failed, retrying per row', err, st);
        progressed = await _writeResultsPerRow(batch, byId, touched);
      }
      written = true;
      _notifier.notify(touched);
      final afterApplied = _hooks.afterPushApplied;
      if (afterApplied != null) await afterApplied(batch);
      return progressed;
    } catch (e) {
      if (written) rethrow; // every row already has its outcome
      if (e is CrashSimulation || e is _LockLost) {
        cleanup = _Cleanup.none;
      } else if (e is _Blocked ||
          e is _Cancelled ||
          (e is SyncTransportException &&
              (_isHardBlock(e) || e.kind == SyncTransportKind.scopeChanged))) {
        cleanup = _Cleanup.restore;
      } else if (e is SyncTransportException &&
          e.kind == SyncTransportKind.tooLarge) {
        if (batch.length == 1) {
          // Cannot be split further: park it instead of retrying forever.
          await _parkTooLarge(batch.single); // throws -> retry cleanup
          written = true;
          return true;
        }
        cleanup = _Cleanup.restore;
        _pushLimit = max(1, min(_pushLimit, batch.length) ~/ 2);
        return true; // retry right away with a smaller batch
      } else if (e is SyncTransportException) {
        retryAfter = e.retryAfterSeconds;
      }
      rethrow;
    } finally {
      if (!written && cleanup != _Cleanup.none) {
        await _releaseClaimed(batch, cleanup, retryAfter);
      }
    }
  }

  /// Writes the outcome for one claimed row. Every write is guarded by the
  /// lease the row was claimed under; 0 rows updated means another runner
  /// owns it and nothing else (applier, dependents) is touched.
  /// Returns true for a terminal result written by us.
  Future<bool> _writeResult(
    Transaction txn,
    OutboxEntry e,
    PushResult? r,
    Set<String> touched, {
    bool withApplier = true,
  }) async {
    final lease = e.leaseUntil;
    if (r == null || r.status == PushStatus.retry) {
      await _outbox.scheduleRetry(
        e.mutationId,
        _now().add(_rowDelay(e)),
        executor: txn,
        leaseUntil: lease,
      );
      return false;
    }
    final applier = withApplier ? _appliers.of(e.entity) : null;
    final converged =
        r.status == PushStatus.rejected &&
        e.op == 'delete' &&
        r.code == 'entity_deleted';
    if (r.status == PushStatus.rejected && !converged) {
      final n = await _outbox.applyResult(
        txn,
        e.mutationId,
        status: OutboxStatus.rejected,
        code: r.code,
        message: r.message,
        leaseUntil: lease,
      );
      if (n == 0) return false;
      if (applier != null) {
        await applier.onPushResult(txn, e, r);
        touched.addAll(applier.tables);
      }
      await _outbox.failDependents(txn, e.entityId, scope: e.scope);
      return true;
    }
    final n = await _outbox.applyResult(
      txn,
      e.mutationId,
      status: OutboxStatus.done,
      leaseUntil: lease,
    );
    if (n == 0) return false;
    // A converged delete is not an error for the applier: nothing to do.
    if (applier != null && !converged) {
      await applier.onPushResult(txn, e, r);
      touched.addAll(applier.tables);
    }
    await _outbox.unblockDependents(txn, e.entityId, scope: e.scope);
    return true;
  }

  /// Fallback when the batch transaction failed: each row in its own
  /// transaction. A row whose applier still throws is recorded with the
  /// server's outcome anyway (the server already applied it) and the repair
  /// flag is raised.
  Future<bool> _writeResultsPerRow(
    List<OutboxEntry> batch,
    Map<String, PushResult> byId,
    Set<String> touched,
  ) async {
    final db = await _db.database;
    var progressed = false;
    for (final e in batch) {
      final r = byId[e.mutationId];
      try {
        if (await db.transaction((txn) => _writeResult(txn, e, r, touched))) {
          progressed = true;
        }
        continue;
      } catch (err, st) {
        if (err is CrashSimulation) rethrow;
        _report(
          err,
          st,
          'push result for ${e.entity}/${e.entityId} '
          '(${e.mutationId}) could not be applied locally',
        );
      }
      try {
        if (await db.transaction(
          (txn) => _writeResult(txn, e, r, touched, withApplier: false),
        )) {
          progressed = true;
        }
        if (r != null && r.status != PushStatus.retry) {
          await _st.setRepairNeeded();
        }
      } catch (err, st) {
        if (err is CrashSimulation) rethrow;
        _log('row result write failed', err, st);
        // Best effort; otherwise the lease expiry recovers the row.
        await _releaseClaimed([e], _Cleanup.retry, null);
      }
    }
    return progressed;
  }

  Future<void> _parkTooLarge(OutboxEntry e) async {
    await (await _db.database).transaction((txn) async {
      final n = await _outbox.applyResult(
        txn,
        e.mutationId,
        status: OutboxStatus.rejected,
        code: 'payload_too_large',
        message: 'Mutation is too large for the server',
        leaseUntil: e.leaseUntil,
      );
      if (n > 0) await _outbox.failDependents(txn, e.entityId, scope: e.scope);
    });
    _notifier.notify({SyncTables.outbox});
  }

  Duration _rowDelay(OutboxEntry e, [int? retryAfterSeconds]) {
    var delay = _backoff.delay(e.attempts + 1);
    if (retryAfterSeconds != null &&
        Duration(seconds: retryAfterSeconds) > delay) {
      delay = Duration(seconds: retryAfterSeconds);
    }
    return delay > maxRowDelay ? maxRowDelay : delay;
  }

  /// Returns claimed-but-unresolved rows to `pending` (only rows still held
  /// under our lease). `retry` bumps attempts and sets a per-row backoff;
  /// `restore` leaves attempts/backoff untouched.
  Future<void> _releaseClaimed(
    List<OutboxEntry> rows,
    _Cleanup mode,
    int? retryAfterSeconds,
  ) async {
    try {
      final now = _now();
      for (final e in rows) {
        if (mode == _Cleanup.retry) {
          await _outbox.scheduleRetry(
            e.mutationId,
            now.add(_rowDelay(e, retryAfterSeconds)),
            leaseUntil: e.leaseUntil,
          );
        } else {
          await _outbox.releaseClaim(e.mutationId, leaseUntil: e.leaseUntil);
        }
      }
      _notifier.notify({SyncTables.outbox});
    } catch (e, st) {
      // Rows keep their lease; releaseExpiredLeases recovers them.
      _log('releasing claimed rows failed', e, st);
    }
  }

  // ------------------------------------------------------------- helpers

  void _log(String msg, Object e, StackTrace st) =>
      developer.log(msg, name: 'SyncEngine', error: e, stackTrace: st);

  void _report(Object e, StackTrace st, String context) {
    _log(context, e, st);
    try {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'sync engine',
          context: ErrorDescription(context),
        ),
      );
    } catch (_) {
      // Reporting must never break sync.
    }
  }

  Future<void> _ensureLock() async {
    if (await _state.renewLock(_holder, _lockTtl)) return;
    // Our own lease may have lapsed without anyone taking it: re-acquire.
    // Fails if another holder owns an unexpired lease.
    if (await _state.acquireLock(_holder, _lockTtl)) return;
    throw _LockLost();
  }

  /// Throws [SyncTransportKind.scopeChanged] when the signed-in scope is no
  /// longer the one this run was started for. Nothing may be sent, applied
  /// or committed under another session's credentials.
  Future<void> _assertScope() async {
    if (_scopeProvider() != _scope ||
        (_readSessionKey != null && await _readSessionKey() != _scope)) {
      throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
    }
  }

  bool _isAuthExpiry(SyncTransportException e) =>
      e.kind == SyncTransportKind.tokenExpired ||
      e.kind == SyncTransportKind.unauthorized;

  bool _isHardBlock(SyncTransportException e) =>
      e.kind == SyncTransportKind.accountDisabled ||
      e.kind == SyncTransportKind.deviceRevoked;

  /// Runs [call]; on token expiry refreshes once per syncNow and retries
  /// once. `rejected` -> blocked(tokenExpired); `transient`/no callback/
  /// callback error -> the original exception (treated as backoff).
  Future<T> _authed<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SyncTransportException catch (e, st) {
      if (!_isAuthExpiry(e) || _refreshAttempted) rethrow;
      _refreshAttempted = true;
      final refresh = _refreshToken;
      if (refresh == null) rethrow;
      RefreshOutcome outcome;
      try {
        outcome = await refresh();
      } catch (err, rst) {
        _log('token refresh failed', err, rst);
        outcome = RefreshOutcome.transient;
      }
      switch (outcome) {
        case RefreshOutcome.refreshed:
          await _assertScope(); // the refresh may have landed on another session
          return await call();
        case RefreshOutcome.rejected:
          throw _Blocked(SyncBlockReason.tokenExpired);
        case RefreshOutcome.transient:
          Error.throwWithStackTrace(e, st);
      }
    }
  }

  Future<SyncOutcome> _onTransportError(SyncTransportException e) {
    switch (e.kind) {
      case SyncTransportKind.accountDisabled:
        return _blocked(SyncBlockReason.accountDisabled);
      case SyncTransportKind.deviceRevoked:
        return _blocked(SyncBlockReason.deviceRevoked);
      case SyncTransportKind.scopeChanged:
        return _blocked(SyncBlockReason.noSession);
      case SyncTransportKind.maintenance:
        _status = _status.copyWith(serverReachable: true);
        return _enterBackoff(
          error: 'maintenance',
          retryAfter: e.retryAfterSeconds,
          block: SyncBlockReason.maintenance,
        );
      case SyncTransportKind.tooLarge:
        // Push handles this per batch; here only from pull.
        _status = _status.copyWith(serverReachable: true);
        return _enterBackoff(error: e.code ?? 'payload_too_large');
      case SyncTransportKind.tokenExpired:
      case SyncTransportKind.unauthorized:
        // Refresh was not possible or transient: never block, never logout.
        _status = _status.copyWith(serverReachable: true);
        return _enterBackoff(error: e.code ?? e.kind.name);
      case SyncTransportKind.network:
      case SyncTransportKind.timeout:
      case SyncTransportKind.server:
        _reachability.reportFailure();
        _status = _status.copyWith(serverReachable: false);
        return _enterBackoff(
          error: e.code ?? e.kind.name,
          retryAfter: e.retryAfterSeconds,
        );
    }
  }

  Future<SyncOutcome> _blocked(SyncBlockReason reason) async {
    _status = _status.copyWith(nextRetryAt: null, lastError: reason.name);
    await _setPhase(SyncPhase.blocked, block: reason);
    return SyncOutcome.blocked;
  }

  Future<SyncOutcome> _enterBackoff({
    required String error,
    int? retryAfter,
    SyncBlockReason block = SyncBlockReason.none,
  }) async {
    _failures++;
    final delay = retryAfter != null && retryAfter > 0
        ? Duration(seconds: retryAfter)
        : _backoff.delay(_failures);
    _status = _status.copyWith(
      lastError: error,
      nextRetryAt: _now().toUtc().add(delay),
    );
    await _setPhase(SyncPhase.backoff, block: block);
    return SyncOutcome.backoff;
  }

  Future<void> _resetForBootstrap() async {
    final caps = await _state.capabilities();
    final skew = await _state.clockSkew();
    await _st.clear(); // cursor, skew, last sync, capabilities, deferred
    await _state.setCapabilities(caps);
    if (skew != null) await _state.setClockSkew(skew);
    _status = _status.copyWith(lastSyncedAt: null);
    _notifier.notify({SyncTables.syncState});
  }

  bool _isAppTooOld(String? minVersion) {
    if (minVersion == null || minVersion.trim().isEmpty) return false;
    final min = _parseVersion(minVersion);
    final mine = _parseVersion(_appVersion);
    // Unparseable values never brick the app.
    if (min == null || mine == null) return false;
    for (var i = 0; i < max(min.length, mine.length); i++) {
      final a = i < mine.length ? mine[i] : 0;
      final b = i < min.length ? min[i] : 0;
      if (a != b) return a < b;
    }
    return false;
  }

  static List<int>? _parseVersion(String v) {
    final core = v.trim().split('+').first.split('-').first;
    if (!RegExp(r'^\d+(\.\d+)*$').hasMatch(core)) return null;
    return core.split('.').map(int.parse).toList();
  }

  // ------------------------------------------------------------- status

  Future<void> _setPhase(SyncPhase phase, {SyncBlockReason? block}) async {
    _status = _status.copyWith(phase: phase, block: block);
    await _publish();
  }

  /// Re-reads outbox counts (after commit) and emits the current status.
  Future<void> _publish() async {
    final gen = ++_countsGen;
    try {
      final db = await _db.database;
      final rows = await db.rawQuery(
        'SELECT '
        "SUM(CASE WHEN status IN ('pending','inflight','blocked') "
        'THEN 1 ELSE 0 END) AS p, '
        "SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) AS r "
        'FROM ${SyncTables.outbox} WHERE scope = ?',
        [_scopeProvider() ?? ''],
      );
      if (gen == _countsGen) {
        _status = _status.copyWith(
          pending: (rows.first['p'] as int?) ?? 0,
          rejected: (rows.first['r'] as int?) ?? 0,
        );
      }
    } catch (_) {
      // DB closed or busy: emit with the last known counts.
    }
    if (!_statusCtrl.isClosed) _statusCtrl.add(_status);
  }
}
