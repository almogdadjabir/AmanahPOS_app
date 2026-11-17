import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../sync_schema.dart';

/// A picked image copied into a file we own, hashed, NOT yet recorded.
/// Produced by [PendingUploadStore.prepare] outside any transaction.
class StagedImage {
  const StagedImage({
    required this.entity,
    required this.entityId,
    required this.relativePath,
    required this.localPath,
    required this.sha256,
    required this.bytes,
  });

  final String entity;
  final String entityId;

  /// Path under `pending_images/` as stored in the row (`<entityId>/<name>`).
  final String relativePath;

  /// Absolute path, in memory only (resolved against the current base).
  final String localPath;

  /// The staged file doubles as the thumbnail (no encoder dependency; the
  /// image widget decodes it small via `cacheWidth`).
  String get thumbnailPath => localPath;

  /// Lowercase hex sha256 of the staged (= to-be-uploaded) bytes.
  final String sha256;
  final int bytes;
}

/// One `pending_uploads` row. Paths are resolved by the store: the row holds
/// a path RELATIVE to `<appSupport>/pending_images` (the app-support path
/// can change across reinstalls / iOS container moves); [localPath] is the
/// absolute path, in memory only.
class PendingUpload {
  const PendingUpload({
    required this.scope,
    required this.entity,
    required this.entityId,
    required this.relativePath,
    required this.localPath,
    required this.sha256,
    required this.bytes,
    required this.state,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
  });

  /// Waiting for its entity's open outbox rows, then for the uploader.
  static const String waiting = 'waiting';

  /// Parked (403/404/413, unreadable file): retry-able from the UI.
  static const String failed = 'failed';

  /// Sync scope (`userId|tenantId`) the upload belongs to.
  final String scope;
  final String entity;
  final String entityId;
  final String relativePath;
  final String localPath;

  /// The staged file doubles as the thumbnail.
  String get thumbnailPath => localPath;
  final String sha256;
  final int bytes;
  final String state;
  final int attempts;
  final String? nextAttemptAt;
  final String? lastError;
}

/// Staged catalog images (`pending_uploads` + files under
/// `<appSupport>/pending_images/<entityId>/`). One row per entity: a second
/// pick replaces it. Rows carry the sync scope; readers filter by it.
///
/// File I/O never runs inside a transaction: [prepare] copies and hashes
/// BEFORE the caller's `LocalWriter.write`; [stage] / [cancel] only touch the
/// row and return the files that became unreferenced, which the caller
/// deletes with [deleteFiles] AFTER the commit. If the transaction fails the
/// caller deletes the new file with [discard]. Every staged file has a
/// unique name, so deleting one can never remove a file another row uses.
/// Leftovers (crash between copy and commit, `.part` files) are removed by
/// [sweepOrphans].
///
/// Thumbnail (coordinator ruling): no new dependency; the staged file
/// doubles as the thumbnail and the widget decodes it small (`cacheWidth`).
class PendingUploadStore {
  PendingUploadStore({
    required Future<String> Function() baseDir,
    DateTime Function()? now,
    math.Random? random,
  }) : _baseDir = baseDir,
       _now = now ?? DateTime.now,
       _random = random ?? math.Random();

  /// Folder under app support that holds the staged files.
  static const String dirName = 'pending_images';
  static const String table = SyncTables.pendingUploads;
  static const String _part = '.part';

  final Future<String> Function() _baseDir;
  final DateTime Function() _now;
  final math.Random _random;

  /// `<base>/pending_images`.
  Future<String> root() async => p.join(await _baseDir(), dirName);

  /// Absolute path of a stored relative path.
  Future<String> resolve(String relativePath) async =>
      p.join(await root(), relativePath);

  /// Copies [source] into `pending_images/<entityId>/<unique>` and hashes
  /// the copied bytes. Nothing is recorded. Throws [FileSystemException]
  /// when the source cannot be read.
  Future<StagedImage> prepare({
    required String entity,
    required String entityId,
    required File source,
  }) async {
    final bytes = await source.readAsBytes();
    final base = await root();
    final dir = Directory(p.join(base, entityId));
    await dir.create(recursive: true);
    final name =
        '${_now().toUtc().microsecondsSinceEpoch}_'
        '${_random.nextInt(1 << 32).toRadixString(16)}';
    final dest = File(p.join(dir.path, name));
    final tmp = File('${dest.path}$_part');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(dest.path);
    return StagedImage(
      entity: entity,
      entityId: entityId,
      relativePath: p.join(entityId, name),
      localPath: dest.path,
      sha256: crypto.sha256.convert(bytes).toString(),
      bytes: bytes.length,
    );
  }

  /// Records [image] under [scope] (state `waiting`, attempts 0), replacing
  /// any previous row of the entity. Returns the absolute paths of the files
  /// the replaced row used (delete them after the commit).
  Future<({PendingUpload upload, List<String> obsoleteFiles})> stage(
    DatabaseExecutor txn,
    StagedImage image, {
    required String scope,
  }) async {
    final old = await get(txn, image.entity, image.entityId);
    final row = <String, Object?>{
      'scope': scope,
      'entity': image.entity,
      'entity_id': image.entityId,
      'local_path': image.relativePath,
      'thumbnail_path': image.relativePath,
      'sha256': image.sha256,
      'bytes': image.bytes,
      'state': PendingUpload.waiting,
      'attempts': 0,
      'next_attempt_at': null,
      'last_error': null,
      'created_at': _now().toUtc().toIso8601String(),
    };
    await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    return (
      upload: _fromRow(row, await root()),
      obsoleteFiles: old == null || old.relativePath == image.relativePath
          ? const <String>[]
          : [old.localPath],
    );
  }

  /// Removes the entity's upload row (any scope: the entity id is a UUID).
  /// Returns its absolute file paths (delete them after the commit); empty
  /// when there was none.
  Future<List<String>> cancel(
    DatabaseExecutor txn,
    String entity,
    String entityId,
  ) async {
    final old = await get(txn, entity, entityId);
    if (old == null) return const [];
    await txn.delete(
      table,
      where: 'entity = ? AND entity_id = ?',
      whereArgs: [entity, entityId],
    );
    return [old.localPath];
  }

  /// The entity's upload. With [scope], only when it belongs to it.
  Future<PendingUpload?> get(
    DatabaseExecutor db,
    String entity,
    String entityId, {
    String? scope,
  }) async {
    final r = await db.query(
      table,
      where: scope == null
          ? 'entity = ? AND entity_id = ?'
          : 'entity = ? AND entity_id = ? AND scope = ?',
      whereArgs: [entity, entityId, ?scope],
      limit: 1,
    );
    return r.isEmpty ? null : _fromRow(r.first, await root());
  }

  /// Every upload of [scope] (any state), e.g. for the pending-sync screen.
  Future<List<PendingUpload>> all(
    DatabaseExecutor db, {
    required String scope,
  }) async {
    final rows = await db.query(
      table,
      where: 'scope = ?',
      whereArgs: [scope],
      orderBy: 'created_at, rowid',
    );
    final base = await root();
    return [for (final r in rows) _fromRow(r, base)];
  }

  /// `waiting` rows of [scope] whose next attempt is unset or not after
  /// [now]. Whether the entity still has open outbox rows is the uploader's
  /// check.
  Future<List<PendingUpload>> due(
    DatabaseExecutor db, {
    required String scope,
    DateTime? now,
  }) async {
    final at = (now ?? _now()).toUtc().toIso8601String();
    final rows = await db.query(
      table,
      where:
          'scope = ? AND state = ? '
          'AND (next_attempt_at IS NULL OR next_attempt_at <= ?)',
      whereArgs: [scope, PendingUpload.waiting, at],
      orderBy: 'created_at, rowid',
    );
    final base = await root();
    return [for (final r in rows) _fromRow(r, base)];
  }

  // ------------------------------------------------- uploader (Task 6)
  //
  // Every write below is guarded on the staged file ([PendingUpload.
  // relativePath]): when the user picked another image meanwhile (a new
  // row), the write matches nothing and the new upload is left alone.

  static const String _guard =
      'entity = ? AND entity_id = ? AND local_path = ?';
  static List<Object?> _guardArgs(PendingUpload u) => [
    u.entity,
    u.entityId,
    u.relativePath,
  ];

  /// Transient failure: `attempts + 1`, next try at [nextAttemptAt]. The
  /// row stays `waiting` (never gives up) and the file is kept.
  Future<bool> markRetry(
    DatabaseExecutor db,
    PendingUpload u, {
    required DateTime nextAttemptAt,
    required String error,
  }) async =>
      await db.rawUpdate(
        'UPDATE $table SET attempts = attempts + 1, next_attempt_at = ?, '
        'last_error = ? WHERE $_guard',
        [nextAttemptAt.toUtc().toIso8601String(), error, ..._guardArgs(u)],
      ) >
      0;

  /// Parks the upload as [PendingUpload.failed] (403/404/413, unreadable
  /// file): kept with its file until [retryFailed] or a cancel.
  Future<bool> markFailed(
    DatabaseExecutor db,
    PendingUpload u,
    String error,
  ) async =>
      await db.update(
        table,
        {
          'state': PendingUpload.failed,
          'last_error': error,
          'next_attempt_at': null,
        },
        where: _guard,
        whereArgs: _guardArgs(u),
      ) >
      0;

  /// The staged bytes hash to [sha256] (`hash_mismatch` recompute).
  Future<bool> updateHash(
    DatabaseExecutor db,
    PendingUpload u, {
    required String sha256,
    required int bytes,
  }) async =>
      await db.update(
        table,
        {'sha256': sha256, 'bytes': bytes},
        where: _guard,
        whereArgs: _guardArgs(u),
      ) >
      0;

  /// Deletes exactly [u]'s row (not a newer pick of the same entity).
  /// Returns whether it was deleted; delete its file after the commit.
  Future<bool> remove(DatabaseExecutor db, PendingUpload u) async =>
      await db.delete(table, where: _guard, whereArgs: _guardArgs(u)) > 0;

  /// A `failed` upload back to `waiting`, due now, attempts 0 (the
  /// pending-sync screen's retry). With [scope], only a row of that scope.
  /// Returns whether a failed row was reset.
  Future<bool> retryFailed(
    DatabaseExecutor db,
    String entity,
    String entityId, {
    String? scope,
  }) async =>
      await db.update(
        table,
        {
          'state': PendingUpload.waiting,
          'attempts': 0,
          'next_attempt_at': null,
          'last_error': null,
        },
        where: scope == null
            ? 'entity = ? AND entity_id = ? AND state = ?'
            : 'entity = ? AND entity_id = ? AND state = ? AND scope = ?',
        whereArgs: [entity, entityId, PendingUpload.failed, ?scope],
      ) >
      0;

  /// Deletes [image]'s file (its transaction failed).
  Future<void> discard(StagedImage image) => deleteFiles([image.localPath]);

  /// Best effort: deletes each file and then its folder when empty.
  Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths.toSet()) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
        await _removeIfEmpty(f.parent);
      } on FileSystemException {
        // Left for sweepOrphans; never fails the caller's write.
      }
    }
  }

  /// Deletes files under `pending_images` that no `pending_uploads` row (of
  /// any scope) references, and `.part` leftovers, when older than [minAge]
  /// (a file just prepared whose write has not committed yet is younger).
  /// Empty entity folders are removed. Returns the number of files deleted.
  /// Run by the uploader (Task 6), never inside a transaction.
  Future<int> sweepOrphans(
    DatabaseExecutor db, {
    Duration minAge = const Duration(hours: 1),
  }) async {
    final dir = Directory(await root());
    if (!await dir.exists()) return 0;
    final rows = await db.query(
      table,
      columns: ['local_path', 'thumbnail_path'],
    );
    final known = <String>{
      for (final r in rows) ...[
        p.normalize(r['local_path'] as String),
        if (r['thumbnail_path'] is String)
          p.normalize(r['thumbnail_path'] as String),
      ],
    };
    final cutoff = _now().subtract(minAge);
    var deleted = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is! File) continue;
      final rel = p.normalize(p.relative(e.path, from: dir.path));
      if (known.contains(rel)) continue;
      try {
        if ((await e.lastModified()).isAfter(cutoff)) continue;
        await e.delete();
        deleted++;
      } on FileSystemException {
        // Next sweep.
      }
    }
    await for (final e in dir.list()) {
      if (e is Directory) await _removeIfEmpty(e);
    }
    return deleted;
  }

  static Future<void> _removeIfEmpty(Directory dir) async {
    try {
      if (await dir.exists() && await dir.list().isEmpty) await dir.delete();
    } on FileSystemException {
      // Raced with a new file; fine.
    }
  }

  static PendingUpload _fromRow(Map<String, Object?> r, String base) {
    final rel = r['local_path'] as String;
    return PendingUpload(
      scope: (r['scope'] as String?) ?? '',
      entity: r['entity'] as String,
      entityId: r['entity_id'] as String,
      relativePath: rel,
      localPath: p.join(base, rel),
      sha256: r['sha256'] as String,
      bytes: (r['bytes'] as int?) ?? 0,
      state: r['state'] as String,
      attempts: (r['attempts'] as int?) ?? 0,
      nextAttemptAt: r['next_attempt_at'] as String?,
      lastError: r['last_error'] as String?,
    );
  }
}
