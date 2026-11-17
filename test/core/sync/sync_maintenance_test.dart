import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/maintenance/sync_maintenance.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/test_db.dart';

void main() {
  late OfflineDb odb;
  late Database db;
  late DateTime clock;
  late OutboxStore outbox;
  late SyncStateStore state;
  String? scope = 'u1|t1';
  late SyncMaintenance m;

  setUp(() async {
    scope = 'u1|t1';
    odb = await openTestDb();
    db = await odb.database;
    clock = DateTime.utc(2026, 3, 1, 12);
    outbox = OutboxStore(odb, now: () => clock);
    state = SyncStateStore(odb, now: () => clock);
    m = SyncMaintenance(
      outbox: outbox,
      state: state,
      scopeProvider: () => scope,
      now: () => clock,
    );
  });
  tearDown(() async => db.close());

  Future<String> row(String id, String status, Duration age) async {
    final e = await outbox.enqueue(
      db,
      entity: 'product',
      op: 'update',
      entityId: id,
      payload: {'a': 1},
      scope: 'u1|t1',
    );
    await db.update(
      'outbox',
      {'status': status, 'created_at': clock.subtract(age).toIso8601String()},
      where: 'mutation_id = ?',
      whereArgs: [e.mutationId],
    );
    return e.mutationId;
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM outbox'))!;

  test('prunes old done rows, keeps young done, open and rejected', () async {
    await row('a', 'done', const Duration(days: 8));
    await row('b', 'done', const Duration(days: 2));
    await row('c', 'pending', const Duration(days: 30));
    await row('d', 'rejected', const Duration(days: 30));
    expect(await m.maybeRun(), 1);
    expect(await count(), 3);
  });

  test('second run within 24h prunes nothing', () async {
    expect(await m.maybeRun(), 0);
    await row('a', 'done', const Duration(days: 8));
    clock = clock.add(const Duration(hours: 23));
    expect(await m.maybeRun(), 0);
    expect(await count(), 1);
  });

  test('runs again after 24h', () async {
    await m.maybeRun();
    await row('a', 'done', const Duration(days: 8));
    clock = clock.add(const Duration(hours: 25));
    expect(await m.maybeRun(), 1);
  });

  test('last run in the future (clock moved back) runs anyway', () async {
    await state
        .forScope('u1|t1')
        .setLastPruneAt(clock.add(const Duration(days: 3)));
    await row('a', 'done', const Duration(days: 8));
    expect(await m.maybeRun(), 1);
  });

  test('no scope -> 0 and nothing written', () async {
    scope = null;
    await row('a', 'done', const Duration(days: 8));
    expect(await m.maybeRun(), 0);
    expect(await count(), 1);
    expect(await state.forScope('u1|t1').lastPruneAt(), isNull);
  });

  test('clear() removes prune_last_at', () async {
    final s = state.forScope('u1|t1');
    await s.setLastPruneAt(clock);
    await s.clear();
    expect(await s.lastPruneAt(), isNull);
  });
}
