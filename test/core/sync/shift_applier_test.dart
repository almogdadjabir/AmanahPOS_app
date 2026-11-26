import 'package:amana_pos/core/sync/appliers/shift_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

OutboxEntry sent(String entity, String op, String id) => OutboxEntry(
  mutationId: 'm',
  entity: entity,
  op: op,
  entityId: id,
  occurredAt: DateTime.utc(2026),
  payload: const {},
);

PushResult res(PushStatus s, {String? code, String? message}) => PushResult(
  mutationId: 'm',
  status: s,
  code: code,
  message: message,
);

void main() {
  test('both entities are registered', () {
    final r = buildSyncAppliers();
    expect(r.of('shift'), isA<ShiftApplier>());
    expect(r.of('cash_movement'), isA<ShiftApplier>());
  });

  test('push results set sync_state', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    await db.insert('shifts', {
      'id': 's1', 'shop_id': 'x', 'opened_at': '2026-01-01T00:00:00Z',
    });
    await db.insert('shifts', {
      'id': 's2', 'shop_id': 'x', 'opened_at': '2026-01-01T00:00:00Z',
    });
    await db.insert('cash_movements', {
      'id': 'm1', 'shift_id': 's1', 'kind': 'pay_in', 'amount': '1',
      'occurred_at': '2026-01-01T00:00:00Z',
    });
    final shift = ShiftApplier.shift();
    final move = ShiftApplier.cashMovement();

    await db.transaction((t) async {
      await shift.onPushResult(
          t, sent('shift', 'open', 's1'), res(PushStatus.applied));
      await shift.onPushResult(
          t,
          sent('shift', 'open', 's2'),
          res(PushStatus.rejected, code: 'not_allowed', message: 'No'));
      await move.onPushResult(
          t, sent('cash_movement', 'create', 'm1'), res(PushStatus.duplicate));
    });
    String st(List<Map<String, Object?>> r) => r.single['sync_state'] as String;
    expect(st(await db.query('shifts', where: "id='s1'")), 'synced');
    final s2 = (await db.query('shifts', where: "id='s2'")).single;
    expect(s2['sync_state'], 'rejected');
    expect(s2['error_code'], 'not_allowed');
    expect(st(await db.query('cash_movements')), 'synced');
  });

  test('a rejected close keeps the shift usable and records the error',
      () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    await db.insert('shifts', {
      'id': 's1', 'shop_id': 'x', 'opened_at': '2026-01-01T00:00:00Z',
      'sync_state': 'synced',
    });
    await db.transaction((t) => ShiftApplier.shift().onPushResult(
        t,
        sent('shift', 'close', 's1'),
        res(PushStatus.rejected, code: 'validation_error')));
    final r = (await db.query('shifts')).single;
    expect(r['sync_state'], 'synced');
    expect(r['error_code'], 'validation_error');
  });
}
