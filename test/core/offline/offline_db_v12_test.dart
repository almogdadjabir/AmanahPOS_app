import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

Future<Set<String>> _cols(DatabaseExecutor db, String t) async =>
    (await db.rawQuery(
      'PRAGMA table_info($t)',
    )).map((r) => r['name'] as String).toSet();

const _assetCols = [
  'type',
  'id',
  'variant',
  'url',
  'expected_hash',
  'local_path',
  'local_hash',
  'bytes',
  'state',
  'attempts',
  'next_attempt_at',
];

void main() {
  test('fresh onCreate has synced_assets (legacy offline_assets is gone '
      'since v13)', () async {
    expect(OfflineDb.schemaVersion, greaterThanOrEqualTo(12));
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    expect(await _cols(db, 'synced_assets'), containsAll(_assetCols));
    expect(await _cols(db, 'offline_assets'), isEmpty);
  });

  test('synced_assets: PK(type,id,variant), attempts defaults to 0', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    await db.insert('synced_assets', {
      'type': 'product',
      'id': 'p1',
      'variant': 'thumb',
      'url': 'https://x/t.webp',
      'expected_hash': 'h',
      'state': 'pending',
    });
    await db.insert('synced_assets', {
      'type': 'product',
      'id': 'p1',
      'variant': 'full',
      'url': 'https://x/i.webp',
      'expected_hash': 'h',
      'state': 'pending',
    });
    final r = await db.query('synced_assets', orderBy: 'variant');
    expect(r, hasLength(2));
    expect(r.first['attempts'], 0);
    expect(
      () => db.insert('synced_assets', {
        'type': 'product',
        'id': 'p1',
        'variant': 'thumb',
        'url': 'u',
        'state': 'pending',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('v11 -> v12 adds synced_assets, idempotent, keeps rows', () async {
    sqfliteFfiInit();
    final old = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(old.close);
    await old.execute(
      'CREATE TABLE offline_assets (id TEXT NOT NULL, type TEXT NOT NULL, '
      'url TEXT NOT NULL, hash TEXT, updated_at TEXT, local_path TEXT, '
      'downloaded_at TEXT, PRIMARY KEY(id, type))',
    );
    await old.insert('offline_assets', {
      'id': 'p1',
      'type': 'product',
      'url': 'u',
    });

    await OfflineDb.onUpgrade(old, 11, 12);
    await OfflineDb.onUpgrade(old, 11, 12); // idempotent

    expect(await _cols(old, 'synced_assets'), containsAll(_assetCols));
    expect(await old.query('offline_assets'), hasLength(1));
  });

  test('catalog wipes clear synced_assets and notify it', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    final notified = <Set<String>>[];
    odb.onTablesChanged = notified.add;
    bool saw() => notified.any((t) => t.contains('synced_assets'));
    Future<void> seed() => db.insert('synced_assets', {
      'type': 'product',
      'id': 'p1',
      'variant': 'thumb',
      'url': 'u',
      'state': 'ok',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await seed();
    await odb.clearAllLocalOfflineData();
    expect(await db.query('synced_assets'), isEmpty);
    expect(saw(), isTrue);
    notified.clear();
    await seed();
    await OfflineLocalCache(odb).clearAllOnLogout();
    expect(await db.query('synced_assets'), isEmpty);
    expect(saw(), isTrue);
  });
}
