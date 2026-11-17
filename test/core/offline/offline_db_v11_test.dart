import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

Future<Set<String>> _cols(DatabaseExecutor db, String t) async =>
    (await db.rawQuery(
      'PRAGMA table_info($t)',
    )).map((r) => r['name'] as String).toSet();

void main() {
  test('fresh onCreate has the v11 columns and synced_entities', () async {
    expect(OfflineDb.schemaVersion, greaterThanOrEqualTo(11));
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    for (final t in [
      'businesses',
      'shops',
      'categories',
      'products',
      'customers',
      'vendors',
    ]) {
      expect(await _cols(db, t), contains('version'), reason: t);
    }
    for (final t in ['categories', 'products']) {
      expect(await _cols(db, t), contains('image_hash'), reason: t);
    }
    expect(
      await _cols(db, 'synced_entities'),
      containsAll(['entity', 'id', 'version', 'json', 'updated_at']),
    );
    expect(
      await _cols(db, 'sale_refunds'),
      containsAll([
        'id',
        'sale_id',
        'shop_id',
        'total',
        'occurred_at',
        'method',
        'json',
      ]),
    );
  });

  test('v10 -> v11 adds the columns, idempotent, keeps rows', () async {
    sqfliteFfiInit();
    final old = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(old.close);
    for (final t in [
      'businesses',
      'shops',
      'categories',
      'products',
      'customers',
      'vendors',
    ]) {
      await old.execute('CREATE TABLE $t (id TEXT PRIMARY KEY, json TEXT)');
    }
    await old.insert('products', {'id': 'p1', 'json': '{}'});

    await OfflineDb.onUpgrade(old, 10, 11);
    await OfflineDb.onUpgrade(old, 10, 11); // idempotent

    for (final t in [
      'businesses',
      'shops',
      'categories',
      'products',
      'customers',
      'vendors',
    ]) {
      expect(await _cols(old, t), contains('version'), reason: t);
    }
    expect(await _cols(old, 'products'), contains('image_hash'));
    expect(await _cols(old, 'categories'), contains('image_hash'));
    expect(await _cols(old, 'synced_entities'), contains('json'));
    expect(await _cols(old, 'sale_refunds'), contains('occurred_at'));
    expect(await old.query('products'), hasLength(1));
  });
}
