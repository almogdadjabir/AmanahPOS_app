import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

Future<List<String>> _cols(DatabaseExecutor db, String t) async =>
    (await db.rawQuery(
      'PRAGMA table_info($t)',
    )).map((r) => r['name'] as String).toList();

void main() {
  test('fresh onCreate is v15 with shifts and cash_movements', () async {
    expect(OfflineDb.schemaVersion, greaterThanOrEqualTo(15));
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    expect(
      await _cols(db, 'shifts'),
      containsAll([
        'id',
        'shop_id',
        'opened_at',
        'closed_at',
        'opened_by',
        'opened_by_name',
        'closed_by',
        'closed_by_name',
        'opening_cash',
        'expected_cash',
        'counted_cash',
        'note',
        'origin',
        'sync_state',
      ]),
    );
    expect(
      await _cols(db, 'cash_movements'),
      containsAll([
        'id',
        'shift_id',
        'kind',
        'amount',
        'reason',
        'occurred_at',
        'user_id',
        'user_name',
        'sync_state',
      ]),
    );
  });

  test('v14 -> v15 adds the tables, keeps data, and is idempotent', () async {
    sqfliteFfiInit();
    final old = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(old.close);
    await old.execute('CREATE TABLE keepme (id TEXT)');
    await old.insert('keepme', {'id': 'x'});

    await OfflineDb.onUpgrade(old, 14, 15);
    await OfflineDb.onUpgrade(old, 14, 15);
    await OfflineDb.createV15Schema(old);

    expect(await _cols(old, 'shifts'), contains('opening_cash'));
    expect(await _cols(old, 'cash_movements'), contains('shift_id'));
    expect((await old.query('keepme')).single['id'], 'x');
  });
}
