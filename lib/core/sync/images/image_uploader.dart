import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:sqflite/sqflite.dart';

import '../../offline/offline_db.dart';
import '../appliers/applier_support.dart';
import '../assets/asset_sync.dart';
import '../db_change_notifier.dart';
import '../sync_engine.dart';
import '../sync_schema.dart';
import '../transport/image_upload_transport.dart';
import '../transport/sync_transport.dart';
import 'pending_upload_store.dart';

/// Outcome of one [ImageUploader.run].
class ImageUploadReport {
  const ImageUploadReport({
    this.uploaded = 0,
    this.failed = 0,
    this.retrying = 0,
    this.waiting = 0,
    this.cancelled = 0,
    this.stopped = false,
    this.skipped = false,
  });

  /// Another run was in flight (single flight): this one did nothing.
  const ImageUploadReport.skippedRun() : this(skipped: true);

  /// Sent and adopted locally.
  final int uploaded;

  /// Parked as `failed` (403/404/413/400, unreadable file).
  final int failed;

  /// Transient failure: backed off, file kept, retried later.
  final int retrying;

  /// Not eligible yet: the entity has an open outbox row (or a rejected
  /// create).
  final int waiting;

  /// The entity (or its create) is gone: row and file removed.
  final int cancelled;

  /// The run stopped early (session ended / auth refused / scope changed /
  /// server unreachable). Rows not reached are untouched.
  final bool stopped;
  final bool skipped;

  @override
  String toString() =>
      'ImageUploadReport(uploaded: $uploaded, failed: $failed, '
      'retrying: $retrying, waiting: $waiting, cancelled: $cancelled'
      '${stopped ? ', stopped' : ''}${skipped ? ', skipped' : ''})';
}

/// Sends staged catalog images (`pending_uploads`, Task 4) with the BE image
/// PUT (`ImageUploadTransport`). FOREGROUND ONLY: started by `SyncTriggers`
/// after a sync run that ended `completed`, on app resume and on
/// connectivity regained, while the server answers; never by the OS
/// background worker. Fire-and-forget for its callers: it never changes a
/// sync outcome and never logs anybody out.
///
/// Eligibility (per `due(scope)` row): the entity row exists locally and has
/// NO open outbox row of its own (`pending`/`inflight`/`blocked`), i.e. the
/// server row exists at the version this device knows. A `rejected` create
/// parks it (waiting) until the create is retried or discarded. An entity
/// row that is gone, or a never-synced row (`version` NULL) without any
/// create row, cancels the upload and deletes its file.
///
/// Success (200, `data` with `image`, `thumbnail_url`, `version`): ONE
/// transaction updates the entity row (image columns / json, `version`
/// only when newer than the stored one, `image_hash` = the local sha256 as
/// the change token, `server_json`), registers the served image for
/// `AssetSync`, and deletes the upload row; the staged file is deleted after
/// the commit. A same-bytes replay is a server no-op (`unchanged`), so a
/// lost response followed by a retry leaves exactly one server image.
///
/// Errors: network / timeout / 5xx / 429 / maintenance -> back off
/// ([AssetSync.backoffFor], 1 min doubling to 24 h), never give up, keep
/// the file, stop the run; 400 `hash_mismatch` -> recompute the sha256 from
/// the file, store it when it differs and retry ONCE, a second mismatch
/// backs off; any other 400 / 403 / 404 / 413 / unreadable file -> parked
/// `failed` with `last_error` ([retryFailed] from the pending-sync screen);
/// 401 `token_expired` -> one refresh through the engine's [authedFor]
/// helper; any 401 that remains, `account_disabled`, `device_revoked`, a
/// rejected refresh or a scope change -> the run stops quietly with the row
/// untouched (the session guard owns the session).
///
/// Orphan staged files are swept ([PendingUploadStore.sweepOrphans]) at most
/// once per [sweepInterval].
class ImageUploader {
  ImageUploader({
    required OfflineDb db,
    required PendingUploadStore store,
    required ImageUploadTransport transport,
    required DbChangeNotifier notifier,
    required String? Function() scopeProvider,
    required AuthedCall Function(String scope) authedFor,
    DateTime Function()? now,
    this.maxPerRun = 20,
    this.sweepInterval = const Duration(hours: 1),
  }) : _db = db,
       _store = store,
       _transport = transport,
       _notifier = notifier,
       _scope = scopeProvider,
       _authedFor = authedFor,
       _now = now ?? DateTime.now;

  final OfflineDb _db;
  final PendingUploadStore _store;
  final ImageUploadTransport _transport;
  final DbChangeNotifier _notifier;
  final String? Function() _scope;
  final AuthedCall Function(String scope) _authedFor;
  final DateTime Function() _now;

  /// Uploads attempted per run at most (the rest wait for the next one).
  final int maxPerRun;
  final Duration sweepInterval;

  bool _running = false;
  DateTime? _lastSweep;

  /// Entity -> local table.
  static const Map<String, String> tableOf = {
    'product': 'products',
    'category': 'categories',
  };

  static const Set<String> _openStatuses = {'pending', 'inflight', 'blocked'};

  Future<ImageUploadReport> run() async {
    if (_running) return const ImageUploadReport.skippedRun();
    final scope = _scope();
    if (scope == null) return const ImageUploadReport();
    _running = true;
    try {
      return await _run(scope);
    } finally {
      _running = false;
    }
  }

  /// Puts a `failed` upload of the current scope back to `waiting` (due
  /// now). Returns whether one was reset. The next trigger sends it.
  Future<bool> retryFailed(String entity, String entityId) async {
    final scope = _scope();
    if (scope == null) return false;
    final db = await _db.database;
    final ok = await _store.retryFailed(db, entity, entityId, scope: scope);
    if (ok) _notifier.notify(const {SyncTables.pendingUploads});
    return ok;
  }

  Future<ImageUploadReport> _run(String scope) async {
    final db = await _db.database;
    await _maybeSweep(db);

    final due = await _store.due(db, scope: scope, now: _now());
    final authed = _authedFor(scope);
    var uploaded = 0, failed = 0, retrying = 0, waiting = 0, cancelled = 0;
    var stopped = false;
    var attempted = 0;

    for (final u in due) {
      if (_scope() != scope) {
        stopped = true;
        break;
      }
      final table = tableOf[u.entity];
      if (table == null) {
        await _cancel(db, u);
        cancelled++;
        continue;
      }
      switch (await _eligibility(db, table, u)) {
        case _Eligibility.wait:
          waiting++;
          continue;
        case _Eligibility.cancel:
          await _cancel(db, u);
          cancelled++;
          continue;
        case _Eligibility.go:
          break;
      }
      if (attempted >= maxPerRun) break;
      attempted++;

      final o = await _uploadOne(db, table, u, scope, authed);
      switch (o) {
        case _Outcome.uploaded:
          uploaded++;
        case _Outcome.failed:
          failed++;
        case _Outcome.retry:
          retrying++;
        case _Outcome.retryStop:
          retrying++;
          stopped = true;
        case _Outcome.stop:
          stopped = true;
        case _Outcome.replaced:
          break;
      }
      if (stopped) break;
    }
    return ImageUploadReport(
      uploaded: uploaded,
      failed: failed,
      retrying: retrying,
      waiting: waiting,
      cancelled: cancelled,
      stopped: stopped,
    );
  }

  Future<_Eligibility> _eligibility(
    Database db,
    String table,
    PendingUpload u,
  ) async {
    final row = await db.query(
      table,
      columns: ['version'],
      where: 'id = ?',
      whereArgs: [u.entityId],
      limit: 1,
    );
    if (row.isEmpty) return _Eligibility.cancel;
    final own = await db.query(
      'outbox',
      columns: ['op', 'status'],
      where: 'scope = ? AND entity = ? AND entity_id = ?',
      whereArgs: [u.scope, u.entity, u.entityId],
    );
    var hasCreate = false;
    for (final r in own) {
      final status = r['status'] as String?;
      final op = r['op'] as String?;
      if (_openStatuses.contains(status)) return _Eligibility.wait;
      if (op == 'create') {
        hasCreate = true;
        if (status == 'rejected') return _Eligibility.wait;
      }
    }
    // Never synced and no create left (dropped / discarded): the server
    // will never have this row.
    if (row.first['version'] == null && !hasCreate) {
      return _Eligibility.cancel;
    }
    return _Eligibility.go;
  }

  Future<_Outcome> _uploadOne(
    Database db,
    String table,
    PendingUpload u,
    String scope,
    AuthedCall authed,
  ) async {
    List<int> bytes;
    try {
      bytes = await File(u.localPath).readAsBytes();
    } on FileSystemException catch (e) {
      _log('${u.entity}/${u.entityId}: staged file unreadable: $e');
      return _park(db, u, 'file_unreadable');
    }
    var sha = u.sha256;
    var rehashed = false;
    while (true) {
      try {
        final r = await authed(
          () => _transport.putImage(
            entity: u.entity,
            entityId: u.entityId,
            bytes: bytes,
            sha256: sha,
            scope: scope,
          ),
        );
        // The session changed while the request was out: write nothing
        // under the new scope (the next run of the old scope redoes it; a
        // replay of the same bytes is a server no-op).
        if (_scope() != scope) return _Outcome.stop;
        return await _adopt(db, table, u, r, sha);
      } on SyncBlockedException catch (e) {
        _log('${u.entity}/${u.entityId}: stopped ($e)');
        return _Outcome.stop;
      } on SyncTransportException catch (e) {
        if (_scope() != scope) return _Outcome.stop;
        switch (_classify(e)) {
          case _Err.hashMismatch:
            if (rehashed) return _retry(db, u, e, stop: false);
            rehashed = true;
            final actual = crypto.sha256.convert(bytes).toString();
            if (actual != sha) {
              sha = actual;
              await _store.updateHash(
                db,
                u,
                sha256: actual,
                bytes: bytes.length,
              );
            }
            continue;
          case _Err.park:
            return _park(db, u, _describe(e));
          case _Err.transient:
            return _retry(db, u, e, stop: true);
          case _Err.stop:
            _log('${u.entity}/${u.entityId}: stopped ($e)');
            return _Outcome.stop;
        }
      } catch (e, st) {
        if (_scope() != scope) return _Outcome.stop;
        // Unexpected (malformed answer, DB error): back off, never loop.
        _log('${u.entity}/${u.entityId}: failed: $e\n$st');
        return _retry(db, u, e, stop: false);
      }
    }
  }

  _Err _classify(SyncTransportException e) {
    switch (e.kind) {
      case SyncTransportKind.network:
      case SyncTransportKind.timeout:
      case SyncTransportKind.maintenance:
        return _Err.transient;
      case SyncTransportKind.tooLarge:
        return _Err.park;
      case SyncTransportKind.unauthorized:
      case SyncTransportKind.tokenExpired:
      case SyncTransportKind.accountDisabled:
      case SyncTransportKind.deviceRevoked:
      case SyncTransportKind.scopeChanged:
        return _Err.stop;
      case SyncTransportKind.server:
        final s = e.httpStatus;
        if (s == 400 && e.code == 'hash_mismatch') return _Err.hashMismatch;
        if (s == 401) return _Err.stop;
        if (s == null || s >= 500 || s == 429 || s == 408) {
          return _Err.transient;
        }
        if (s >= 400) return _Err.park;
        return _Err.transient;
    }
  }

  static String _describe(Object e) {
    if (e is SyncTransportException) {
      final parts = [
        if (e.httpStatus != null) 'HTTP ${e.httpStatus}',
        ?e.code,
        ?e.message,
      ];
      return parts.isEmpty ? e.kind.name : parts.join(' ');
    }
    return e.toString();
  }

  Future<_Outcome> _park(Database db, PendingUpload u, String error) async {
    if (await _store.markFailed(db, u, error)) {
      _notifier.notify(const {SyncTables.pendingUploads});
      return _Outcome.failed;
    }
    return _Outcome.replaced;
  }

  Future<_Outcome> _retry(
    Database db,
    PendingUpload u,
    Object e, {
    required bool stop,
  }) async {
    var wait = AssetSync.backoffFor(u.attempts + 1);
    final after = e is SyncTransportException ? e.retryAfterSeconds : null;
    if (after != null && Duration(seconds: after) > wait) {
      wait = Duration(seconds: after);
      if (wait > AssetSync.backoffCap) wait = AssetSync.backoffCap;
    }
    final ok = await _store.markRetry(
      db,
      u,
      nextAttemptAt: _now().add(wait),
      error: _describe(e),
    );
    if (!ok) return _Outcome.replaced;
    return stop ? _Outcome.retryStop : _Outcome.retry;
  }

  Future<void> _cancel(Database db, PendingUpload u) async {
    if (await _store.remove(db, u)) {
      await _store.deleteFiles([u.localPath]);
      _notifier.notify(const {SyncTables.pendingUploads});
    }
  }

  /// One transaction: entity row + asset registration + upload row; files
  /// after the commit.
  Future<_Outcome> _adopt(
    Database db,
    String table,
    PendingUpload u,
    ImageUploadResult r,
    String sha,
  ) async {
    var rowWritten = false;
    final removed = await db.transaction((txn) async {
      rowWritten = false;
      final rows = await txn.query(
        table,
        columns: ['version', 'json', 'server_json'],
        where: 'id = ?',
        whereArgs: [u.entityId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final stored = rows.first['version'] as int?;
        final v = r.version;
        // A pull may already have applied this (or a newer) server row,
        // which carries the image: never go back.
        final newer = stored == null || v == null || v > stored;
        if (newer) {
          await txn.update(
            table,
            _rowUpdate(table, rows.first, r, sha, newer: v),
            where: 'id = ?',
            whereArgs: [u.entityId],
          );
          await registerRowAssets(txn, u.entity, u.entityId, {
            'image': r.image,
            'thumbnail_url': r.thumbnailUrl,
            'image_hash': sha,
          });
          rowWritten = true;
        }
      }
      return _store.remove(txn, u);
    });
    if (removed) await _store.deleteFiles([u.localPath]);
    // T6 M6: announce only what changed.
    final changed = <String>{
      if (rowWritten) ...{table, kSyncedAssetsTable},
      if (removed) SyncTables.pendingUploads,
    };
    if (changed.isNotEmpty) _notifier.notify(changed);
    return removed ? _Outcome.uploaded : _Outcome.replaced;
  }

  static Map<String, Object?> _rowUpdate(
    String table,
    Map<String, Object?> row,
    ImageUploadResult r,
    String sha,
    {required int? newer}
  ) {
    final json = decodeJsonMap(row['json'])
      ..['image'] = r.image
      ..['thumbnail_url'] = r.thumbnailUrl;
    if (table == 'products') json['image_hash'] = sha;
    final serverRaw = row['server_json'];
    Map<String, dynamic>? server;
    if (serverRaw is String && serverRaw.isNotEmpty) {
      server = decodeJsonMap(serverRaw)
        ..['image'] = r.image
        ..['thumbnail_url'] = r.thumbnailUrl
        ..['image_hash'] = sha;
      if (r.imageBytes != null) server['image_bytes'] = r.imageBytes;
      if (r.thumbnailBytes != null) {
        server['thumbnail_bytes'] = r.thumbnailBytes;
      }
      if (newer != null) server['version'] = newer;
    }
    return {
      'json': jsonEncode(json),
      'image_hash': sha,
      if (table == 'products') ...{
        'image_url': r.image,
        'thumbnail_url': r.thumbnailUrl,
      },
      'version': ?newer,
      if (server != null) 'server_json': jsonEncode(server),
    };
  }

  Future<void> _maybeSweep(Database db) async {
    final now = _now();
    final last = _lastSweep;
    if (last != null) {
      final since = now.difference(last);
      if (!since.isNegative && since < sweepInterval) return;
    }
    _lastSweep = now;
    try {
      await _store.sweepOrphans(db);
    } catch (e) {
      _log('orphan sweep failed: $e');
    }
  }

  static void _log(String m) =>
      developer.log('ImageUploader: $m', name: 'sync');
}

enum _Eligibility { go, wait, cancel }

enum _Outcome { uploaded, failed, retry, retryStop, stop, replaced }

enum _Err { hashMismatch, park, transient, stop }
