import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../offline/offline_db.dart';
import '../appliers/applier_support.dart';
import '../db_change_notifier.dart';

export '../appliers/applier_support.dart'
    show kSyncedAssetsTable, registerAsset, unregisterAssets;

/// Outcome of one [AssetSync.run].
class AssetSyncResult {
  const AssetSyncResult({
    required this.downloaded,
    required this.failed,
    required this.remaining,
    this.skipped = false,
  });

  /// A run that did nothing because another run was in flight.
  const AssetSyncResult.skippedRun()
    : downloaded = 0,
      failed = 0,
      remaining = 0,
      skipped = true;

  final int downloaded;
  final int failed;

  /// Rows (of the requested variants) still needing a download after the
  /// run, due now or backing off.
  final int remaining;
  final bool skipped;

  @override
  String toString() =>
      'AssetSyncResult(downloaded: $downloaded, failed: $failed, '
      'remaining: $remaining${skipped ? ', skipped' : ''})';
}

/// Downloads the images registered in `synced_assets` by the catalog
/// appliers ([registerAsset]).
///
/// `expected_hash` (= feed `image_hash`) is a CHANGE TOKEN only (ruling
/// T1-a: the BE serves re-processed WebP, the hash is of the uploaded
/// bytes), so a download is never sha256-compared. It is accepted when: HTTP
/// 200, non-empty, size == Content-Length when that header is present (and
/// no Content-Encoding), and the bytes sniff as an image. The sniff is a
/// magic-byte check (JPEG must end with FFD9, PNG must carry the IEND
/// trailer, WebP's RIFF size must equal the byte count, GIF header only)
/// instead of a full decode: decoding needs the Flutter engine (`dart:ui`),
/// unavailable in the background isolate and unit tests. A corrupt image
/// with intact header/trailer is therefore accepted (ledger T1-a). Files
/// over [maxFileBytes] are rejected (Content-Length or while receiving);
/// a file that does not fit the rest of the run's byte budget is left for
/// the next run without a penalty.
///
/// Files: written to `<name>.<rand>.part` in [assetsDir], then renamed (same
/// directory = atomic) to `as_<type>_<id>_<variant>_<key><ext>`; the row is
/// switched to the new file in a transaction guarded on the url/token it was
/// downloaded for, and only then the previous file is deleted (if no row
/// references it). A download whose guarded update matches nothing is never
/// deleted directly (another instance may have adopted that very path); the
/// orphan sweep removes it. Failure deletes the temp file, keeps the old file
/// and row, and backs the row off exponentially (1 min doubling, capped at
/// 24 h). Rows with an empty token are downloaded once keyed by url
/// (`state = 'nohash'`); they give up only after [maxNoHashAttempts]
/// CONTENT failures (4xx, not an image, size mismatch, over the cap);
/// a 401/403 from the BE host (session gone) is no failure at all: the row
/// keeps its schedule and the run stops;
/// network errors, timeouts and 5xx only back off. Nothing loops.
///
/// Orphans (`as_*` files no row references: image removed, row wiped, token
/// race) are swept at the end of a run when older than [orphanGrace] (another
/// isolate may be between rename and commit); stale `.part` files after 1 h.
/// The missing-file repair and the sweep run on an instance's first run and
/// then at most once per [maintenanceInterval]; the sweep also runs after a
/// run that had rows due. A run with nothing due is two indexed queries.
/// [assetsDir] must be a directory owned by AssetSync (not the retired
/// legacy `offline_assets` directory).
///
/// Auth: [beHeaders] are added only for urls on [beBaseUrl]'s
/// scheme/host/port; every other host is fetched anonymously, including
/// after a redirect (redirects are followed manually). [dio] must therefore
/// be a plain Dio WITHOUT the sync auth interceptor.
class AssetSync {
  AssetSync({
    required OfflineDb db,
    required Dio dio,
    required Directory Function() assetsDir,
    required DbChangeNotifier notifier,
    required String? Function() scopeProvider,
    DateTime Function()? now,
    int concurrency = 2,
    Uri? beBaseUrl,
    Future<Map<String, String>> Function()? beHeaders,
    Duration orphanGrace = const Duration(minutes: 10),
    int maxFileBytes = 10 * 1024 * 1024,
  }) : _db = db,
       _maxFileBytes = maxFileBytes,
       _dio = dio,
       _assetsDir = assetsDir,
       _notifier = notifier,
       _scope = scopeProvider,
       _now = now ?? DateTime.now,
       _concurrency = math.max(1, concurrency),
       _beBase = beBaseUrl,
       _beHeaders = beHeaders,
       _orphanGrace = orphanGrace;

  final OfflineDb _db;
  final Dio _dio;
  final Directory Function() _assetsDir;
  final DbChangeNotifier _notifier;
  final String? Function() _scope;
  final DateTime Function() _now;
  final int _concurrency;
  final Uri? _beBase;
  final Future<Map<String, String>> Function()? _beHeaders;
  final Duration _orphanGrace;
  final int _maxFileBytes;

  /// Minimum spacing of the missing-file repair (full `synced_assets` scan
  /// + file stats) and of the orphan sweep on runs with nothing due.
  static const Duration maintenanceInterval = Duration(minutes: 10);

  static const Duration backoffBase = Duration(minutes: 1);
  static const Duration backoffCap = Duration(hours: 24);
  static const int maxNoHashAttempts = 5;
  static const int _maxRedirects = 3;
  static const Duration _partGrace = Duration(hours: 1);
  static const String _prefix = 'as_';

  bool _running = false;
  bool _cancelled = false;
  DateTime? _lastMaintenance;
  final math.Random _rand = math.Random();

  /// Asks the run in flight to start no further download (the files in
  /// flight finish or fail normally). Used by the background worker's time
  /// budget. No effect on a later [run].
  void cancel() {
    if (_running) _cancelled = true;
  }

  Future<AssetSyncResult> run({
    int maxFiles = 40,
    int maxBytes = 20 * 1024 * 1024,
    bool thumbnailsOnly = false,
  }) async {
    if (_running) return const AssetSyncResult.skippedRun();
    final scope = _scope();
    if (scope == null) {
      return const AssetSyncResult(downloaded: 0, failed: 0, remaining: 0);
    }
    _running = true;
    _cancelled = false;
    try {
      return await _run(scope, maxFiles, maxBytes, thumbnailsOnly);
    } finally {
      _running = false;
    }
  }

  Future<AssetSyncResult> _run(
    String scope,
    int maxFiles,
    int maxBytes,
    bool thumbnailsOnly,
  ) async {
    final db = await _db.database;
    final dir = _assetsDir();
    if (!await dir.exists()) await dir.create(recursive: true);

    // The full scan (repair + orphan sweep) is throttled: a run with nothing
    // due inside the window costs two indexed queries only (F4).
    final maintain = _maintenanceDue();
    var changed = maintain && await _resetMissingFiles(db);

    final variantSql = thumbnailsOnly ? " AND variant = 'thumb'" : '';
    final due = maxFiles <= 0
        ? const <Map<String, Object?>>[]
        : await db.query(
            kSyncedAssetsTable,
            where:
                "state = 'pending' AND (next_attempt_at IS NULL OR "
                'next_attempt_at <= ?)$variantSql',
            whereArgs: [_iso(_now())],
            orderBy:
                "CASE variant WHEN 'thumb' THEN 0 ELSE 1 END, attempts, "
                'type, id',
            limit: maxFiles,
          );

    var downloaded = 0;
    var failed = 0;
    var bytesUsed = 0;
    var next = 0;
    var budgetHit = false;
    var authRejected = false;

    Future<void> worker() async {
      while (true) {
        if (next >= due.length || budgetHit || authRejected || _cancelled) {
          return;
        }
        if (bytesUsed >= maxBytes) return;
        if (_scope() != scope) return;
        final row = due[next++];
        // The first file of a run may exceed the budget (else a large image
        // could never download); later ones must fit what is left.
        final budget = bytesUsed > 0 ? maxBytes - bytesUsed : null;
        final o = await _syncOne(db, dir, row, budget);
        switch (o.kind) {
          case _Kind.downloaded:
            downloaded++;
            bytesUsed += o.bytes;
            changed = true;
          case _Kind.failed:
            failed++;
            changed = true;
          case _Kind.stale:
            changed = true;
          case _Kind.overBudget:
            budgetHit = true;
          case _Kind.authRejected:
            // Every further BE request would be refused the same way.
            authRejected = true;
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < math.min(_concurrency, due.length); i++) worker(),
    ]);

    if (maintain || due.isNotEmpty) await _sweepOrphans(db, dir);
    if (maintain) _lastMaintenance = _now();

    final remaining =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM $kSyncedAssetsTable WHERE state = 'pending'"
            '$variantSql',
          ),
        ) ??
        0;
    if (changed) _notifier.notify(const {kSyncedAssetsTable});
    return AssetSyncResult(
      downloaded: downloaded,
      failed: failed,
      remaining: remaining,
    );
  }

  /// First run of this instance, [maintenanceInterval] since the last
  /// maintenance, or a clock that went backwards.
  bool _maintenanceDue() {
    final last = _lastMaintenance;
    if (last == null) return true;
    final since = _now().difference(last);
    return since.isNegative || since >= maintenanceInterval;
  }

  /// Rows whose file vanished (cache cleared) go back to `pending`.
  Future<bool> _resetMissingFiles(Database db) async {
    final rows = await db.query(
      kSyncedAssetsTable,
      columns: ['type', 'id', 'variant', 'local_path'],
      where: 'local_path IS NOT NULL',
    );
    var any = false;
    for (final r in rows) {
      if (await File(r['local_path'] as String).exists()) continue;
      any = true;
      await db.update(
        kSyncedAssetsTable,
        {
          'state': 'pending',
          'local_path': null,
          'local_hash': null,
          'bytes': null,
          'attempts': 0,
          'next_attempt_at': null,
        },
        where: 'type = ? AND id = ? AND variant = ? AND local_path = ?',
        whereArgs: [r['type'], r['id'], r['variant'], r['local_path']],
      );
    }
    return any;
  }

  /// Downloads one row. Never touches the row's current file unless the new
  /// one is verified AND adopted by the guarded update.
  Future<_Outcome> _syncOne(
    Database db,
    Directory dir,
    Map<String, Object?> row,
    int? budget,
  ) async {
    final type = row['type'] as String;
    final id = row['id'] as String;
    final variant = row['variant'] as String;
    final url = row['url'] as String;
    final token = (row['expected_hash'] as String?) ?? '';
    final attempts = (row['attempts'] as int?) ?? 0;
    final oldPath = row['local_path'] as String?;

    File? temp;
    try {
      final bytes = await _fetch(url, budget);
      final ext = _sniffExtension(bytes);
      if (ext == null) throw const _Invalid('not an image');
      final finalPath = p.join(
        dir.path,
        _safe('$_prefix${type}_${id}_${variant}_${_key(token, url)}$ext'),
      );
      temp = File('$finalPath.${_rand.nextInt(1 << 32)}.part');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(finalPath);
      temp = null;

      final adopted = await db.update(
        kSyncedAssetsTable,
        {
          'local_path': finalPath,
          'local_hash': token,
          'bytes': bytes.length,
          'state': token.isEmpty ? 'nohash' : 'ok',
          'attempts': 0,
          'next_attempt_at': null,
        },
        where: _guard,
        whereArgs: [type, id, variant, url, token],
      );
      if (adopted == 0) {
        // Re-registered (new token / url / removed) while downloading, or
        // another instance (background isolate) moved the row on. The file
        // may be the one the row now points to: NEVER delete here; an
        // unreferenced file is removed by the orphan sweep (after its grace).
        _log('$type/$id/$variant changed during download; not adopted');
        return const _Outcome(_Kind.stale);
      }
      if (oldPath != null &&
          oldPath != finalPath &&
          !await _referenced(db, oldPath)) {
        await _deleteQuietly(File(oldPath));
      }
      return _Outcome(_Kind.downloaded, bytes.length);
    } on _OverBudget {
      // Not the row's fault: no penalty, retried by a later run.
      return const _Outcome(_Kind.overBudget);
    } on _AuthRejected catch (e) {
      // Session gone / token cleared mid-run: not the file's fault. No
      // penalty (attempts / next_attempt_at untouched); the run stops.
      if (temp != null) await _deleteQuietly(temp);
      _log('$type/$id/$variant skipped: $e');
      return const _Outcome(_Kind.authRejected);
    } catch (e) {
      if (temp != null) await _deleteQuietly(temp);
      _log('$type/$id/$variant failed: $e');
      final n = attempts + 1;
      // Only a CONTENT failure (4xx, not an image, size mismatch, too big)
      // may end a no-hash row; network errors, timeouts and 5xx only back
      // off (capped), so an outage never loses an image.
      final content = e is _Invalid && e.content;
      final giveUp = content && token.isEmpty && n >= maxNoHashAttempts;
      await db.update(
        kSyncedAssetsTable,
        {
          'attempts': n,
          'next_attempt_at': _iso(_now().add(_backoff(n))),
          if (giveUp) 'state': 'nohash',
        },
        where: _guard,
        whereArgs: [type, id, variant, url, token],
      );
      return const _Outcome(_Kind.failed);
    }
  }

  static Future<bool> _referenced(Database db, String path) async =>
      (await db.query(
        kSyncedAssetsTable,
        columns: ['id'],
        where: 'local_path = ?',
        whereArgs: [path],
        limit: 1,
      )).isNotEmpty;

  static const String _guard =
      'type = ? AND id = ? AND variant = ? AND url = ? AND '
      "IFNULL(expected_hash, '') = ?";

  Duration _backoff(int attempts) {
    final factor = math.pow(2, math.min(attempts - 1, 20)).toInt();
    final d = backoffBase * factor;
    return d > backoffCap ? backoffCap : d;
  }

  /// GET with manual redirects so auth headers never leave the BE host.
  Future<Uint8List> _fetch(String rawUrl, int? budget) async {
    var uri = _resolve(rawUrl);
    final cap = _maxFileBytes;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final headers = <String, dynamic>{};
      if (_isBe(uri) && _beHeaders != null) {
        headers.addAll(await _beHeaders());
      }
      final cancel = CancelToken();
      Exception? abort;
      void onProgress(int received, int total) {
        if (abort != null) return;
        if (total > cap || received > cap) {
          abort = _Invalid('larger than the ${cap}B file cap');
        } else if (budget != null && total > budget) {
          abort = const _OverBudget();
        }
        if (abort != null) cancel.cancel();
      }

      final Response<List<int>> res;
      try {
        res = await _dio.getUri<List<int>>(
          uri,
          cancelToken: cancel,
          onReceiveProgress: onProgress,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (_) => true,
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 15),
            headers: headers,
          ),
        );
      } on DioException {
        if (abort != null) throw abort!;
        rethrow;
      }
      if (abort != null) throw abort!;
      final status = res.statusCode ?? 0;
      if (status >= 300 && status < 400) {
        final loc = res.headers.value('location');
        if (loc == null || loc.isEmpty) {
          throw _Invalid('redirect $status');
        }
        uri = uri.resolve(loc);
        continue;
      }
      if ((status == 401 || status == 403) && _isBe(uri)) {
        throw _AuthRejected(status);
      }
      if (status != 200) {
        // 4xx (except timeout/rate-limit) is the server's answer about this
        // file; 5xx / 408 / 429 are transient.
        final content =
            status >= 400 && status < 500 && status != 408 && status != 429;
        throw _Invalid('HTTP $status', content: content);
      }
      final data = res.data;
      if (data == null || data.isEmpty) throw const _Invalid('empty body');
      final bytes = data is Uint8List ? data : Uint8List.fromList(data);
      if (bytes.length > cap) throw _Invalid('larger than the ${cap}B cap');
      final declared = int.tryParse(
        res.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (budget != null && declared == null && bytes.length > budget) {
        throw const _OverBudget();
      }
      final encoded = res.headers.value('content-encoding') != null;
      if (declared != null && !encoded && declared != bytes.length) {
        throw _Invalid('size ${bytes.length} != Content-Length $declared');
      }
      return bytes;
    }
    throw const _Invalid('too many redirects');
  }

  Uri _resolve(String url) {
    final u = Uri.parse(url);
    if (u.hasScheme) return u;
    final base = _beBase;
    if (base == null) throw _Invalid('relative url without base: $url');
    return base.resolveUri(u);
  }

  bool _isBe(Uri u) {
    final b = _beBase;
    if (b == null) return false;
    return u.scheme == b.scheme &&
        u.host.toLowerCase() == b.host.toLowerCase() &&
        u.port == b.port;
  }

  /// File extension for an image, or null when [b] is not one.
  static String? _sniffExtension(Uint8List b) {
    bool at(int off, List<int> sig) {
      if (b.length < off + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[off + i] != sig[i]) return false;
      }
      return true;
    }

    // JPEG: SOI ... EOI (FFD9) as the last two bytes (truncation check).
    if (at(0, const [0xFF, 0xD8, 0xFF])) {
      final n = b.length;
      return n >= 4 && b[n - 2] == 0xFF && b[n - 1] == 0xD9 ? '.jpg' : null;
    }
    // PNG: signature ... IEND chunk (type at len-8, then 4-byte CRC).
    if (at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return b.length >= 20 && at(b.length - 8, 'IEND'.codeUnits)
          ? '.png'
          : null;
    }
    if (at(0, 'GIF87a'.codeUnits) || at(0, 'GIF89a'.codeUnits)) return '.gif';
    if (at(0, 'RIFF'.codeUnits) && at(8, 'WEBP'.codeUnits)) {
      final riff = b[4] | (b[5] << 8) | (b[6] << 16) | (b[7] << 24);
      // RIFF size excludes the 8-byte header; a pad byte may follow.
      final total = riff + 8;
      if (b.length == total || b.length == total + 1) return '.webp';
      return null;
    }
    return null;
  }

  Future<void> _sweepOrphans(Database db, Directory dir) async {
    final referenced = (await db.query(
      kSyncedAssetsTable,
      columns: ['local_path'],
      where: 'local_path IS NOT NULL',
    )).map((r) => p.basename(r['local_path'] as String)).toSet();
    final wall = DateTime.now();
    try {
      await for (final e in dir.list(followLinks: false)) {
        if (e is! File) continue;
        final name = p.basename(e.path);
        if (!name.startsWith(_prefix)) continue;
        final age = wall.difference((await e.stat()).modified);
        if (name.endsWith('.part')) {
          if (age >= _partGrace) await _deleteQuietly(e);
          continue;
        }
        if (referenced.contains(name)) continue;
        if (age >= _orphanGrace) await _deleteQuietly(e);
      }
    } catch (e) {
      _log('orphan sweep failed: $e');
    }
  }

  static String _key(String token, String url) {
    if (token.isNotEmpty) {
      final t = _safe(token);
      return t.length > 32 ? t.substring(0, 32) : t;
    }
    return 'u${_fnv1a64(url)}';
  }

  /// Stable across runs/isolates (unlike `String.hashCode`).
  static String _fnv1a64(String s) {
    var h = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;
    for (final c in s.codeUnits) {
      h = ((h ^ BigInt.from(c)) * prime) & mask;
    }
    return h.toRadixString(16);
  }

  static String _safe(String s) =>
      s.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  static String _iso(DateTime t) => t.toUtc().toIso8601String();

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static void _log(String m) => developer.log('AssetSync: $m', name: 'sync');
}

enum _Kind { downloaded, failed, stale, overBudget, authRejected }

class _Outcome {
  const _Outcome(this.kind, [this.bytes = 0]);
  final _Kind kind;
  final int bytes;
}

/// Larger than what is left of the run's byte budget (no penalty).
class _OverBudget implements Exception {
  const _OverBudget();
}

/// The BE host refused the credentials (401/403): no penalty, run stops.
/// Foreign hosts get no credentials, so their 401/403 stays a content
/// failure.
class _AuthRejected implements Exception {
  const _AuthRejected(this.status);
  final int status;

  @override
  String toString() => 'HTTP $status from the BE host (auth)';
}

/// A rejected download. [content] = a property of the file/answer itself
/// (counts toward giving up a no-hash row); otherwise transient.
class _Invalid implements Exception {
  const _Invalid(this.reason, {this.content = true});
  final String reason;
  final bool content;

  @override
  String toString() => reason;
}
