import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../features/inventory/data/local/stock_local_store.dart';
import '../../../features/pos/data/local/sale_local_store.dart';
import '../../offline/offline_db.dart';
import '../db_change_notifier.dart';
import '../sync_schema.dart';
import 'outbox_entry.dart';

class OutboxStore {
  OutboxStore(this._db, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final OfflineDb _db;
  final Uuid _uuid;
  static const SaleLocalStore _sales = SaleLocalStore();
  static const StockLocalStore _stock = StockLocalStore();
  final DateTime Function() _now;

  static const String _t = SyncTables.outbox;

  /// Slack for small clock steps (NTP) in the "clock moved backwards"
  /// checks: a timestamp at most this far beyond its maximum is honoured.
  static const Duration clockSlack = Duration(minutes: 1);

  String _iso(DateTime d) => d.toUtc().toIso8601String();
  String get _nowIso => _iso(_now());

  Future<OutboxEntry> enqueue(
    DatabaseExecutor txn, {
    required String entity,
    required String op,
    required String entityId,
    required Map<String, dynamic> payload,
    required String scope,
    String? dependsOnEntityId,
    int? baseVersion,
    DateTime? occurredAt,
  }) async {
    var status = OutboxStatus.pending;
    if (dependsOnEntityId != null) {
      final open = await txn.rawQuery(
        "SELECT 1 FROM $_t WHERE entity_id = ? AND op = 'create' "
        "AND status != 'done' AND scope = ? LIMIT 1",
        [dependsOnEntityId, scope],
      );
      if (open.isNotEmpty) status = OutboxStatus.blocked;
    }
    final entry = OutboxEntry(
      mutationId: _uuid.v4(),
      entity: entity,
      op: op,
      entityId: entityId,
      dependsOnEntityId: dependsOnEntityId,
      baseVersion: baseVersion,
      occurredAt: (occurredAt ?? _now()).toUtc(),
      payload: payload,
      status: status,
      scope: scope,
    );
    entry.seq = await txn.insert(_t, entry.toRow(createdAt: _now()));
    return entry;
  }

  /// Atomically leases up to [limit] due pending rows. A row is skipped when
  /// any earlier-seq row of the same entity is not `done` (per-entity order),
  /// including rows claimed earlier in this same call.
  ///
  /// [maxRetryDelay]: a `next_attempt_at` further than this in the future can
  /// only come from a clock that moved backwards; such rows are treated as due
  /// so a wrong clock never wedges the queue.
  Future<List<OutboxEntry>> claimBatch({
    required String scope,
    int limit = 100,
    Duration lease = const Duration(minutes: 2),
    Duration? maxRetryDelay,
  }) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = _now();
      final nowIso = _iso(now);
      final leaseIso = _iso(now.add(lease));
      final farIso = maxRetryDelay == null
          ? null
          : _iso(now.add(maxRetryDelay + clockSlack));
      final claimedSeqs = <int>[];
      var lastSeq = 0;
      const window = 500;
      while (claimedSeqs.length < limit) {
        // Lightweight scan: no payload_json, bounded window, paged by seq.
        final candidates = await txn.rawQuery(
          "SELECT seq, entity_id FROM $_t INDEXED BY idx_outbox_scope_status_seq "
          "WHERE status = 'pending' AND scope = ? AND seq > ? AND "
          '(next_attempt_at IS NULL OR next_attempt_at <= ?'
          '${farIso == null ? '' : ' OR next_attempt_at > ?'}) '
          'ORDER BY seq ASC LIMIT ?',
          [scope, lastSeq, nowIso, ?farIso, window],
        );
        if (candidates.isEmpty) break;
        for (final row in candidates) {
          final seq = row['seq'] as int;
          lastSeq = seq;
          if (claimedSeqs.length >= limit) break;
          // Uses idx_outbox_entity_seq (entity_id, seq).
          final blockers = await txn.rawQuery(
            "SELECT 1 FROM $_t WHERE entity_id = ? AND seq < ? "
            "AND status != 'done' AND scope = ? LIMIT 1",
            [row['entity_id'], seq, scope],
          );
          if (blockers.isNotEmpty) continue;
          final n = await txn.update(
            _t,
            {'status': 'inflight', 'lease_until': leaseIso},
            where: "seq = ? AND status = 'pending'",
            whereArgs: [seq],
          );
          if (n == 1) claimedSeqs.add(seq);
        }
        if (candidates.length < window) break;
      }
      final claimed = <OutboxEntry>[];
      for (var i = 0; i < claimedSeqs.length; i += 500) {
        final chunk = claimedSeqs.sublist(
          i,
          i + 500 > claimedSeqs.length ? claimedSeqs.length : i + 500,
        );
        final rows = await txn.query(
          _t,
          where: 'seq IN (${List.filled(chunk.length, '?').join(',')})',
          whereArgs: chunk,
          orderBy: 'seq ASC',
        );
        claimed.addAll(rows.map(OutboxEntry.fromRow));
      }
      return claimed;
    });
  }

  /// Ownership guard shared by result writers: with [leaseUntil] only an
  /// `inflight` row still holding that exact lease is touched.
  (String, List<Object?>) _owned(String mutationId, DateTime? leaseUntil) =>
      leaseUntil == null
      ? ('mutation_id = ?', [mutationId])
      : (
          "mutation_id = ? AND status = 'inflight' AND lease_until = ?",
          [mutationId, _iso(leaseUntil)],
        );

  /// Writes a result. With [leaseUntil] (the lease the caller claimed the row
  /// under) the write only happens if the caller still owns the row.
  /// Returns the number of rows updated (0 = not ours any more).
  Future<int> applyResult(
    DatabaseExecutor txn,
    String mutationId, {
    required OutboxStatus status,
    String? code,
    String? message,
    DateTime? leaseUntil,
  }) {
    final (where, args) = _owned(mutationId, leaseUntil);
    return txn.update(
      _t,
      {
        'status': status.name,
        'error_code': code,
        'error_message': message,
        'lease_until': null,
        'next_attempt_at': null,
      },
      where: where,
      whereArgs: args,
    );
  }

  /// Returns an inflight row to `pending` due at [at], bumping attempts.
  /// Runs on [executor] when given (e.g. inside the results transaction).
  /// With [leaseUntil] only a row still held under that lease is touched.
  Future<int> scheduleRetry(
    String mutationId,
    DateTime at, {
    DatabaseExecutor? executor,
    DateTime? leaseUntil,
  }) async {
    final e = executor ?? await _db.database;
    final (where, args) = _owned(mutationId, leaseUntil);
    return e.rawUpdate(
      "UPDATE $_t SET status = 'pending', attempts = attempts + 1, "
      'next_attempt_at = ?, lease_until = NULL '
      "WHERE $where AND status = 'inflight'",
      [_iso(at), ...args],
    );
  }

  /// Returns a claimed row to `pending` without counting an attempt or
  /// adding backoff (the outbox was not the problem). Guarded like
  /// [applyResult].
  Future<int> releaseClaim(
    String mutationId, {
    DatabaseExecutor? executor,
    DateTime? leaseUntil,
  }) async {
    final e = executor ?? await _db.database;
    final (where, args) = _owned(mutationId, leaseUntil);
    return e.rawUpdate(
      "UPDATE $_t SET status = 'pending', lease_until = NULL "
      "WHERE $where AND status = 'inflight'",
      args,
    );
  }

  /// Deliberately NOT scoped: an expired lease is a crashed-run artefact, and
  /// returning any scope's row to `pending` is harmless (only a run under that
  /// scope can claim it). Scoping it would strand another user's rows.
  ///
  /// Returns inflight rows whose lease expired to `pending`. With [maxLease],
  /// a lease ending later than now + [maxLease] is impossible for a correct
  /// clock (the clock moved backwards) and is treated as expired too.
  Future<int> releaseExpiredLeases({Duration? maxLease}) async {
    final db = await _db.database;
    final far = maxLease == null
        ? null
        : _iso(_now().add(maxLease + clockSlack));
    return db.rawUpdate(
      "UPDATE $_t SET status = 'pending', lease_until = NULL "
      "WHERE status = 'inflight' AND lease_until IS NOT NULL "
      'AND (lease_until < ?${far == null ? '' : ' OR lease_until > ?'})',
      [_nowIso, ?far],
    );
  }

  /// Dependencies are resolved within one [scope] only (see enqueue).
  Future<void> unblockDependents(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
  }) async {
    await txn.update(
      _t,
      {'status': 'pending'},
      where: "status = 'blocked' AND depends_on_entity_id = ? AND scope = ?",
      whereArgs: [entityId, scope],
    );
  }

  /// Rejects dependents (blocked or pending) of [entityId], cascading to
  /// their own dependents. The local stock they affected is recomputed (a
  /// rejected row no longer counts).
  Future<void> failDependents(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
  }) async {
    await _recomputeStock(
      txn,
      await _failDependents(txn, entityId, scope: scope),
    );
  }

  /// [failDependents] without the stock recompute; returns the rows it
  /// rejected.
  Future<List<OutboxEntry>> _failDependents(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
  }) async {
    final failed = <OutboxEntry>[];
    final queue = <String>[entityId];
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!seen.add(id)) continue;
      final rows = await txn.query(
        _t,
        where:
            "depends_on_entity_id = ? AND scope = ? "
            "AND status IN ('blocked','pending')",
        whereArgs: [id, scope],
      );
      for (final r in rows) {
        await txn.update(
          _t,
          {
            'status': 'rejected',
            'error_code': 'dependency_failed',
            'error_message': 'Dependency $id failed',
            'lease_until': null,
          },
          where: 'seq = ?',
          whereArgs: [r['seq']],
        );
        failed.add(OutboxEntry.fromRow(r));
        queue.add(r['entity_id'] as String);
      }
    }
    return failed;
  }

  /// Live count of unconfirmed rows; with [scope] only that session's.
  Stream<int> watchPendingCount(DbChangeNotifier n, {String? scope}) {
    return n.watch<int>(
      tables: {_t},
      query: () async {
        final db = await _db.database;
        final r = await db.rawQuery(
          "SELECT COUNT(*) AS c FROM $_t "
          "WHERE status IN ('pending','inflight','blocked')"
          '${scope == null ? '' : ' AND scope = ?'}',
          [?scope],
        );
        return (r.first['c'] as int?) ?? 0;
      },
    );
  }

  /// Rows waiting to be pushed (`pending` only; inflight/blocked/rejected are
  /// excluded). Used by triggers to ignore outbox notifications that did not
  /// leave anything to push (e.g. the engine's own result writes).
  Future<int> pendingCount({String? scope}) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM $_t WHERE status = 'pending'"
      '${scope == null ? '' : ' AND scope = ?'}',
      [?scope],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Every row the server has not confirmed (anything but `done`, including
  /// `rejected`, which is unsent user data). Zero means the outbox is empty.
  ///
  /// With [scope] only that session's rows are counted.
  Future<int> unsyncedCount({String? scope}) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM $_t WHERE status != 'done'"
      '${scope == null ? '' : ' AND scope = ?'}',
      [?scope],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Rows a user may discard: not sent yet (or answered `rejected`) and
  /// not claimed by a sync run. `inflight` rows (and any row still holding a
  /// lease) may be on the wire right now: discarding one would drop the
  /// server's answer while the server keeps the sale (review I1).
  static const String _discardableSql =
      "status IN ('pending','blocked','rejected') AND lease_until IS NULL";

  /// Explicit, user-confirmed discard of one scope's unsynced rows. Never
  /// called by normal logout / business-switch paths; the UI must confirm
  /// first. Rows being sent (see [_discardableSql]) are kept. In ONE
  /// transaction: local sales of discarded `sale.create` rows are marked
  /// rejected (`discarded`), dependents are failed, and local stock of every
  /// affected (product, shop) is recomputed. Returns the rows deleted.
  Future<int> discardAll({required String scope}) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        _t,
        where: 'scope = ? AND $_discardableSql',
        whereArgs: [scope],
        orderBy: 'seq ASC',
      );
      final removed = <OutboxEntry>[];
      for (final r in rows) {
        final n = await txn.delete(
          _t,
          where: 'seq = ? AND $_discardableSql',
          whereArgs: [r['seq']],
        );
        if (n == 1) removed.add(OutboxEntry.fromRow(r));
      }
      final failed = <OutboxEntry>[];
      for (final e in removed) {
        failed.addAll(await _failDependents(txn, e.entityId, scope: e.scope));
      }
      await _afterRemoved(txn, removed, failed);
      return removed.length;
    });
  }

  /// Every row the server has not confirmed, all scopes, oldest first.
  Future<List<OutboxEntry>> listUnsynced() async {
    final db = await _db.database;
    final rows = await db.query(
      _t,
      where: "status != 'done'",
      orderBy: 'seq ASC',
    );
    return rows.map(OutboxEntry.fromRow).toList();
  }

  Future<List<OutboxEntry>> rejected() async {
    final db = await _db.database;
    final rows = await db.query(
      _t,
      where: "status = 'rejected'",
      orderBy: 'seq ASC',
    );
    return rows.map(OutboxEntry.fromRow).toList();
  }

  /// Puts a `rejected` row back in the queue. In ONE transaction its local
  /// sale (for `sale.create`) goes back from `rejected` to `pending` and the
  /// local stock it affects is recomputed (a rejected row has no stock
  /// effect; a pending one has, exactly once). False when the row is not
  /// `rejected` (any more).
  Future<bool> retryRejected(String mutationId) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        _t,
        where: "mutation_id = ? AND status = 'rejected'",
        whereArgs: [mutationId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final n = await txn.update(
        _t,
        {
          'status': 'pending',
          'attempts': 0,
          'next_attempt_at': null,
          'lease_until': null,
          'error_code': null,
          'error_message': null,
        },
        where: "mutation_id = ? AND status = 'rejected'",
        whereArgs: [mutationId],
      );
      if (n != 1) return false;
      final e = OutboxEntry.fromRow(rows.first);
      if (_isSaleCreate(e)) {
        await _sales.markPendingAgain(txn, e.entityId);
      }
      await _recomputeStock(txn, [e]);
      return true;
    });
  }

  /// User discard of one row (review I1/I2/M4). In ONE transaction:
  /// refuses a row being sent ([DiscardOutcome.sending]) or already
  /// confirmed ([DiscardOutcome.alreadySynced]); otherwise deletes it, marks
  /// its local sale (for `sale.create`) rejected with code `discarded` (the
  /// sale is never deleted: history keeps showing it), fails its dependents
  /// and recomputes the local stock of every affected (product, shop).
  ///
  /// With [currentScope] set, a row of another scope is refused
  /// ([DiscardOutcome.otherScope]); another account's rows go through
  /// [discardAll] after their own confirmation.
  Future<DiscardOutcome> discard(
    String mutationId, {
    String? currentScope,
  }) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        _t,
        where: 'mutation_id = ?',
        whereArgs: [mutationId],
        limit: 1,
      );
      if (rows.isEmpty) return DiscardOutcome.notFound;
      final e = OutboxEntry.fromRow(rows.first);
      if (currentScope != null && e.scope != currentScope) {
        return DiscardOutcome.otherScope;
      }
      if (e.status == OutboxStatus.done) return DiscardOutcome.alreadySynced;
      final n = await txn.delete(
        _t,
        where: 'mutation_id = ? AND $_discardableSql',
        whereArgs: [mutationId],
      );
      if (n != 1) return DiscardOutcome.sending;
      final failed = await _failDependents(txn, e.entityId, scope: e.scope);
      await _afterRemoved(txn, [e], failed);
      return DiscardOutcome.discarded;
    });
  }

  static bool _isSaleCreate(OutboxEntry e) =>
      e.entity == 'sale' && e.op == 'create';

  /// Local consequences of user-removed rows ([removed]) and of the
  /// dependents that failed with them ([failed]).
  Future<void> _afterRemoved(
    DatabaseExecutor txn,
    List<OutboxEntry> removed,
    List<OutboxEntry> failed,
  ) async {
    for (final e in removed) {
      if (!_isSaleCreate(e)) continue;
      await _sales.markRejected(
        txn,
        e.entityId,
        code: e.errorCode ?? 'discarded',
        message: e.errorMessage ?? 'Discarded by user',
      );
    }
    await _recomputeStock(txn, [...removed, ...failed]);
  }

  /// Re-derives local stock (base + remaining open rows) for every
  /// (product, shop) the given rows affect.
  Future<void> _recomputeStock(
    DatabaseExecutor txn,
    Iterable<OutboxEntry> rows,
  ) async {
    final pairs = <(String, String)>{
      for (final e in rows)
        ...StockLocalStore.affectedByOutboxRow(e.entity, e.op, e.payload),
    };
    for (final (product, shop) in pairs) {
      await _stock.recompute(txn, product, shop);
    }
  }

  /// Removes `done` rows older than [keep] (default 7 days). Returns count.
  Future<int> pruneDone({Duration keep = const Duration(days: 7)}) async {
    final db = await _db.database;
    final cutoff = _iso(_now().subtract(keep));
    return db.delete(
      _t,
      where: "status = 'done' AND created_at < ?",
      whereArgs: [cutoff],
    );
  }
}

/// Result of [OutboxStore.discard].
enum DiscardOutcome {
  discarded,

  /// No such row (already gone).
  notFound,

  /// Claimed by a sync run (may be on the wire): kept.
  sending,

  /// The server already confirmed it: kept.
  alreadySynced,

  /// Another account's row while a current scope was given: kept.
  otherScope,
}
