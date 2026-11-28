import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show Transaction;
import 'package:uuid/uuid.dart';

import '../../offline/offline_db.dart';
import '../catalog_stash.dart';
import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../db_change_notifier.dart';
import '../deferred_pull.dart';
import '../sync_engine.dart';
import '../sync_schema.dart';
import '../sync_state_store.dart';
import '../transport/sync_transport.dart';

enum BootstrapOutcome {
  completed,
  interrupted,
  blocked,
  alreadyRunning,
  notNeeded,
}

/// Progress of the bootstrap run, for the first-setup screen.
@immutable
class BootstrapStatus {
  const BootstrapStatus({
    this.outcome,
    this.currentEntity,
    this.entityIndex = 0,
    this.entityCount = 0,
    this.rowsApplied = 0,
    this.offline = false,
    this.block,
    this.scope,
  });

  /// The scope (`userId|tenantId`) this run belongs to; null before the run
  /// knows it (e.g. blocked for no session). The stream is process-wide,
  /// so readers must ignore another scope's status (stale session).
  final String? scope;

  /// Null while running; set on the run's last event.
  final BootstrapOutcome? outcome;
  final String? currentEntity;

  /// 0-based index of [currentEntity] in the stored entity list.
  final int entityIndex;
  final int entityCount;

  /// Items written by this run (applied, not skipped or deferred).
  final int rowsApplied;

  /// The run stopped because the network/server was unreachable.
  final bool offline;

  /// Why the run is blocked; null with [BootstrapOutcome.blocked] means the
  /// server lacks the `bootstrap_paged` capability ([serverNotReady]).
  final SyncBlockReason? block;

  bool get serverNotReady =>
      outcome == BootstrapOutcome.blocked && block == null;

  BootstrapStatus copyWith({
    BootstrapOutcome? outcome,
    String? currentEntity,
    int? entityIndex,
    int? entityCount,
    int? rowsApplied,
    bool? offline,
    SyncBlockReason? block,
    String? scope,
  }) => BootstrapStatus(
    outcome: outcome ?? this.outcome,
    currentEntity: currentEntity ?? this.currentEntity,
    entityIndex: entityIndex ?? this.entityIndex,
    entityCount: entityCount ?? this.entityCount,
    rowsApplied: rowsApplied ?? this.rowsApplied,
    offline: offline ?? this.offline,
    block: block ?? this.block,
    scope: scope ?? this.scope,
  );

  @override
  String toString() =>
      'BootstrapStatus(${outcome?.name ?? 'running'}, $currentEntity '
      '${entityIndex + 1}/$entityCount, rows=$rowsApplied, '
      'offline=$offline, block=${block?.name}, scope=$scope)';
}

class _Stop implements Exception {
  _Stop(this.outcome, {this.block});
  final BootstrapOutcome outcome;
  final SyncBlockReason? block;
}

/// Resumable paged first setup of one scope (spec 2026-11-16 phase 2,
/// section 2).
///
/// Invariants:
///  * the snapshot is taken ONCE: while a [BootstrapProgress] exists for the
///    scope, the stored snapshot, entity list and done set decide what is
///    requested (a changed manifest is ignored until the run finishes).
///  * every page is ONE transaction: its items (synthetic upserts through
///    the same [ChangeApplier]s pull uses), its deferrals and the advanced
///    progress. A failure anywhere rolls the whole page back; progress never
///    moves past rows that are not committed.
///  * items never roll a row back (`version <= local` is skipped) and never
///    overwrite a row with an unsynced outbox edit (deferred through the
///    engine's `deferred_pull`, which the final transaction keeps).
///  * the pull cursor is set (= snapshot) only by the final transaction,
///    together with `bootstrapped` and the progress removal.
///  * same `sync_lock` as the engine (renewed before every request and every
///    commit); a lost lease writes nothing.
///  * never logs out: offline/timeout/5xx -> interrupted.
class Bootstrapper {
  Bootstrapper({
    required OfflineDb db,
    required SyncTransport transport,
    required SyncStateStore state,
    required ChangeApplierRegistry appliers,
    required DbChangeNotifier notifier,
    required String? Function() scopeProvider,
    required Future<void> Function() assertScope,
    required Future<Set<String>> Function() capabilities,
    required AuthedCall Function(String scope) authedFor,
    int pageSize = defaultPageSize,
    int maxPagesPerEntity = defaultMaxPagesPerEntity,
    DateTime Function()? now,
    Duration lockTtl = const Duration(minutes: 2),
    Uuid? uuid,
    Future<void> Function(Duration)? sleep,
  }) : _db = db,
       _transport = transport,
       _state = state,
       _appliers = appliers,
       _notifier = notifier,
       _scopeProvider = scopeProvider,
       _assertScopeHook = assertScope,
       _capabilities = capabilities,
       _authedFor = authedFor,
       _maxPagesPerEntity = maxPagesPerEntity,
       _pageSize = pageSize,
       _now = now ?? DateTime.now,
       _lockTtl = lockTtl,
       _sleep = sleep ?? Future<void>.delayed,
       _holder = (uuid ?? const Uuid()).v4();

  static const int defaultPageSize = 500;
  static const int salePageSize = 200;
  static const int salesSinceDays = 90;

  /// Guard against a server cursor cycle (A, B, A...) looping forever.
  static const int defaultMaxPagesPerEntity = 20000;
  static const String capability = 'bootstrap_paged';

  /// Fixed client order (dependency friendly). Manifest entities not listed
  /// here are logged and skipped; listed ones the manifest lacks (cashier
  /// scope) are never requested.
  static const List<String> entityOrder = [
    'business',
    'shop',
    'category',
    'product',
    'vendor',
    'customer',
    'user',
    'subscription',
    'bankak_account',
    'stock',
    'expiry_batch',
    'sale',
    'refund',
    'inbound',
    'notification',
  ];

  final OfflineDb _db;
  final SyncTransport _transport;
  final SyncStateStore _state;
  final ChangeApplierRegistry _appliers;
  final DbChangeNotifier _notifier;
  final String? Function() _scopeProvider;
  final Future<void> Function() _assertScopeHook;
  final Future<Set<String>> Function() _capabilities;

  /// Token wrapper factory (engine.authedFor); a fresh wrapper, so a fresh
  /// refresh budget, per run.
  final AuthedCall Function(String scope) _authedFor;
  AuthedCall _authed = _noAuth;
  static Future<T> _noAuth<T>(Future<T> Function() call) => call();
  final int _maxPagesPerEntity;
  final int _pageSize;
  final DateTime Function() _now;
  final Duration _lockTtl;
  final Future<void> Function(Duration) _sleep;

  /// A 429 during first setup is waited out (Retry-After, else 2s, 4s, 8s...
  /// capped at [maxRateLimitWait]) instead of failing the whole download.
  /// After [maxRateLimitRetries] the run is interrupted and resumes later
  /// from the stored cursor; nothing is lost.
  static const int maxRateLimitRetries = 6;
  static const Duration maxRateLimitWait = Duration(seconds: 60);

  Future<T> _call<T>(Future<T> Function() call) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _authed(call);
      } on SyncTransportException catch (e) {
        if (e.httpStatus != 429 || attempt >= maxRateLimitRetries) rethrow;
        if (_cancelRequested) throw _Stop(BootstrapOutcome.interrupted);
        var wait = e.retryAfterSeconds != null
            ? Duration(seconds: e.retryAfterSeconds!)
            : Duration(seconds: 2 << attempt);
        if (wait > maxRateLimitWait) wait = maxRateLimitWait;
        _log('rate limited; waiting ${wait.inSeconds}s (try ${attempt + 1})');
        await _sleep(wait);
      }
    }
  }
  final String _holder;

  /// Synchronous so the run's last event is delivered before [run]
  /// returns (a progress screen never misses the outcome).
  final _statusCtrl = StreamController<BootstrapStatus>.broadcast(sync: true);
  BootstrapStatus _status = const BootstrapStatus();

  bool _running = false;
  bool _cancelRequested = false;
  String _scope = '';
  late SyncStateStore _st = _state;

  Stream<BootstrapStatus> get status => _statusCtrl.stream;
  BootstrapStatus get current => _status;

  /// Cooperative stop, checked between pages; the page in flight is either
  /// fully committed or not at all. Reset at the start of every run.
  void cancel() => _cancelRequested = true;

  Future<void> dispose() async {
    if (!_statusCtrl.isClosed) await _statusCtrl.close();
  }

  // ------------------------------------------------------------- entry

  Future<BootstrapOutcome> run() async {
    if (_running) return BootstrapOutcome.alreadyRunning; // before any await
    _running = true;
    _cancelRequested = false;
    _status = const BootstrapStatus();
    var lockHeld = false;
    var crashed = false;
    try {
      final scope = _scopeProvider();
      if (scope == null || scope.isEmpty) {
        throw _Stop(BootstrapOutcome.blocked, block: SyncBlockReason.noSession);
      }
      _scope = scope;
      _st = _state.forScope(scope);
      _authed = _authedFor(scope);
      _emit(BootstrapStatus(scope: scope));

      if (await _notNeeded()) return _finish(BootstrapOutcome.notNeeded);
      final caps = await _capabilities();
      if (!caps.contains(capability)) {
        _log('server lacks "$capability": first setup blocked');
        return _finish(BootstrapOutcome.blocked);
      }
      if (!await _state.acquireLock(_holder, _lockTtl)) {
        return _finish(BootstrapOutcome.alreadyRunning);
      }
      lockHeld = true;
      await _assertScope();

      var progress = await _st.bootstrapProgress(await _db.database);
      // Ids the snapshot served per sweepable entity. Only a run that saw the
      // whole snapshot (no resume) may sweep ghost rows (F3).
      Map<String, Set<String>>? seen;
      if (progress == null) {
        if (await _notNeeded()) return _finish(BootstrapOutcome.notNeeded);
        progress = await _start();
        seen = {for (final e in sweepEntities) e: <String>{}};
      } else {
        progress = await _dropUnhandled(progress);
      }

      for (var i = 0; i < progress!.entities.length; i++) {
        final entity = progress.entities[i];
        if (progress.done.contains(entity)) continue;
        _emit(
          _status.copyWith(
            currentEntity: entity,
            entityIndex: i,
            entityCount: progress.entities.length,
          ),
        );
        var pages = 0;
        while (true) {
          final p = progress!;
          if (_cancelRequested) throw _Stop(BootstrapOutcome.interrupted);
          if (++pages > _maxPagesPerEntity) {
            throw FormatException(
              'bootstrap of "$entity" exceeded $_maxPagesPerEntity pages '
              '(cursor cycle?)',
            );
          }
          await _ensureLock();
          await _assertScope();
          final sent = p.pageCursor;
          final page = await _call(
            () => _transport.bootstrapPage(
              entity: entity,
              pageCursor: sent,
              limit: entity == 'sale' && _pageSize > salePageSize
                  ? salePageSize
                  : _pageSize,
              snapshotCursor: p.snapshotCursor,
              salesSinceDays: salesSinceDays,
              scope: _scope,
            ),
          );
          _checkPage(entity, sent, page, p);
          final served = seen?[entity];
          if (served != null) {
            for (final item in page.items) {
              final id = _idOf(item);
              if (id != null) served.add(id);
            }
          }
          await _ensureLock(); // a runner that lost the lease writes nothing
          final (next, touched, applied) = await _commitPage(entity, page, p);
          progress = next;
          if (touched.isNotEmpty) _notifier.notify(touched);
          _emit(_status.copyWith(rowsApplied: _status.rowsApplied + applied));
          if (!page.hasMore) break;
        }
      }

      if (_cancelRequested) throw _Stop(BootstrapOutcome.interrupted);
      await _ensureLock();
      await _finalCommit(progress, seen);
      _notifier.notify({SyncTables.syncState});
      return _finish(BootstrapOutcome.completed);
    } on CrashSimulation {
      crashed = true; // a killed process cleans nothing up
      rethrow;
    } on _Stop catch (s) {
      if (s.outcome == BootstrapOutcome.alreadyRunning) lockHeld = false;
      return _finish(s.outcome, block: s.block);
    } on SyncBlockedException catch (b) {
      return _finish(BootstrapOutcome.blocked, block: b.reason);
    } on SyncTransportException catch (e) {
      return _onTransportError(e);
    } catch (e, st) {
      _report(e, st, 'bootstrap of $_scope interrupted');
      return _finish(BootstrapOutcome.interrupted);
    } finally {
      if (lockHeld && !crashed) {
        try {
          await _state.releaseLock(_holder);
        } catch (e, st) {
          _log('releaseLock failed', e, st);
        }
      }
      _running = false;
    }
  }

  /// A scope with a pull cursor, the `bootstrapped` flag and no interrupted
  /// bootstrap is set up (ruling T6-b: same rule as the engine).
  Future<bool> _notNeeded() async {
    final c = await _st.cursor();
    if (c == null || c.isEmpty) return false;
    if (!await _st.isBootstrapped()) return false;
    return await _st.bootstrapProgress(await _db.database) == null;
  }

  /// Takes the snapshot (the ONLY manifest call of a bootstrap) and stores
  /// the ordered entity list.
  Future<BootstrapProgress> _start() async {
    final manifest = await _call(
      () => _transport.bootstrapManifest(scope: _scope),
    );
    for (final e in manifest.entities) {
      if (!entityOrder.contains(e)) {
        _log('unknown bootstrap entity "$e" skipped');
      }
    }
    final entities = <String>[];
    for (final e in entityOrder) {
      if (!manifest.entities.contains(e)) continue;
      if (_appliers.of(e) == null) {
        _log('no applier for bootstrap entity "$e"; skipped');
        continue;
      }
      entities.add(e);
    }
    final p = BootstrapProgress(
      snapshotCursor: manifest.snapshotCursor,
      entities: entities,
      done: const [],
      startedAt: _now().toUtc(),
    );
    await (await _db.database).transaction((txn) async {
      // Under the lock nobody else may have started one meanwhile.
      if (await _st.bootstrapProgress(txn) != null) {
        throw StateError('bootstrap progress appeared concurrently');
      }
      await _assertScope();
      await _st.setBootstrapProgress(txn, p);
    });
    _notifier.notify({SyncTables.syncState});
    return p;
  }

  /// Resume path: a stored entity with no registered applier is logged and
  /// dropped exactly like at start (its pages are never fetched); when it
  /// was the entity in progress, its page cursor is discarded.
  Future<BootstrapProgress> _dropUnhandled(BootstrapProgress p) async {
    final keep = <String>[];
    for (final e in p.entities) {
      if (_appliers.of(e) == null) {
        _log('no applier for stored bootstrap entity "$e"; dropped');
      } else {
        keep.add(e);
      }
    }
    if (keep.length == p.entities.length) return p;
    final current = p.entities.where((e) => !p.done.contains(e)).firstOrNull;
    final next = BootstrapProgress(
      snapshotCursor: p.snapshotCursor,
      entities: keep,
      done: p.done.where(keep.contains).toList(),
      pageCursor: current != null && keep.contains(current)
          ? p.pageCursor
          : null,
      startedAt: p.startedAt,
    );
    await (await _db.database).transaction((txn) async {
      if (!_same(await _st.bootstrapProgress(txn), p)) {
        throw StateError('bootstrap progress changed under this run');
      }
      await _assertScope();
      await _st.setBootstrapProgress(txn, next);
    });
    return next;
  }

  void _checkPage(
    String entity,
    String? sent,
    BootstrapPage page,
    BootstrapProgress p,
  ) {
    if (page.entity != entity) {
      throw FormatException(
        'bootstrap page for "${page.entity}" while asking "$entity"',
      );
    }
    if (page.hasMore) {
      final next = page.nextPageCursor;
      if (next == null || next.isEmpty || next == sent) {
        throw FormatException(
          'bootstrap page of "$entity" has_more without a new cursor',
        );
      }
    }
    if (page.snapshotCursor != p.snapshotCursor) {
      // The BE only echoes it; staleness is detected by pull.
      _log('bootstrap page echoed another snapshot (ignored)');
    }
  }

  // ------------------------------------------------------------- pages

  /// Applies one page, its deferrals and the advanced progress in ONE
  /// transaction. Returns the new progress, the touched tables and the
  /// number of applied items.
  Future<(BootstrapProgress, Set<String>, int)> _commitPage(
    String entity,
    BootstrapPage page,
    BootstrapProgress expected,
  ) async {
    final touched = <String>{};
    var applied = 0;
    final next = await (await _db.database).transaction((txn) async {
      final stored = await _st.bootstrapProgress(txn);
      if (!_same(stored, expected)) {
        throw StateError('bootstrap progress changed under this run');
      }

      final raw = await _st.deferredPullJson(txn);
      final deferred = decodeDeferredPull(
        raw,
        onError: (e, st) =>
            _report(e, st, 'deferred pull changes unreadable; dropped'),
      );
      var dirty = deferred == null;
      final pending = deferred ?? <String, PullChange>{};
      if (deferred == null) await _st.setRepairNeeded(txn);

      final applier = _appliers.of(entity);
      for (final item in page.items) {
        final id = _idOf(item);
        if (id == null) {
          _log('bootstrap $entity item without a usable id skipped');
          continue;
        }
        if (applier == null) continue;
        final v = item['version'];
        final change = PullChange(
          seq: 0,
          entity: entity,
          op: 'upsert',
          id: id,
          version: v is int ? v : null,
          data: item,
        );
        final version = change.version;
        if (version != null) {
          final local = await applier.localVersion(txn, change);
          if (local != null && version <= local) continue; // never roll back
        }
        final key = deferredPullKey(entity, id);
        if (applier.skipWhenLocalPending &&
            await hasLocalPendingOutbox(
              txn,
              entity: entity,
              id: id,
              scope: _scope,
            )) {
          final prev = pending[key];
          // Keep an already deferred change only when it is newer.
          final prevV = prev?.version;
          if (prev == null ||
              prevV == null ||
              version == null ||
              prevV <= version) {
            pending[key] = change;
            dirty = true;
          }
          continue;
        }
        await applier.apply(txn, change);
        touched.addAll(applier.tables);
        applied++;
        if (pending.remove(key) != null) dirty = true;
      }

      await _assertScope(); // throwing rolls the whole page back
      if (dirty) {
        await _st.setDeferredPullJson(txn, encodeDeferredPull(pending));
      }
      final p = page.hasMore
          ? BootstrapProgress(
              snapshotCursor: expected.snapshotCursor,
              entities: expected.entities,
              done: expected.done,
              pageCursor: page.nextPageCursor,
              startedAt: expected.startedAt,
            )
          : BootstrapProgress(
              snapshotCursor: expected.snapshotCursor,
              entities: expected.entities,
              done: [...expected.done, entity],
              startedAt: expected.startedAt,
            );
      await _st.setBootstrapProgress(txn, p);
      return p;
    });
    touched.add(SyncTables.syncState);
    return (next, touched, applied);
  }

  /// Pull cursor = snapshot, scope bootstrapped (+ completion time),
  /// progress removed: ONE transaction. Deferred pulled changes are kept for the next pull.
  Future<void> _finalCommit(
    BootstrapProgress expected,
    Map<String, Set<String>>? seen,
  ) async {
    var restored = const <String>{};
    var swept = const <String>{};
    await (await _db.database).transaction((txn) async {
      final stored = await _st.bootstrapProgress(txn);
      if (!_same(stored, expected) ||
          !expected.entities.every(expected.done.contains)) {
        throw StateError('bootstrap progress not complete at final commit');
      }
      await _assertScope();
      await _st.setCursor(txn, expected.snapshotCursor);
      await _st.setBootstrapped(txn, true);
      await _st.setBootstrapCompletedAt(txn, _now());
      await _st.setBootstrapProgress(txn, null);
      if (seen != null) swept = await _sweepGhosts(txn, expected, seen);
      // M1: catalog rows with unsynced changes that the last logout wiped
      // come back where the bootstrap wrote nothing.
      restored = await CatalogStash.restore(txn, _scope);
    });
    if (restored.isNotEmpty) _notifier.notify(restored);
    if (swept.isNotEmpty) _notifier.notify(swept);
  }

  /// Catalog entities whose server rows are tombstoned, never silently
  /// omitted: a synced local row the full snapshot does not contain is a
  /// ghost (deleted on the server while this device was away, F3).
  static const Set<String> sweepEntities = {'product', 'category', 'vendor'};

  /// Deletes local rows of [sweepEntities] that were synced before (version
  /// set), are absent from the complete snapshot [seen] and have no open
  /// outbox row (never a local-only create or an edit in flight). Goes
  /// through the applier's own delete so counts / assets stay right.
  Future<Set<String>> _sweepGhosts(
    Transaction txn,
    BootstrapProgress done,
    Map<String, Set<String>> seen,
  ) async {
    final touched = <String>{};
    const tables = {
      'product': 'products',
      'category': 'categories',
      'vendor': 'vendors',
    };
    for (final entity in sweepEntities) {
      if (!done.entities.contains(entity)) continue; // not in this snapshot
      final applier = _appliers.of(entity);
      if (applier == null) continue;
      final served = seen[entity] ?? const <String>{};
      final rows = await txn.query(
        tables[entity]!,
        columns: ['id'],
        where: 'version IS NOT NULL',
      );
      for (final r in rows) {
        final id = r['id'] as String;
        if (served.contains(id)) continue;
        final open = await txn.rawQuery(
          'SELECT 1 FROM ${SyncTables.outbox} WHERE entity = ? '
          "AND entity_id = ? AND scope = ? AND status != 'done' LIMIT 1",
          [entity, id, _scope],
        );
        if (open.isNotEmpty) continue;
        await applier.apply(
          txn,
          PullChange(seq: 0, entity: entity, op: 'delete', id: id),
        );
        touched.addAll(applier.tables);
      }
    }
    return touched;
  }

  static String? _idOf(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is String && id.trim().isNotEmpty) return id;
    if (id is int) return '$id';
    return null;
  }

  static bool _same(BootstrapProgress? a, BootstrapProgress b) =>
      a != null &&
      a.snapshotCursor == b.snapshotCursor &&
      a.pageCursor == b.pageCursor &&
      listEquals(a.entities, b.entities) &&
      listEquals(a.done, b.done);

  // ------------------------------------------------------------- guards

  Future<void> _ensureLock() async {
    if (await _state.renewLock(_holder, _lockTtl)) return;
    if (await _state.acquireLock(_holder, _lockTtl)) return;
    throw _Stop(BootstrapOutcome.alreadyRunning);
  }

  /// The run's scope must still be the signed-in one (published scope and
  /// the live session check injected by the caller).
  Future<void> _assertScope() async {
    if (_scopeProvider() != _scope) {
      throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
    }
    await _assertScopeHook();
  }

  BootstrapOutcome _onTransportError(SyncTransportException e) {
    switch (e.kind) {
      case SyncTransportKind.accountDisabled:
        return _finish(
          BootstrapOutcome.blocked,
          block: SyncBlockReason.accountDisabled,
        );
      case SyncTransportKind.deviceRevoked:
        return _finish(
          BootstrapOutcome.blocked,
          block: SyncBlockReason.deviceRevoked,
        );
      case SyncTransportKind.scopeChanged:
        // Session switched: stop quietly, the new scope starts its own.
        return _finish(BootstrapOutcome.interrupted);
      case SyncTransportKind.maintenance:
        return _finish(
          BootstrapOutcome.interrupted,
          block: SyncBlockReason.maintenance,
        );
      case SyncTransportKind.network:
      case SyncTransportKind.timeout:
        return _finish(BootstrapOutcome.interrupted, offline: true);
      case SyncTransportKind.tokenExpired:
      case SyncTransportKind.unauthorized:
      // Refresh impossible or transient: never block, never log out.
      case SyncTransportKind.server:
      case SyncTransportKind.tooLarge:
        _log('bootstrap interrupted: ${e.code ?? e.kind.name}');
        return _finish(BootstrapOutcome.interrupted);
    }
  }

  // ------------------------------------------------------------- status

  BootstrapOutcome _finish(
    BootstrapOutcome outcome, {
    SyncBlockReason? block,
    bool offline = false,
  }) {
    _emit(
      BootstrapStatus(
        outcome: outcome,
        currentEntity: _status.currentEntity,
        entityIndex: _status.entityIndex,
        entityCount: _status.entityCount,
        rowsApplied: _status.rowsApplied,
        offline: offline,
        block: block,
        scope: _status.scope,
      ),
    );
    return outcome;
  }

  void _emit([BootstrapStatus? s]) {
    if (s != null) _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(_status);
  }

  void _log(String msg, [Object? e, StackTrace? st]) =>
      developer.log(msg, name: 'Bootstrapper', error: e, stackTrace: st);

  void _report(Object e, StackTrace st, String context) {
    _log(context, e, st);
    try {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'sync bootstrap',
          context: ErrorDescription(context),
        ),
      );
    } catch (_) {
      // Reporting must never break the bootstrap.
    }
  }
}
