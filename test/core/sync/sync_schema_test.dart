import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/test_db.dart';

void main() {
  test('outbox has expected columns', () async {
    final offline = await openTestDb();
    final db = await offline.database;
    final cols = (await db.rawQuery(
      'PRAGMA table_info(outbox)',
    )).map((r) => r['name']).toList();
    expect(
      cols,
      containsAll([
        'mutation_id',
        'status',
        'lease_until',
        'depends_on_entity_id',
      ]),
    );
    await db.close();
  });

  test('outbox has (entity_id, seq) index', () async {
    final offline = await openTestDb();
    final db = await offline.database;
    final cols = (await db.rawQuery(
      'PRAGMA index_info(idx_outbox_entity_seq)',
    )).map((r) => r['name']).toList();
    expect(cols, ['entity_id', 'seq']);
    await db.close();
  });

  test('duplicate mutation_id throws', () async {
    final offline = await openTestDb();
    final db = await offline.database;
    Map<String, Object?> row() => {
      'mutation_id': 'm1',
      'entity': 'sale',
      'op': 'create',
      'entity_id': 'e1',
      'occurred_at': '2026-01-01T00:00:00Z',
      'payload_json': '{}',
      'status': 'pending',
      'created_at': '2026-01-01T00:00:00Z',
    };
    await db.insert('outbox', row());
    expect(() => db.insert('outbox', row()), throwsA(isA<DatabaseException>()));
    await db.close();
  });

  test('openTestDb returns independent in-memory databases', () async {
    final a = await (await openTestDb()).database;
    final b = await (await openTestDb()).database;
    await a.insert('outbox', {
      'mutation_id': 'm1',
      'entity': 'sale',
      'op': 'create',
      'entity_id': 'e1',
      'occurred_at': '2026-01-01T00:00:00Z',
      'payload_json': '{}',
      'status': 'pending',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(await a.query('outbox'), hasLength(1));
    expect(await b.query('outbox'), isEmpty);
    await a.close();
    await b.close();
  });
}
