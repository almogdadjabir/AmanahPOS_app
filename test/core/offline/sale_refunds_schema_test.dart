import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

void main() {
  test('sale_refunds has sync_state/reference/error columns on create', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    final cols = {
      for (final c in await db.rawQuery('PRAGMA table_info(sale_refunds)'))
        c['name'] as String: c,
    };
    expect(
      cols.keys,
      containsAll(['reference', 'sync_state', 'error_code', 'error_message', 'reason']),
    );
    await db.insert('sale_refunds', {'id': 'r1', 'sale_id': 's'});
    expect((await db.query('sale_refunds')).single['sync_state'], 'synced');
    await db.close();
  });

  test('upgrade step adds the columns to an older sale_refunds, idempotently', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE sale_refunds (id TEXT PRIMARY KEY, sale_id TEXT, '
      'shop_id TEXT, total TEXT, occurred_at TEXT, method TEXT, json TEXT)',
    );
    await SyncSchema.createAll(db);
    await db.insert('sale_refunds', {'id': 'old', 'sale_id': 's'});
    await OfflineDb.createV14Schema(db);
    await OfflineDb.createV14Schema(db);
    final row = (await db.query('sale_refunds')).single;
    expect(row['sync_state'], 'synced');
    expect(row.containsKey('reference'), isTrue);
    await db.close();
  });
}
