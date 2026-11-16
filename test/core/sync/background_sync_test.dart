import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/background/background_sync.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/engine_harness.dart';

String _jwt(Map<String, Object?> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.sig';
}

void main() {
  late EngineHarness h;
  var factoryCalls = 0;

  setUp(() async {
    h = await EngineHarness.create();
    factoryCalls = 0;
  });

  tearDown(() async {
    await h.dispose();
  });

  Future<SyncEngine> factory(String scope) async {
    factoryCalls++;
    h.activeScope = scope;
    return h.build();
  }

  Future<String?> session() async => EngineHarness.scope;

  Future<int> unsynced() async =>
      await h.countStatus('pending') + await h.countStatus('inflight');

  test(
    'no session: returns without building an engine or any network call',
    () async {
      await h.createWidget('w1');

      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: () async => null,
        engineFactory: factory,
      );

      expect(report.result, BackgroundSyncResult.noSession);
      expect(report.shouldRetry, isFalse);
      expect(factoryCalls, 0);
      expect(h.transport.pushCalls, 0);
      expect(h.transport.pullCalls, 0);
      expect(await h.countStatus('pending'), 1);
    },
  );

  test('session + backlog + server up: drains and reports success', () async {
    for (var i = 0; i < 3; i++) {
      await h.createWidget('w$i');
    }

    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: session,
      engineFactory: factory,
    );

    expect(report.result, BackgroundSyncResult.success);
    expect(report.outcome, SyncOutcome.completed);
    expect(report.shouldRetry, isFalse);
    expect(await unsynced(), 0);
    expect(h.serverProductCount, 3);
  });

  test(
    'lease held by a live foreground run: alreadyRunning, no error',
    () async {
      await h.createWidget('w1');
      expect(
        await h.state.acquireLock('foreground', const Duration(minutes: 2)),
        isTrue,
      );

      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
      );

      expect(report.result, BackgroundSyncResult.alreadyRunning);
      expect(report.shouldRetry, isFalse);
      expect(h.transport.pushCalls, 0);
      expect(await h.countStatus('pending'), 1);
    },
  );

  test('budget exceeded: stops between batches and reports partial', () async {
    for (var i = 0; i < 250; i++) {
      await h.createWidget('w$i');
    }
    h.server.latency = const Duration(milliseconds: 100);

    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: session,
      engineFactory: factory,
      budget: const Duration(milliseconds: 250),
      hardStopGrace: const Duration(seconds: 5),
    );

    expect(report.result, BackgroundSyncResult.partial);
    expect(report.outcome, SyncOutcome.cancelled);
    expect(report.shouldRetry, isTrue);
    expect(h.serverProductCount, lessThan(250));
    expect(await h.countStatus('inflight'), 0, reason: 'nothing left claimed');
    expect(await unsynced(), 250 - h.serverProductCount);
  });

  test('a call hanging past budget + grace returns partial on time', () async {
    await h.createWidget('w1');
    h.server.latency = const Duration(milliseconds: 400);

    final sw = Stopwatch()..start();
    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: session,
      engineFactory: factory,
      budget: const Duration(milliseconds: 50),
      hardStopGrace: const Duration(milliseconds: 50),
    );
    sw.stop();

    expect(report.result, BackgroundSyncResult.partial);
    expect(report.outcome, isNull);
    expect(sw.elapsed, lessThan(const Duration(milliseconds: 350)));
    // Let the abandoned run finish before the database is closed.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
  });

  test('server down (backoff) maps to retryLater', () async {
    await h.createWidget('w1');
    h.server.down = true;

    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: session,
      engineFactory: factory,
    );

    expect(report.outcome, SyncOutcome.backoff);
    expect(report.result, BackgroundSyncResult.retryLater);
    expect(report.shouldRetry, isTrue);
    expect(await h.countStatus('pending'), 1);
  });

  test('blocked (app too old) maps to retryLater', () async {
    await h.createWidget('w1');
    h.server.minAppVersion = '99.0.0';

    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: session,
      engineFactory: factory,
    );

    expect(report.outcome, SyncOutcome.blocked);
    expect(report.result, BackgroundSyncResult.retryLater);
    expect(h.transport.pushCalls, 0);
  });

  test(
    'gate says the server has no sync capability: skipped, no engine',
    () async {
      final report = await BackgroundSyncRunner.runOnce(
        readSessionKey: session,
        engineFactory: factory,
        canSync: () async => false,
      );

      expect(report.result, BackgroundSyncResult.skipped);
      expect(report.shouldRetry, isFalse);
      expect(factoryCalls, 0);
    },
  );

  test('engine factory failure maps to retryLater without throwing', () async {
    final report = await BackgroundSyncRunner.runOnce(
      readSessionKey: session,
      engineFactory: (_) async => throw StateError('db busy'),
    );

    expect(report.result, BackgroundSyncResult.retryLater);
  });

  group('storageSessionKey', () {
    test('user_id claim + tenant', () {
      expect(
        BackgroundSyncRunner.storageSessionKey(
          _jwt({'user_id': 'u-1', 'exp': 1}),
          't-9',
        ),
        'u-1|t-9',
      );
    });

    test('missing token, tenant or claim -> null', () {
      final tok = _jwt({'user_id': 'u-1'});
      expect(BackgroundSyncRunner.storageSessionKey(null, 't'), isNull);
      expect(BackgroundSyncRunner.storageSessionKey(tok, null), isNull);
      expect(BackgroundSyncRunner.storageSessionKey(tok, ''), isNull);
      expect(
        BackgroundSyncRunner.storageSessionKey(_jwt({'sub': 'x'}), 't'),
        isNull,
      );
      expect(BackgroundSyncRunner.storageSessionKey('garbage', 't'), isNull);
    });
  });

  test(
    'OfflineDb.onConfigure sets WAL and busy_timeout on a file db',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('amana_wal');
      final path = '${dir.path}/t.db';
      try {
        final db = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            singleInstance: false,
            version: OfflineDb.schemaVersion,
            onConfigure: OfflineDb.onConfigure,
            onCreate: OfflineDb.onCreate,
          ),
        );
        final mode = await db.rawQuery('PRAGMA journal_mode');
        final busy = await db.rawQuery('PRAGMA busy_timeout');
        expect(mode.single.values.single.toString().toLowerCase(), 'wal');
        expect(busy.single.values.single, OfflineDb.busyTimeoutMs);

        // A second connection on the same file (the other isolate) can read
        // and write while the first one is open.
        final other = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            singleInstance: false,
            version: OfflineDb.schemaVersion,
            onConfigure: OfflineDb.onConfigure,
            onCreate: OfflineDb.onCreate,
          ),
        );
        await other.insert('sync_state', {
          'key': 'k',
          'value': 'v',
          'updated_at': '2026-11-16T00:00:00Z',
        });
        expect(
          (await db.query(
            'sync_state',
            where: 'key = ?',
            whereArgs: ['k'],
          )).single['value'],
          'v',
        );
        await other.close();
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
