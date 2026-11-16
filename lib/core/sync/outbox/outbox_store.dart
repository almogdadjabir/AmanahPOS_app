import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
    String? dependsOnEntityId,
    int? baseVersion,
    DateTime? occurredAt,
  }) async {
    var status = OutboxStatus.pending;
    if (dependsOnEntityId != null) {
      final open = await txn.rawQuery(
        "SELECT 1 FROM $_t WHERE entity_id = ? AND op = 'create' "
        "AND status != 'done' LIMIT 1",
        [dependsOnEntityId],
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
          "SELECT seq, entity_id FROM $_t INDEXED BY idx_outbox_status_seq "
          "WHERE status = 'pending' AND seq > ? AND "
          '(next_attempt_at IS NULL OR next_attempt_at <= ?'
          '${farIso == null ? '' : ' OR next_attempt_at > ?'}) '
          'ORDER BY seq ASC LIMIT ?',
          [lastSeq, nowIso, ?farIso, window],
        );
        if (candidates.isEmpty) break;
        for (final row in candidates) {
          final seq = row['seq'] as int;
          lastSeq = seq;
          if (claimedSeqs.length >= limit) break;
          // Uses idx_outbox_entity_seq (entity_id, seq).
          final blockers = await txn.rawQuery(
            "SELECT 1 FROM $_t WHERE entity_id = ? AND seq < ? "
            "AND status != 'done' LIMIT 1",
            [row['entity_id'], seq],
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

  Future<void> unblockDependents(DatabaseExecutor txn, String entityId) async {
    await txn.update(
      _t,
      {'status': 'pending'},
      where: "status = 'blocked' AND depends_on_entity_id = ?",
      whereArgs: [entityId],
    );
  }

  /// Rejects dependents (blocked or pending) of [entityId], cascading to
  /// their own dependents.
  Future<void> failDependents(DatabaseExecutor txn, String entityId) async {
    final queue = <String>[entityId];
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!seen.add(id)) continue;
      final rows = await txn.query(
        _t,
        columns: ['seq', 'entity_id'],
        where: "depends_on_entity_id = ? AND status IN ('blocked','pending')",
        whereArgs: [id],
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
        queue.add(r['entity_id'] as String);
      }
    }
  }

  Stream<int> watchPendingCount(DbChangeNotifier n) {
    return n.watch<int>(
      tables: {_t},
      query: () async {
        final db = await _db.database;
        final r = await db.rawQuery(
          "SELECT COUNT(*) AS c FROM $_t "
          "WHERE status IN ('pending','inflight','blocked')",
        );
        return (r.first['c'] as int?) ?? 0;
      },
    );
  }

  /// Rows waiting to be pushed (`pending` only; inflight/blocked/rejected are
  /// excluded). Used by triggers to ignore outbox notifications that did not
  /// leave anything to push (e.g. the engine's own result writes).
  Future<int> pendingCount() async {
    final db = await _db.database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM $_t WHERE status = 'pending'",
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Every row the server has not confirmed (anything but `done`, including
  /// `rejected`, which is unsent user data). Zero means the outbox is empty.
  Future<int> unsyncedCount() async {
    final db = await _db.database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM $_t WHERE status != 'done'",
    );
    return (r.first['c'] as int?) ?? 0;
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

  Future<void> retryRejected(String mutationId) async {
    final db = await _db.database;
    await db.update(
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
  }

  Future<void> discard(String mutationId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        _t,
        columns: ['entity_id'],
        where: 'mutation_id = ?',
        whereArgs: [mutationId],
      );
      if (rows.isEmpty) return;
      final entityId = rows.first['entity_id'] as String;
      await txn.delete(_t, where: 'mutation_id = ?', whereArgs: [mutationId]);
      await failDependents(txn, entityId);
    });
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
