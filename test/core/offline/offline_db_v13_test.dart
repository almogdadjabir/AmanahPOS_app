import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

Future<bool> _exists(DatabaseExecutor db, String type, String name) async =>
    (await db.rawQuery(
      'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?',
      [type, name],
    )).isNotEmpty;

void main() {
  test('fresh onCreate is v13 without the legacy bootstrap tables', () async {
    expect(OfflineDb.schemaVersion, 13);
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    for (final t in OfflineDb.legacyBootstrapTables) {
      expect(await _exists(db, 'table', t), isFalse, reason: t);
    }
    expect(await _exists(db, 'table', 'synced_assets'), isTrue);
    // Wipe paths no longer touch the dropped tables.
    await odb.clearAllLocalOfflineData();
  });

  test('v12 -> v13 drops offline_assets + sync_metadata, idempotent, keeps '
      'synced_assets rows', () async {
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
    await old.execute(
      'CREATE INDEX idx_offline_assets_url ON offline_assets(url)',
    );
    await old.execute(
      'CREATE TABLE sync_metadata (key TEXT PRIMARY KEY, value TEXT, '
      'updated_at TEXT NOT NULL)',
    );
    await OfflineDb.createV12Schema(old);
    await old.insert('synced_assets', {
      'type': 'product',
      'id': 'p1',
      'variant': 'thumb',
      'url': 'u',
      'state': 'ok',
    });

    await OfflineDb.onUpgrade(old, 12, 13);
    await OfflineDb.onUpgrade(old, 12, 13); // idempotent

    expect(await _exists(old, 'table', 'offline_assets'), isFalse);
    expect(await _exists(old, 'table', 'sync_metadata'), isFalse);
    expect(await _exists(old, 'index', 'idx_offline_assets_url'), isFalse);
    expect(await old.query('synced_assets'), hasLength(1));
  });
}
