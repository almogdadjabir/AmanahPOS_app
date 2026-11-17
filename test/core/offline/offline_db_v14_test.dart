import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

Future<List<String>> _cols(DatabaseExecutor db, String t) async =>
    (await db.rawQuery(
      'PRAGMA table_info($t)',
    )).map((r) => r['name'] as String).toList();

Map<String, Object?> _row(String mid, String entityId, String? dep) => {
  'mutation_id': mid,
  'entity': 'sale',
  'op': 'create',
  'entity_id': entityId,
  'depends_on_entity_id': dep,
  'occurred_at': '2026-01-01T00:00:00.000Z',
  'payload_json': '{}',
  'status': 'blocked',
  'created_at': '2026-01-01T00:00:00.000Z',
  'scope': 'u1|t1',
};

void main() {
  test('fresh onCreate is v14 with outbox.depends_on_json', () async {
    expect(OfflineDb.schemaVersion, 14);
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    expect(await _cols(db, SyncTables.outbox), contains('depends_on_json'));
  });

  test('v14 migration backfills the single column into the list and is '
      'idempotent', () async {
    sqfliteFfiInit();
    final old = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(old.close);
    // A v13 outbox (no depends_on_json yet).
    await SyncSchema.createAll(old);
    expect(
      await _cols(old, SyncTables.outbox),
      isNot(contains('depends_on_json')),
    );
    await old.insert(SyncTables.outbox, _row('m1', 's1', 'p1'));
    await old.insert(SyncTables.outbox, _row('m2', 's2', null));

    await OfflineDb.onUpgrade(old, 13, 14);
    await OfflineDb.onUpgrade(old, 13, 14); // idempotent
    await OfflineDb.createV14Schema(old); // also idempotent

    final rows = {
      for (final r in await old.query(SyncTables.outbox)) r['mutation_id']: r,
    };
    expect(jsonDecode(rows['m1']!['depends_on_json'] as String), ['p1']);
    expect(rows['m2']!['depends_on_json'], isNull);
    expect(OutboxEntry.fromRow(rows['m1']!).dependsOn, ['p1']);
    expect(OutboxEntry.fromRow(rows['m2']!).dependsOn, isEmpty);
  });

  test('v14 (Task 5): server_json on catalog tables, outbox error_entity_id; '
      'idempotent, and safe when the catalog tables do not exist', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    for (final t in ['categories', 'products', 'vendors']) {
      expect(await _cols(db, t), contains('server_json'), reason: t);
    }
    expect(
      await _cols(db, SyncTables.outbox),
      containsAll(['error_entity_id', 'claimed_at', 'failed_by_entity_id']),
    );
    await OfflineDb.createV14Schema(db); // idempotent on a fresh DB

    sqfliteFfiInit();
    final bare = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(bare.close);
    await SyncSchema.createAll(bare); // outbox only, no catalog tables
    await OfflineDb.createV14Schema(bare);
    await OfflineDb.createV14Schema(bare);
    expect(await _cols(bare, SyncTables.outbox), contains('error_entity_id'));

    final e = OutboxEntry.fromRow({
      ...OutboxEntry(
        mutationId: 'm',
        entity: 'product',
        op: 'create',
        entityId: 'p',
        occurredAt: DateTime.utc(2026),
        payload: const {},
        errorEntityId: 'other',
      ).toRow(),
    });
    expect(e.errorEntityId, 'other');
  });
}
