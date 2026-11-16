import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

Future<Set<String>> _tables(DatabaseExecutor db) async => (await db.rawQuery(
  "SELECT name FROM sqlite_master WHERE type = 'table'",
)).map((r) => r['name'] as String).toSet();

void main() {
  test('schema v10: fresh onCreate never creates the legacy queues', () async {
    expect(OfflineDb.schemaVersion, 10);
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    final names = await _tables(db);
    for (final t in OfflineDb.legacyQueueTables) {
      expect(names, isNot(contains(t)));
    }
    expect(names, containsAll(['outbox', 'sales', 'stock', 'products']));
    // Wipes no longer reference the dropped tables.
    await odb.clearAllLocalOfflineData();
  });

  test('v9 -> v10 drops the legacy queue tables (with rows), idempotent; '
      'everything else untouched', () async {
    sqfliteFfiInit();
    final old = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(old.close);
    await old.execute('PRAGMA foreign_keys = ON');
    await old.execute(
      'CREATE TABLE pending_sales (client_sale_id TEXT PRIMARY KEY, '
      'status TEXT)',
    );
    await old.execute(
      'CREATE INDEX idx_pending_sales_status ON pending_sales(status)',
    );
    await old.execute(
      'CREATE TABLE pending_sale_items (id INTEGER PRIMARY KEY, '
      'client_sale_id TEXT NOT NULL, FOREIGN KEY(client_sale_id) '
      'REFERENCES pending_sales(client_sale_id) ON DELETE CASCADE)',
    );
    await old.execute(
      'CREATE TABLE pending_inbound_transactions '
      '(client_inbound_id TEXT PRIMARY KEY)',
    );
    await old.execute('CREATE TABLE keep_me (id TEXT PRIMARY KEY)');
    await old.insert('pending_sales', {'client_sale_id': 'c1'});
    await old.insert('pending_sale_items', {'client_sale_id': 'c1'});
    await old.insert('pending_inbound_transactions', {
      'client_inbound_id': 'i1',
    });
    await old.insert('keep_me', {'id': 'k'});

    await OfflineDb.onUpgrade(old, 9, 10);
    await OfflineDb.onUpgrade(old, 9, 10); // idempotent

    final names = await _tables(old);
    for (final t in OfflineDb.legacyQueueTables) {
      expect(names, isNot(contains(t)));
    }
    final indexes = await old.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND name LIKE 'idx_pending_%'",
    );
    expect(indexes, isEmpty);
    expect(await old.query('keep_me'), hasLength(1));
  });
}
