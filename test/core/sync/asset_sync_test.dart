import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/core/sync/appliers/product_applier.dart';
import 'package:amana_pos/core/sync/assets/asset_sync.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_db.dart';

const _be = 'https://api.amana.test';
const _scope = 'u1|t1';

/// Minimal valid-looking WebP of exactly [n] bytes (RIFF size consistent).
Uint8List webp(int n, {int fill = 7}) {
  assert(n >= 16);
  final b = Uint8List(n)..fillRange(0, n, fill);
  b.setAll(0, 'RIFF'.codeUnits);
  final size = n - 8;
  b[4] = size & 0xff;
  b[5] = (size >> 8) & 0xff;
  b[6] = (size >> 16) & 0xff;
  b[7] = (size >> 24) & 0xff;
  b.setAll(8, 'WEBPVP8 '.codeUnits);
  return b;
}

/// PNG signature ... IEND chunk trailer (length 0, 'IEND', CRC).
Uint8List png(int n, {bool iend = true}) {
  final b = Uint8List(n)..fillRange(0, n, 1);
  b.setAll(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  if (iend) {
    b.setAll(n - 12, const [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44]);
    b.setAll(n - 4, const [0xAE, 0x42, 0x60, 0x82]);
  }
  return b;
}

/// JPEG SOI ... EOI (FFD9) when [eoi].
Uint8List jpeg(int n, {bool eoi = true}) {
  final b = Uint8List(n)..fillRange(0, n, 3);
  b.setAll(0, const [0xFF, 0xD8, 0xFF, 0xE0]);
  if (eoi) b.setAll(n - 2, const [0xFF, 0xD9]);
  return b;
}

class Resp {
  Resp(
    this.bytes, {
    this.status = 200,
    this.contentLength,
    this.location,
    this.gate,
  });
  final List<int> bytes;
  final int status;

  /// Content-Length header to send; defaults to the real length. -1 = none.
  final int? contentLength;
  final String? location;

  /// When set, the response waits for it.
  final Completer<void>? gate;
}

class FakeAdapter implements HttpClientAdapter {
  final Map<String, Resp Function()> routes = {};
  final List<RequestOptions> requests = [];
  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      final url = options.uri.toString();
      final route = routes[url];
      if (route == null) {
        return ResponseBody.fromBytes(const [], 404);
      }
      final r = route();
      if (r.gate != null) await r.gate!.future;
      await Future<void>.delayed(Duration.zero);
      final len = r.contentLength ?? r.bytes.length;
      return ResponseBody.fromBytes(
        r.bytes,
        r.status,
        headers: {
          if (len >= 0) Headers.contentLengthHeader: ['$len'],
          if (r.location != null) 'location': [r.location!],
        },
      );
    } finally {
      inFlight--;
    }
  }

  @override
  void close({bool force = false}) {}

  List<String> get urls => requests.map((r) => r.uri.toString()).toList();
}

void main() {
  late OfflineDb odb;
  late Database db;
  late Directory dir;
  late FakeAdapter adapter;
  late DbChangeNotifier notifier;
  late List<Set<String>> notified;
  late DateTime now;
  String? scope;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    dir = await Directory.systemTemp.createTemp('asset_sync_test');
    adapter = FakeAdapter();
    notifier = DbChangeNotifier();
    notified = [];
    notifier.changes.listen(notified.add);
    now = DateTime.utc(2026, 11, 16, 12);
    scope = _scope;
  });

  tearDown(() async {
    await db.close();
    notifier.dispose();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AssetSync make({
    int concurrency = 2,
    Duration? orphanGrace,
    int maxFileBytes = 10 * 1024 * 1024,
  }) {
    final dio = Dio()..httpClientAdapter = adapter;
    return AssetSync(
      db: odb,
      dio: dio,
      assetsDir: () => dir,
      notifier: notifier,
      scopeProvider: () => scope,
      now: () => now,
      concurrency: concurrency,
      beBaseUrl: Uri.parse(_be),
      beHeaders: () async => {
        'Authorization': 'Bearer tok',
        'X-Tenant-ID': 't1',
      },
      orphanGrace: orphanGrace ?? Duration.zero,
      maxFileBytes: maxFileBytes,
    );
  }

  Future<void> reg(
    String id,
    String variant,
    String? url,
    String? hash, {
    String type = 'product',
  }) =>
      db.transaction((txn) => registerAsset(txn, type, id, variant, url, hash));

  Future<Map<String, Object?>?> row(String id, String variant) async {
    final r = await db.query(
      kSyncedAssetsTable,
      where: 'type = ? AND id = ? AND variant = ?',
      whereArgs: ['product', id, variant],
    );
    return r.isEmpty ? null : r.first;
  }

  List<String> files() =>
      dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();

  group('download + verify', () {
    test('verified download is renamed into place; row ok; notified', () async {
      final bytes = webp(64);
      adapter.routes['$_be/media/t1.webp?v=h1'] = () => Resp(bytes);
      await reg('p1', 'thumb', '$_be/media/t1.webp?v=h1', 'h1');

      final r = await make().run();
      expect((r.downloaded, r.failed, r.remaining), (1, 0, 0));
      final a = (await row('p1', 'thumb'))!;
      expect(a['state'], 'ok');
      expect(a['local_hash'], 'h1');
      expect(a['bytes'], 64);
      final f = File(a['local_path'] as String);
      expect(f.readAsBytesSync(), bytes);
      expect(f.path.endsWith('.part'), isFalse);
      expect(files().where((n) => n.endsWith('.part')), isEmpty);
      expect(notified.any((t) => t.contains(kSyncedAssetsTable)), isTrue);
    });

    test('failure keeps the OLD file and backs off per row', () async {
      final good = webp(40);
      adapter.routes['$_be/a.webp?v=h1'] = () => Resp(good);
      await reg('p1', 'full', '$_be/a.webp?v=h1', 'h1');
      await make().run();
      final oldPath = (await row('p1', 'full'))!['local_path'] as String;

      // Token changes; the server now fails.
      adapter.routes['$_be/a.webp?v=h2'] = () => Resp(const [], status: 500);
      await reg('p1', 'full', '$_be/a.webp?v=h2', 'h2');
      final sync = make();
      var r = await sync.run();
      expect((r.downloaded, r.failed, r.remaining), (0, 1, 1));
      var a = (await row('p1', 'full'))!;
      expect(a['local_path'], oldPath);
      expect(a['local_hash'], 'h1');
      expect(File(oldPath).readAsBytesSync(), good);
      expect(a['attempts'], 1);
      expect(a['state'], 'pending');
      final next1 = DateTime.parse(a['next_attempt_at'] as String);
      expect(next1.isAfter(now), isTrue);

      // Not due yet: no request.
      final before = adapter.requests.length;
      r = await sync.run();
      expect(adapter.requests.length, before);
      expect((r.downloaded, r.failed, r.remaining), (0, 0, 1));

      // Due: retried, fails again, backoff grows (exponential).
      now = next1;
      await sync.run();
      expect(adapter.requests.length, before + 1);
      a = (await row('p1', 'full'))!;
      expect(a['attempts'], 2);
      final next2 = DateTime.parse(a['next_attempt_at'] as String);
      expect(
        next2.difference(now),
        greaterThan(next1.difference(DateTime.utc(2026, 11, 16, 12))),
      );
      expect(File(oldPath).existsSync(), isTrue);

      // Server recovers: new file adopted, old file removed.
      adapter.routes['$_be/a.webp?v=h2'] = () => Resp(webp(48, fill: 9));
      now = next2;
      r = await sync.run();
      expect(r.downloaded, 1);
      a = (await row('p1', 'full'))!;
      expect(a['local_hash'], 'h2');
      expect(a['attempts'], 0);
      expect(a['local_path'], isNot(oldPath));
      expect(File(oldPath).existsSync(), isFalse);
      expect(File(a['local_path'] as String).existsSync(), isTrue);
    });

    test('wrong magic bytes are rejected (old file kept, no temp)', () async {
      await reg('p1', 'thumb', '$_be/t.webp', 'h1');
      adapter.routes['$_be/t.webp'] = () => Resp(List.filled(64, 0x41));
      final r = await make().run();
      expect((r.downloaded, r.failed), (0, 1));
      final a = (await row('p1', 'thumb'))!;
      expect(a['local_path'], isNull);
      expect(a['attempts'], 1);
      expect(files(), isEmpty);
    });

    test('empty body is rejected', () async {
      await reg('p1', 'thumb', '$_be/t.webp', 'h1');
      adapter.routes['$_be/t.webp'] = () => Resp(const []);
      final r = await make().run();
      expect(r.failed, 1);
      expect(files(), isEmpty);
    });

    test('truncated download vs Content-Length is rejected', () async {
      await reg('p1', 'thumb', '$_be/t.png', 'h1');
      adapter.routes['$_be/t.png'] = () => Resp(png(50), contentLength: 100);
      final r = await make().run();
      expect((r.downloaded, r.failed), (0, 1));
      expect((await row('p1', 'thumb'))!['local_path'], isNull);
      expect(files(), isEmpty);
    });

    test('truncated WebP (RIFF size mismatch) is rejected without a '
        'Content-Length', () async {
      await reg('p1', 'thumb', '$_be/t.webp', 'h1');
      final full = webp(80);
      adapter.routes['$_be/t.webp'] = () =>
          Resp(full.sublist(0, 50), contentLength: -1);
      final r = await make().run();
      expect(r.failed, 1);
      expect(files(), isEmpty);
    });

    test('JPEG must end with FFD9; PNG must carry the IEND trailer', () async {
      adapter.routes['$_be/ok.jpg'] = () => Resp(jpeg(40));
      adapter.routes['$_be/cut.jpg'] = () => Resp(jpeg(40, eoi: false));
      adapter.routes['$_be/ok.png'] = () => Resp(png(40));
      adapter.routes['$_be/cut.png'] = () => Resp(png(40, iend: false));
      await reg('p1', 'thumb', '$_be/ok.jpg', 'h');
      await reg('p2', 'thumb', '$_be/cut.jpg', 'h');
      await reg('p3', 'thumb', '$_be/ok.png', 'h');
      await reg('p4', 'thumb', '$_be/cut.png', 'h');
      final r = await make().run();
      expect((r.downloaded, r.failed), (2, 2));
      expect((await row('p1', 'thumb'))!['state'], 'ok');
      expect((await row('p2', 'thumb'))!['local_path'], isNull);
      expect((await row('p3', 'thumb'))!['state'], 'ok');
      expect((await row('p4', 'thumb'))!['local_path'], isNull);
    });

    test('non-200 (404) is a failure with backoff', () async {
      await reg('p1', 'thumb', '$_be/missing.webp', 'h1');
      final r = await make().run();
      expect(r.failed, 1);
      expect((await row('p1', 'thumb'))!['next_attempt_at'], isNotNull);
    });
  });

  group('change token', () {
    test('token change re-downloads; unchanged token does not', () async {
      adapter.routes['$_be/a.webp?v=h1'] = () => Resp(webp(32));
      await reg('p1', 'thumb', '$_be/a.webp?v=h1', 'h1');
      final sync = make();
      await sync.run();
      expect(adapter.requests, hasLength(1));

      // Same token re-registered (replayed page / echo): nothing to do.
      await reg('p1', 'thumb', '$_be/a.webp?v=h1', 'h1');
      var r = await sync.run();
      expect(adapter.requests, hasLength(1));
      expect((r.downloaded, r.remaining), (0, 0));
      expect((await row('p1', 'thumb'))!['state'], 'ok');

      // New token: stale, re-downloaded; old file intact until then.
      adapter.routes['$_be/a.webp?v=h2'] = () => Resp(webp(36));
      await reg('p1', 'thumb', '$_be/a.webp?v=h2', 'h2');
      final stale = (await row('p1', 'thumb'))!;
      expect(stale['state'], 'pending');
      expect(File(stale['local_path'] as String).existsSync(), isTrue);
      r = await sync.run();
      expect(r.downloaded, 1);
      expect(adapter.urls.last, '$_be/a.webp?v=h2');
      expect((await row('p1', 'thumb'))!['local_hash'], 'h2');
      expect(files(), hasLength(1));
    });

    test('empty token downloads once keyed by url (nohash), never again '
        'unless the url changes', () async {
      adapter.routes['$_be/legacy.png'] = () => Resp(png(30));
      await reg('p1', 'full', '$_be/legacy.png', '');
      final sync = make();
      var r = await sync.run();
      expect(r.downloaded, 1);
      expect((await row('p1', 'full'))!['state'], 'nohash');

      await reg('p1', 'full', '$_be/legacy.png', null);
      r = await sync.run();
      expect(adapter.requests, hasLength(1));
      expect(r.remaining, 0);

      adapter.routes['$_be/legacy2.png'] = () => Resp(png(31));
      await reg('p1', 'full', '$_be/legacy2.png', '');
      r = await sync.run();
      expect(r.downloaded, 1);
      expect(adapter.urls.last, '$_be/legacy2.png');
      expect(files(), hasLength(1));
    });

    test('empty token that keeps failing stops after a bounded number of '
        'attempts (never loops)', () async {
      await reg('p1', 'full', '$_be/broken.png', '');
      adapter.routes['$_be/broken.png'] = () => Resp(List.filled(20, 0));
      final sync = make();
      for (var i = 0; i < 20; i++) {
        await sync.run();
        now = now.add(const Duration(days: 2));
      }
      expect(adapter.requests.length, lessThanOrEqualTo(5));
      expect((await row('p1', 'full'))!['state'], 'nohash');
      final r = await sync.run();
      expect(r.remaining, 0);
    });

    test('empty token: a long outage (network errors / 5xx) never gives up; '
        'recovery downloads it', () async {
      await reg('p1', 'full', '$_be/legacy.png', '');
      final sync = make();
      for (var i = 0; i < 12; i++) {
        adapter.routes['$_be/legacy.png'] = i.isEven
            ? () => Resp(const [], status: 503)
            : () => throw DioException.connectionError(
                requestOptions: RequestOptions(path: '$_be/legacy.png'),
                reason: 'offline',
              );
        await sync.run();
        now = now.add(const Duration(days: 2));
      }
      expect(adapter.requests, hasLength(12));
      expect((await row('p1', 'full'))!['state'], 'pending');
      adapter.routes['$_be/legacy.png'] = () => Resp(png(30));
      final r = await sync.run();
      expect(r.downloaded, 1);
      expect((await row('p1', 'full'))!['state'], 'nohash');
    });

    test('empty token: repeated 404 gives up (nohash, no file)', () async {
      await reg('p1', 'full', '$_be/gone.png', '');
      final sync = make();
      for (var i = 0; i < 10; i++) {
        await sync.run();
        now = now.add(const Duration(days: 2));
      }
      expect(adapter.requests.length, AssetSync.maxNoHashAttempts);
      final a = (await row('p1', 'full'))!;
      expect(a['state'], 'nohash');
      expect(a['local_path'], isNull);
    });

    test('BE 401/403 (token cleared mid-run): no penalty, never gives up, '
        'the run stops early', () async {
      for (final status in [401, 403]) {
        await db.delete(kSyncedAssetsTable);
        adapter.requests.clear();
        await reg('p1', 'full', '$_be/auth$status-1.png', '');
        await reg('p2', 'full', '$_be/auth$status-2.png', '');
        await reg('p3', 'full', '$_be/auth$status-3.png', '');
        for (final i in [1, 2, 3]) {
          adapter.routes['$_be/auth$status-$i.png'] = () =>
              Resp(const [], status: status);
        }
        final sync = make(concurrency: 1);
        for (var i = 0; i < 10; i++) {
          final r = await sync.run();
          expect(r.failed, 0, reason: 'HTTP $status is not a failure');
          now = now.add(const Duration(days: 2));
        }
        expect(
          adapter.requests,
          hasLength(10),
          reason: 'HTTP $status: one request per run, then the run stops',
        );
        for (final id in ['p1', 'p2', 'p3']) {
          final a = (await row(id, 'full'))!;
          expect(a['state'], 'pending', reason: '$id HTTP $status');
          expect(a['attempts'], 0, reason: '$id HTTP $status');
          expect(a['next_attempt_at'], isNull, reason: '$id HTTP $status');
        }
        // Signed in again: downloads.
        for (final i in [1, 2, 3]) {
          adapter.routes['$_be/auth$status-$i.png'] = () => Resp(png(30));
        }
        expect((await sync.run()).downloaded, 3);
      }
    });

    test('401 from a foreign host stays a content failure', () async {
      await reg('p1', 'full', 'https://cdn.example.com/x.png', '');
      adapter.routes['https://cdn.example.com/x.png'] = () =>
          Resp(const [], status: 401);
      final sync = make();
      final r = await sync.run();
      expect(r.failed, 1);
      expect((await row('p1', 'full'))!['attempts'], 1);
    });

    test('token A -> B -> A before B was downloaded: no re-download', () async {
      adapter.routes['$_be/a.webp?v=A'] = () => Resp(webp(32));
      await reg('p1', 'thumb', '$_be/a.webp?v=A', 'A');
      final sync = make();
      await sync.run();
      final path = (await row('p1', 'thumb'))!['local_path'];
      await reg('p1', 'thumb', '$_be/a.webp?v=B', 'B');
      expect((await row('p1', 'thumb'))!['state'], 'pending');
      await reg('p1', 'thumb', '$_be/a.webp?v=A', 'A');
      final a = (await row('p1', 'thumb'))!;
      expect(a['state'], 'ok');
      expect(a['local_path'], path);
      final r = await sync.run();
      expect((r.downloaded, r.remaining), (0, 0));
      expect(adapter.requests, hasLength(1));
    });

    test('two instances (foreground + background isolate): a stale '
        'completion never deletes the file the row points to', () async {
      // B starts downloading (url U, token h1) and stalls.
      final gate = Completer<void>();
      adapter.routes['$_be/u1.webp'] = () => Resp(webp(32), gate: gate);
      adapter.routes['$_be/u2.webp'] = () => Resp(webp(32, fill: 5));
      await reg('p1', 'thumb', '$_be/u1.webp', 'h1');
      final b = make().run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // The image moves host (same token); A downloads + adopts the same
      // token-keyed file name.
      await reg('p1', 'thumb', '$_be/u2.webp', 'h1');
      final ra = await make(orphanGrace: const Duration(hours: 1)).run();
      expect(ra.downloaded, 1);
      final path = (await row('p1', 'thumb'))!['local_path'] as String;
      // B completes: its guarded update matches nothing.
      gate.complete();
      await b;
      final a = (await row('p1', 'thumb'))!;
      expect(a['local_path'], path);
      expect(a['state'], 'ok');
      expect(File(path).existsSync(), isTrue);
    });

    test('token changing while the download is in flight: the stale file is '
        'not adopted, row stays pending with the new token', () async {
      final gate = Completer<void>();
      adapter.routes['$_be/a.webp?v=h1'] = () => Resp(webp(32), gate: gate);
      await reg('p1', 'thumb', '$_be/a.webp?v=h1', 'h1');
      final f = make().run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await reg('p1', 'thumb', '$_be/a.webp?v=h2', 'h2');
      gate.complete();
      await f;
      final a = (await row('p1', 'thumb'))!;
      expect(a['state'], 'pending');
      expect(a['expected_hash'], 'h2');
      expect(a['local_path'], isNull);
      expect(files(), isEmpty);
    });

    test('removed image: registration deleted, file swept', () async {
      adapter.routes['$_be/a.webp'] = () => Resp(webp(32));
      await reg('p1', 'thumb', '$_be/a.webp', 'h1');
      final sync = make();
      await sync.run();
      expect(files(), hasLength(1));
      await reg('p1', 'thumb', null, null);
      expect(await row('p1', 'thumb'), isNull);
      // Nothing due: the sweep waits for the maintenance window (F4).
      now = now.add(AssetSync.maintenanceInterval);
      await sync.run();
      expect(files(), isEmpty);
    });

    test('a file deleted from disk is downloaded again', () async {
      adapter.routes['$_be/a.webp'] = () => Resp(webp(32));
      await reg('p1', 'thumb', '$_be/a.webp', 'h1');
      final sync = make();
      await sync.run();
      File((await row('p1', 'thumb'))!['local_path'] as String).deleteSync();
      // The missing-file repair runs once per maintenance window (F4).
      now = now.add(AssetSync.maintenanceInterval);
      final r = await sync.run();
      expect(r.downloaded, 1);
      expect(
        File((await row('p1', 'thumb'))!['local_path'] as String).existsSync(),
        isTrue,
      );
    });

    test('orphan sweep spares young files (other isolate) and unknown '
        'files', () async {
      File('${dir.path}/as_product_px_thumb_zz.webp').writeAsBytesSync([1]);
      File('${dir.path}/someone_else.bin').writeAsBytesSync([1]);
      await make(orphanGrace: const Duration(hours: 1)).run();
      expect(files(), ['as_product_px_thumb_zz.webp', 'someone_else.bin']);
      await make().run();
      expect(files(), ['someone_else.bin']);
    });

    group('maintenance throttle (F4)', () {
      test('nothing due: no missing-file repair and no orphan sweep until '
          'the window passes (injected clock)', () async {
        adapter.routes['$_be/a.webp'] = () => Resp(webp(32));
        await reg('p1', 'thumb', '$_be/a.webp', 'h1');
        final sync = make();
        await sync.run(); // first run: maintenance + download
        final path = (await row('p1', 'thumb'))!['local_path'] as String;
        File(path).deleteSync();
        File('${dir.path}/as_product_px_thumb_zz.webp').writeAsBytesSync([1]);

        now = now.add(
          AssetSync.maintenanceInterval - const Duration(seconds: 1),
        );
        final quiet = await sync.run();
        expect(quiet.downloaded, 0);
        expect((await row('p1', 'thumb'))!['local_path'], path);
        expect((await row('p1', 'thumb'))!['state'], 'ok');
        expect(files(), ['as_product_px_thumb_zz.webp']);
        expect(adapter.requests, hasLength(1));

        now = now.add(const Duration(seconds: 1));
        final due = await sync.run();
        expect(due.downloaded, 1, reason: 'repair reset the row, re-fetched');
        expect(
          File(
            (await row('p1', 'thumb'))!['local_path'] as String,
          ).existsSync(),
          isTrue,
        );
        expect(files(), isNot(contains('as_product_px_thumb_zz.webp')));
      });

      test(
        'a run with due rows sweeps orphans even inside the window',
        () async {
          adapter.routes['$_be/a.webp'] = () => Resp(webp(32));
          adapter.routes['$_be/b.webp'] = () => Resp(webp(40));
          await reg('p1', 'thumb', '$_be/a.webp', 'h1');
          final sync = make();
          await sync.run();
          File('${dir.path}/as_product_px_thumb_zz.webp').writeAsBytesSync([1]);
          await reg('p2', 'thumb', '$_be/b.webp', 'h2');
          final r = await sync.run();
          expect(r.downloaded, 1);
          expect(files(), isNot(contains('as_product_px_thumb_zz.webp')));
        },
      );

      test('a clock that went backwards runs maintenance', () async {
        adapter.routes['$_be/a.webp'] = () => Resp(webp(32));
        await reg('p1', 'thumb', '$_be/a.webp', 'h1');
        final sync = make();
        await sync.run();
        File('${dir.path}/as_product_px_thumb_zz.webp').writeAsBytesSync([1]);
        now = now.subtract(const Duration(hours: 1));
        await sync.run();
        expect(files(), isNot(contains('as_product_px_thumb_zz.webp')));
      });
    });
  });

  group('budget + order', () {
    test('thumbnails before full images', () async {
      adapter.routes['$_be/full.webp'] = () => Resp(webp(20));
      adapter.routes['$_be/thumb.webp'] = () => Resp(webp(20));
      await reg('p1', 'full', '$_be/full.webp', 'h');
      await reg('p2', 'thumb', '$_be/thumb.webp', 'h');
      final r = await make().run(maxFiles: 1);
      expect(adapter.urls, ['$_be/thumb.webp']);
      expect(r.remaining, 1);
      await make().run();
      expect(adapter.urls, ['$_be/thumb.webp', '$_be/full.webp']);
    });

    test('thumbnailsOnly never downloads full images', () async {
      adapter.routes['$_be/full.webp'] = () => Resp(webp(20));
      adapter.routes['$_be/thumb.webp'] = () => Resp(webp(20));
      await reg('p1', 'full', '$_be/full.webp', 'h');
      await reg('p2', 'thumb', '$_be/thumb.webp', 'h');
      final r = await make().run(thumbnailsOnly: true);
      expect(adapter.urls, ['$_be/thumb.webp']);
      expect((r.downloaded, r.remaining), (1, 0));
    });

    test('maxFiles respected', () async {
      for (var i = 0; i < 3; i++) {
        adapter.routes['$_be/$i.webp'] = () => Resp(webp(20));
        await reg('p$i', 'thumb', '$_be/$i.webp', 'h');
      }
      final r = await make().run(maxFiles: 2);
      expect(adapter.requests, hasLength(2));
      expect((r.downloaded, r.remaining), (2, 1));
    });

    test(
      'maxBytes respected (no new download once the budget is used)',
      () async {
        for (var i = 0; i < 3; i++) {
          adapter.routes['$_be/$i.webp'] = () => Resp(webp(100));
          await reg('p$i', 'thumb', '$_be/$i.webp', 'h');
        }
        // 1st fits; 2nd announces 100 > remaining 50: skipped WITHOUT a
        // penalty and the run stops (no 3rd request).
        final r = await make(concurrency: 1).run(maxBytes: 150);
        expect(adapter.requests, hasLength(2));
        expect((r.downloaded, r.failed, r.remaining), (1, 0, 2));
        final skipped = (await row('p1', 'thumb'))!;
        expect(skipped['attempts'], 0);
        expect(skipped['next_attempt_at'], isNull);
        expect(files(), hasLength(1));
        // Next run (fresh budget) gets them.
        final r2 = await make(concurrency: 1).run(maxBytes: 1000);
        expect((r2.downloaded, r2.remaining), (2, 0));
      },
    );

    test('per-file cap: Content-Length over the cap is rejected', () async {
      adapter.routes['$_be/big.webp'] = () => Resp(webp(200));
      await reg('p1', 'thumb', '$_be/big.webp', 'h');
      final r = await make(maxFileBytes: 100).run();
      expect((r.downloaded, r.failed), (0, 1));
      expect(files(), isEmpty);
    });

    test(
      'per-file cap without Content-Length aborts while receiving',
      () async {
        adapter.routes['$_be/big.webp'] = () =>
            Resp(webp(200), contentLength: -1);
        await reg('p1', 'thumb', '$_be/big.webp', 'h');
        final r = await make(maxFileBytes: 100).run();
        expect((r.downloaded, r.failed), (0, 1));
        expect(files(), isEmpty);
      },
    );

    test('at most `concurrency` downloads in flight', () async {
      for (var i = 0; i < 5; i++) {
        adapter.routes['$_be/$i.webp'] = () => Resp(webp(20));
        await reg('p$i', 'thumb', '$_be/$i.webp', 'h');
      }
      final r = await make().run();
      expect(r.downloaded, 5);
      expect(adapter.maxInFlight, 2);
    });

    test('a second concurrent run is a no-op; no temp file sits at the '
        'final path while downloading', () async {
      final gate = Completer<void>();
      adapter.routes['$_be/a.webp'] = () => Resp(webp(32), gate: gate);
      await reg('p1', 'thumb', '$_be/a.webp', 'h1');
      final sync = make();
      final first = sync.run();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final second = await sync.run();
      expect(second.skipped, isTrue);
      expect((second.downloaded, second.failed), (0, 0));
      expect(adapter.requests, hasLength(1));
      expect(files().where((n) => !n.endsWith('.part')), isEmpty);
      gate.complete();
      final r = await first;
      expect(r.downloaded, 1);
      expect(adapter.requests, hasLength(1));
    });
  });

  group('auth + scope', () {
    test('sync auth headers only for the BE host; other hosts anonymous; '
        'a redirect to another host drops them', () async {
      adapter.routes['$_be/a.webp'] = () => Resp(webp(20));
      adapter.routes['https://cdn.other.test/b.webp'] = () => Resp(webp(20));
      adapter.routes['$_be/redir.webp'] = () =>
          Resp(const [], status: 302, location: 'https://s3.other.test/c.webp');
      adapter.routes['https://s3.other.test/c.webp'] = () => Resp(webp(20));
      await reg('p1', 'thumb', '$_be/a.webp', 'h');
      await reg('p2', 'thumb', 'https://cdn.other.test/b.webp', 'h');
      await reg('p3', 'thumb', '$_be/redir.webp', 'h');
      final r = await make(concurrency: 1).run();
      expect(r.downloaded, 3);
      Map<String, dynamic> h(String url) =>
          adapter.requests.firstWhere((q) => q.uri.toString() == url).headers;
      bool hasAuth(String url) => h(url).keys.any(
        (k) =>
            k.toLowerCase() == 'authorization' ||
            k.toLowerCase() == 'x-tenant-id',
      );
      expect(hasAuth('$_be/a.webp'), isTrue);
      expect(hasAuth('$_be/redir.webp'), isTrue);
      expect(hasAuth('https://cdn.other.test/b.webp'), isFalse);
      expect(hasAuth('https://s3.other.test/c.webp'), isFalse);
    });

    for (final foreign in [
      'https://api.amana.test.evil.com/x.webp',
      'http://api.amana.test/x.webp',
      'https://api.amana.test:8443/x.webp',
    ]) {
      test('host pinning: $foreign is anonymous', () async {
        adapter.routes[foreign] = () => Resp(webp(20));
        await reg('p1', 'thumb', foreign, 'h');
        final r = await make().run();
        expect(r.downloaded, 1);
        final h = adapter.requests.single.headers;
        expect(
          h.keys.map((k) => k.toLowerCase()),
          isNot(anyOf(contains('authorization'), contains('x-tenant-id'))),
        );
      });
    }

    test('relative url resolves against the BE base url', () async {
      adapter.routes['$_be/media/x.webp'] = () => Resp(webp(20));
      await reg('p1', 'thumb', '/media/x.webp', 'h');
      final r = await make().run();
      expect(r.downloaded, 1);
    });

    test('null scope: no work at all', () async {
      adapter.routes['$_be/a.webp'] = () => Resp(webp(20));
      await reg('p1', 'thumb', '$_be/a.webp', 'h');
      scope = null;
      final r = await make().run();
      expect((r.downloaded, r.failed, r.remaining), (0, 0, 0));
      expect(adapter.requests, isEmpty);
      expect((await row('p1', 'thumb'))!['state'], 'pending');
    });
  });

  group('appliers register assets', () {
    PullChange up(String entity, String id, int v, Map<String, dynamic> d) =>
        PullChange(
          seq: 0,
          entity: entity,
          op: 'upsert',
          id: id,
          version: v,
          data: d,
        );

    Map<String, dynamic> product(int v, {String? hash, bool image = true}) => {
      'id': 'p1',
      'version': v,
      'name': 'Tea',
      'price': '1.00',
      'category': null,
      'image': image ? '$_be/i.webp?v=$hash' : null,
      'thumbnail_url': image ? '$_be/t.webp?v=$hash' : null,
      'image_hash': hash,
    };

    Future<void> apply(Object applier, PullChange c) => db.transaction(
      (txn) => applier is ProductApplier
          ? applier.apply(txn, c)
          : (applier as CategoryApplier).apply(txn, c),
    );

    test('product upsert registers thumb + full; newer token marks stale; '
        'older version ignored; image removed unregisters; delete '
        'unregisters', () async {
      final a = ProductApplier();
      expect(a.tables, contains(kSyncedAssetsTable));
      await apply(a, up('product', 'p1', 1, product(1, hash: 'h1')));
      var t = (await row('p1', 'thumb'))!;
      expect(t['url'], '$_be/t.webp?v=h1');
      expect(t['expected_hash'], 'h1');
      expect(t['state'], 'pending');
      expect((await row('p1', 'full'))!['url'], '$_be/i.webp?v=h1');

      // Pretend downloaded.
      await db.update(kSyncedAssetsTable, {
        'state': 'ok',
        'local_hash': 'h1',
        'local_path': '/x/old.webp',
      });

      // Older version: no change.
      await apply(a, up('product', 'p1', 1, product(1, hash: 'zz')));
      expect((await row('p1', 'thumb'))!['state'], 'ok');

      await apply(a, up('product', 'p1', 2, product(2, hash: 'h2')));
      t = (await row('p1', 'thumb'))!;
      expect(t['state'], 'pending');
      expect(t['expected_hash'], 'h2');
      expect(t['local_path'], '/x/old.webp', reason: 'old file kept');

      await apply(a, up('product', 'p1', 3, product(3, image: false)));
      expect(await row('p1', 'thumb'), isNull);
      expect(await row('p1', 'full'), isNull);

      await apply(a, up('product', 'p1', 4, product(4, hash: 'h4')));
      expect(await row('p1', 'thumb'), isNotNull);
      await db.transaction(
        (txn) => a.apply(
          txn,
          const PullChange(seq: 0, entity: 'product', op: 'delete', id: 'p1'),
        ),
      );
      expect(await db.query(kSyncedAssetsTable), isEmpty);
    });

    test('category upsert registers its image', () async {
      final a = CategoryApplier(scopeProvider: () => _scope);
      expect(a.tables, contains(kSyncedAssetsTable));
      await apply(
        a,
        up('category', 'c1', 1, {
          'id': 'c1',
          'version': 1,
          'name': 'Drinks',
          'parent': null,
          'image': '$_be/c.webp',
          'thumbnail_url': '$_be/ct.webp',
          'image_hash': 'hc',
        }),
      );
      final r = await db.query(
        kSyncedAssetsTable,
        where: 'type = ?',
        whereArgs: ['category'],
        orderBy: 'variant',
      );
      expect(r.map((e) => e['variant']), ['full', 'thumb']);
      expect(r.first['expected_hash'], 'hc');
      await db.transaction(
        (txn) => a.apply(
          txn,
          const PullChange(seq: 0, entity: 'category', op: 'delete', id: 'c1'),
        ),
      );
      expect(await db.query(kSyncedAssetsTable), isEmpty);
    });
  });
}
