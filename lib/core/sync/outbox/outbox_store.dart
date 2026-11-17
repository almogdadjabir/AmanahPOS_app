import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../features/inventory/data/local/stock_local_store.dart';
import '../../../features/pos/data/local/sale_local_store.dart';
import '../../offline/offline_db.dart';
import '../catalog_support.dart';
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

  /// Catalog entities whose rejected `update`/`delete` never holds later
  /// rows of the same row (claimBatch).
  static const Set<String> catalogEntities = {'category', 'product', 'vendor'};
  static final String _catalogIn = catalogEntities.map((e) => "'$e'").join(',');

  /// Slack for small clock steps (NTP) in the "clock moved backwards"
  /// checks: a timestamp at most this far beyond its maximum is honoured.
  static const Duration clockSlack = Duration(minutes: 1);

  String _iso(DateTime d) => d.toUtc().toIso8601String();
  String get _nowIso => _iso(_now());

  /// Inserts a row. [dependsOn]: entity ids this row needs on the server
  /// first (e.g. a sale's products). Only those with an open `create` in
  /// [scope] (see [openCreateIds]) are stored; the row starts `blocked` when
  /// any is. Ids with no open create (unknown, server-side, already `done`)
  /// are dropped.
  Future<OutboxEntry> enqueue(
    DatabaseExecutor txn, {
    required String entity,
    required String op,
    required String entityId,
    required Map<String, dynamic> payload,
    required String scope,
    List<String> dependsOn = const [],
    int? baseVersion,
    DateTime? occurredAt,
  }) async {
    final deps = <String>[
      ...{
        for (final d in dependsOn)
          if (d.trim().isNotEmpty && d.trim() != entityId) d.trim(),
      },
    ];
    // Only ids whose create is still open are recorded (spec): a done or
    // server-side entity can never block or fail this row later.
    final open = await openCreateIds(txn, deps, scope: scope);
    final entry = OutboxEntry(
      mutationId: _uuid.v4(),
      entity: entity,
      op: op,
      entityId: entityId,
      dependsOn: [
        for (final d in deps)
          if (open.contains(d)) d,
      ],
      baseVersion: baseVersion,
      occurredAt: (occurredAt ?? _now()).toUtc(),
      payload: payload,
      status: open.isEmpty ? OutboxStatus.pending : OutboxStatus.blocked,
      scope: scope,
    );
    entry.seq = await txn.insert(_t, entry.toRow(createdAt: _now()));
    return entry;
  }

  /// The subset of [ids] that has an open `create` in [scope]. "Open" = not
  /// `done`: a `rejected` create still counts (the user may retry it; a
  /// dependent sent before it would be saved with a NULL reference).
  Future<Set<String>> openCreateIds(
    DatabaseExecutor txn,
    Iterable<String> ids, {
    required String scope,
  }) async {
    final list = ids.toSet().toList();
    final open = <String>{};
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(
        i,
        i + 500 > list.length ? list.length : i + 500,
      );
      final rows = await txn.rawQuery(
        'SELECT DISTINCT entity_id FROM $_t '
        "WHERE op = 'create' AND status != 'done' AND scope = ? "
        'AND entity_id IN (${List.filled(chunk.length, '?').join(',')})',
        [scope, ...chunk],
      );
      open.addAll(rows.map((r) => r['entity_id'] as String));
    }
    return open;
  }

  /// Rows of [scope] whose `depends_on_json` lists [entityId] and whose
  /// status is one of [statuses]. The LIKE on the quoted id only narrows
  /// the scan; the list is decoded and matched exactly.
  Future<List<Map<String, Object?>>> _dependentsOf(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
    required List<String> statuses,
  }) async {
    final rows = await txn.rawQuery(
      'SELECT * FROM $_t WHERE scope = ? '
      'AND status IN (${List.filled(statuses.length, '?').join(',')}) '
      "AND depends_on_json LIKE ? ESCAPE '\\' ORDER BY seq ASC",
      [scope, ...statuses, '%${_likeEscape(jsonEncode(entityId))}%'],
    );
    return [
      for (final r in rows)
        if (OutboxEntry.decodeDependsOn(
          r['depends_on_json'],
        ).contains(entityId))
          r,
    ];
  }

  static String _likeEscape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

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
          // Uses idx_outbox_entity_seq (entity_id, seq). A rejected
          // catalog update/delete does not hold later rows of its row
          // ([catalogEntities]; ruling I2): they carry their own
          // base_version and the BE merges field-wise. Every other rejected
          // row (a create, any sale/stock/inbound row) still holds them,
          // except a rejected `sale.refund`: refunds are independent and
          // append-only, a voided one must not strand later refunds of the
          // same sale (Phase 4).
          final blockers = await txn.rawQuery(
            "SELECT 1 FROM $_t WHERE entity_id = ? AND seq < ? "
            "AND status != 'done' AND scope = ? "
            "AND NOT (status = 'rejected' AND ("
            "(op IN ('update','delete') AND entity IN ($_catalogIn)) "
            "OR (op = 'refund' AND entity = 'sale'))) LIMIT 1",
            [row['entity_id'], seq, scope],
          );
          if (blockers.isNotEmpty) continue;
          // `claimed_at` is sticky: once claimed, the row may have reached
          // the server (see CatalogSupport.dropNeverSentCreate).
          final n = await txn.rawUpdate(
            "UPDATE $_t SET status = 'inflight', lease_until = ?, "
            'claimed_at = COALESCE(claimed_at, ?) '
            "WHERE seq = ? AND status = 'pending'",
            [leaseIso, nowIso, seq],
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
  /// [errorEntityId]: the server's `conflict_entity_id` (stored in
  /// `error_entity_id`; null clears it).
  /// Returns the number of rows updated (0 = not ours any more).
  Future<int> applyResult(
    DatabaseExecutor txn,
    String mutationId, {
    required OutboxStatus status,
    String? code,
    String? message,
    String? errorEntityId,
    String? failedBy,
    DateTime? leaseUntil,
  }) {
    final (where, args) = _owned(mutationId, leaseUntil);
    return txn.update(
      _t,
      {
        'status': status.name,
        'error_code': code,
        'error_message': message,
        'error_entity_id': errorEntityId,
        'failed_by_entity_id': failedBy,
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

  /// Called once [entityId]'s create is `done`. Each `blocked` dependent of
  /// it flips to `pending` only when none of its other dependencies still
  /// has an open create. Dependencies are resolved within one [scope] only
  /// (see enqueue).
  Future<void> unblockDependents(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
  }) async {
    final rows = await _dependentsOf(
      txn,
      entityId,
      scope: scope,
      statuses: const ['blocked'],
    );
    for (final r in rows) {
      final deps = OutboxEntry.decodeDependsOn(r['depends_on_json']);
      if ((await openCreateIds(txn, deps, scope: scope)).isNotEmpty) continue;
      await txn.update(
        _t,
        {'status': 'pending'},
        where: "seq = ? AND status = 'blocked'",
        whereArgs: [r['seq']],
      );
    }
  }

  /// Whether a failed / discarded row [e] must fail the rows waiting on its
  /// entity: only a `create` can be a dependency. A rejected or discarded
  /// `update`/`delete` of a product never fails the sales naming it (C1).
  static bool failsDependents(OutboxEntry e) => e.op == 'create';

  /// Rejects dependents (blocked or pending) of [entityId], whose `create`
  /// failed, cascading to the dependents of every failed `create`. The
  /// LATER rows of the same entity (an edit or delete queued behind the
  /// create) are failed too: without their create they can never be sent
  /// (Review Focus 2). Callers guard with [failsDependents]. The local stock
  /// they affected is recomputed (a rejected row no longer counts).
  ///
  /// Every row failed here carries `error_code` `dependency_failed` and
  /// `error_message` [dependencyFailedMessage] of the id that failed it;
  /// [retryRejected] uses that to revive them.
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

  /// `error_message` of a row failed because the create of [entityId] failed.
  static String dependencyFailedMessage(String entityId) =>
      'Dependency $entityId failed';

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
      final rows = [
        ...await txn.query(
          _t,
          where:
              "entity_id = ? AND scope = ? AND status IN ('blocked','pending')",
          whereArgs: [id, scope],
          orderBy: 'seq ASC',
        ),
        ...await _dependentsOf(
          txn,
          id,
          scope: scope,
          statuses: const ['blocked', 'pending'],
        ),
      ];
      final done = <Object?>{};
      for (final r in rows) {
        if (!done.add(r['seq'])) continue;
        await txn.update(
          _t,
          {
            'status': 'rejected',
            'error_code': 'dependency_failed',
            'error_message': dependencyFailedMessage(id),
            'error_entity_id': null,
            'failed_by_entity_id': id,
            'lease_until': null,
          },
          where: 'seq = ?',
          whereArgs: [r['seq']],
        );
        final fe = OutboxEntry.fromRow(r);
        failed.add(fe);
        if (_isRefund(fe)) {
          await _refundState(
            txn,
            fe,
            'rejected',
            code: 'dependency_failed',
            message: dependencyFailedMessage(id),
          );
        }
        // Only a failed create is itself a dependency.
        if (r['op'] == 'create') queue.add(r['entity_id'] as String);
      }
    }
    return failed;
  }

  /// M1: after the create of [entityId] went back to the queue, revives the
  /// rows [failDependents] failed because of it (matched by
  /// [dependencyFailedMessage]), recursively through revived creates. A row
  /// becomes `blocked` while any dependency create is still open, else
  /// `pending`. Best effort and conservative: a row listing another
  /// dependency that no longer has any create row in [scope] (discarded, or
  /// done and pruned: indistinguishable) stays rejected; the user can retry
  /// it by hand. Returns the revived rows.
  Future<List<OutboxEntry>> _reviveDependents(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
  }) async {
    final revived = <OutboxEntry>[];
    final queue = <String>[entityId];
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!seen.add(id)) continue;
      // M9: matched by `failed_by_entity_id`; the message text only for
      // rows failed before the column existed.
      final rows = await txn.query(
        _t,
        where:
            "scope = ? AND status = 'rejected' AND error_code = ? "
            'AND (failed_by_entity_id = ? OR '
            '(failed_by_entity_id IS NULL AND error_message = ?))',
        whereArgs: [
          scope,
          'dependency_failed',
          id,
          dependencyFailedMessage(id),
        ],
        orderBy: 'seq ASC',
      );
      for (final r in rows) {
        final e = OutboxEntry.fromRow(r);
        final others = e.dependsOn.where((d) => d != id).toList();
        if (others.isNotEmpty &&
            (await _withCreateRow(txn, others, scope: scope)).length !=
                others.toSet().length) {
          continue;
        }
        final status = await _queuedStatus(txn, e);
        await txn.update(
          _t,
          {
            'status': status.name,
            'attempts': 0,
            'next_attempt_at': null,
            'lease_until': null,
            'error_code': null,
            'error_message': null,
            'error_entity_id': null,
            'failed_by_entity_id': null,
          },
          where: "seq = ? AND status = 'rejected'",
          whereArgs: [e.seq],
        );
        if (_isSaleCreate(e)) await _sales.markPendingAgain(txn, e.entityId);
        if (_isRefund(e)) await _refundState(txn, e, 'pending');
        revived.add(e);
        if (e.op == 'create') queue.add(e.entityId);
      }
    }
    return revived;
  }

  /// The subset of [ids] that has a `create` row (any status) in [scope].
  Future<Set<String>> _withCreateRow(
    DatabaseExecutor txn,
    List<String> ids, {
    required String scope,
  }) async {
    final rows = await txn.rawQuery(
      'SELECT DISTINCT entity_id FROM $_t '
      "WHERE op = 'create' AND scope = ? "
      'AND entity_id IN (${List.filled(ids.length, '?').join(',')})',
      [scope, ...ids],
    );
    return rows.map((r) => r['entity_id'] as String).toSet();
  }

  /// `blocked` while any of [e]'s dependency creates is open, else `pending`.
  Future<OutboxStatus> _queuedStatus(
    DatabaseExecutor txn,
    OutboxEntry e,
  ) async =>
      e.dependsOn.isNotEmpty &&
          (await openCreateIds(txn, e.dependsOn, scope: e.scope)).isNotEmpty
      ? OutboxStatus.blocked
      : OutboxStatus.pending;

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
        if (!failsDependents(e)) continue;
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
  /// effect; a pending one has, exactly once). A row whose dependency create
  /// is still open goes back `blocked`, never `pending` (it would be sent
  /// before its create). Retrying a `create` also revives the rows that
  /// were failed with `dependency_failed` because of it (see
  /// [_reviveDependents]). False when the row is not `rejected` (any more).
  Future<bool> retryRejected(String mutationId) async {
    final db = await _db.database;
    return db.transaction((txn) => retryRejectedIn(txn, mutationId));
  }

  /// [retryRejected] in the caller's transaction (e.g. a `LocalWriter`
  /// body: "Edit and retry" folds the edit into the row first).
  Future<bool> retryRejectedIn(DatabaseExecutor txn, String mutationId) async {
    final rows = await txn.query(
      _t,
      where: "mutation_id = ? AND status = 'rejected'",
      whereArgs: [mutationId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final e = OutboxEntry.fromRow(rows.first);
    final n = await txn.update(
      _t,
      {
        'status': (await _queuedStatus(txn, e)).name,
        'attempts': 0,
        'next_attempt_at': null,
        'lease_until': null,
        'error_code': null,
        'error_message': null,
        'error_entity_id': null,
        'failed_by_entity_id': null,
      },
      where: "mutation_id = ? AND status = 'rejected'",
      whereArgs: [mutationId],
    );
    if (n != 1) return false;
    if (_isSaleCreate(e)) {
      await _sales.markPendingAgain(txn, e.entityId);
    }
    if (_isRefund(e)) await _refundState(txn, e, 'pending');
    final revived = failsDependents(e)
        ? await _reviveDependents(txn, e.entityId, scope: e.scope)
        : const <OutboxEntry>[];
    await _recomputeStock(txn, [e, ...revived]);
    return true;
  }

  /// "Merge into existing" (`CatalogConflictService.mergeInto`), in the
  /// caller's transaction; the caller has already deleted the rows of the
  /// dropped entity itself. Every row of [scope] naming [oldId] is
  /// rewritten: payload values equal to [oldId] become [newId] (any JSON
  /// path), [oldId] leaves `depends_on_json` (the server row [newId] is
  /// never a dependency), the legacy `depends_on_entity_id` is cleared and
  /// `error_entity_id` / `error_message` follow. Rows that waited on, or were
  /// failed by, the dropped create go back to the queue (`blocked` while
  /// another dependency create is open, else `pending`; see
  /// [_reviveDependents]). The caller recomputes the local stock of the
  /// returned [requeued] rows (their payloads already hold [newId]).
  Future<({int rewritten, List<OutboxEntry> requeued})> rekeyForMerge(
    DatabaseExecutor txn,
    String oldId,
    String newId, {
    required String scope,
  }) async {
    final like = '%${_likeEscape(oldId)}%';
    final rows = await txn.rawQuery(
      'SELECT * FROM $_t WHERE scope = ? AND ('
      "payload_json LIKE ? ESCAPE '\\' OR depends_on_json LIKE ? ESCAPE '\\' "
      'OR depends_on_entity_id = ? OR error_entity_id = ?) ORDER BY seq ASC',
      [scope, like, like, oldId, oldId],
    );
    final touched = <int>[];
    for (final r in rows) {
      final payload = CatalogSupport.replaceIdDeep(
        jsonDecode(r['payload_json'] as String),
        oldId,
        newId,
      );
      final deps = [
        for (final d in OutboxEntry.decodeDependsOn(r['depends_on_json']))
          if (d != oldId) d,
      ];
      await txn.update(
        _t,
        {
          'payload_json': jsonEncode(payload),
          'depends_on_json': deps.isEmpty ? null : jsonEncode(deps),
          if (r['depends_on_entity_id'] == oldId) 'depends_on_entity_id': null,
          if (r['error_entity_id'] == oldId) 'error_entity_id': newId,
        },
        where: 'seq = ?',
        whereArgs: [r['seq']],
      );
      touched.add(r['seq'] as int);
    }
    final requeued = <int, OutboxEntry>{
      for (final e in await _reviveDependents(txn, oldId, scope: scope))
        e.seq!: e,
    };
    // Rows queued after the rejection still wait `blocked` on [oldId].
    for (final seq in touched) {
      final r = await txn.query(
        _t,
        where: "seq = ? AND status = 'blocked'",
        whereArgs: [seq],
      );
      if (r.isEmpty) continue;
      final e = OutboxEntry.fromRow(r.first);
      final status = await _queuedStatus(txn, e);
      if (status == OutboxStatus.pending) {
        await txn.update(
          _t,
          {'status': status.name},
          where: "seq = ? AND status = 'blocked'",
          whereArgs: [seq],
        );
      }
      requeued[seq] = e;
    }
    // Rows that stay rejected now wait on the surviving id.
    await txn.rawUpdate(
      'UPDATE $_t SET failed_by_entity_id = ? '
      'WHERE scope = ? AND failed_by_entity_id = ?',
      [newId, scope, oldId],
    );
    // Rows that stay rejected keep a readable reason naming the new id.
    await txn.rawUpdate(
      'UPDATE $_t SET error_message = REPLACE(error_message, ?, ?) '
      "WHERE scope = ? AND error_message LIKE ? ESCAPE '\\'",
      [oldId, newId, scope, like],
    );
    final fresh = <OutboxEntry>[];
    for (final seq in requeued.keys) {
      final r = await txn.query(_t, where: 'seq = ?', whereArgs: [seq]);
      if (r.isNotEmpty) fresh.add(OutboxEntry.fromRow(r.first));
    }
    return (rewritten: touched.length, requeued: fresh);
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
      final failed = failsDependents(e)
          ? await _failDependents(txn, e.entityId, scope: e.scope)
          : const <OutboxEntry>[];
      await _afterRemoved(txn, [e], failed);
      return DiscardOutcome.discarded;
    });
  }

  static bool _isSaleCreate(OutboxEntry e) =>
      e.entity == 'sale' && e.op == 'create';

  static bool _isRefund(OutboxEntry e) =>
      e.entity == 'sale' && e.op == 'refund';

  /// Keeps the local refund (`sale_refunds.reference` = payload
  /// `reference`) in step with its outbox row when the OUTBOX settles it
  /// outside a push result: voided (`rejected`) when it is failed by a
  /// dependency or discarded, `pending` again when revived / retried. The
  /// sale status is recomputed from the non-voided refunds.
  Future<void> _refundState(
    DatabaseExecutor txn,
    OutboxEntry e,
    String state, {
    String? code,
    String? message,
  }) async {
    final ref = e.payload['reference'];
    if (ref is! String) return;
    await txn.update(
      'sale_refunds',
      {'sync_state': state, 'error_code': code, 'error_message': message},
      where: 'sale_id = ? AND reference = ?',
      whereArgs: [e.entityId, ref],
    );
    await _sales.recomputeRefundStatus(txn, e.entityId);
  }

  /// Local consequences of user-removed rows ([removed]) and of the
  /// dependents that failed with them ([failed]).
  Future<void> _afterRemoved(
    DatabaseExecutor txn,
    List<OutboxEntry> removed,
    List<OutboxEntry> failed,
  ) async {
    for (final e in removed) {
      if (_isRefund(e)) {
        await _refundState(
          txn,
          e,
          'rejected',
          code: e.errorCode ?? 'discarded',
          message: e.errorMessage ?? 'Discarded by user',
        );
        continue;
      }
      if (e.entity == 'customer' && e.op == 'create') {
        // A never-sent customer the user discarded leaves no ghost row.
        await txn.delete(
          'customers',
          where: 'id = ? AND version IS NULL',
          whereArgs: [e.entityId],
        );
        continue;
      }
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

  /// A catalog create other rows wait on (sales, stock, inbound, products
  /// of a category, child categories): kept (fix-wave I3, ruling R7). The
  /// user merges it or edits and retries it.
  hasDependents,

  /// A catalog create that was claimed by a sync run and never answered:
  /// the server may hold it, so dropping it locally would be undone by the
  /// next pull (review M8). Kept; "Send now" settles it.
  mayBeOnServer,
}
