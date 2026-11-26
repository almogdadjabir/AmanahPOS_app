import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';

/// Push results of `shift.*` and `cash_movement.create`: the local row's
/// `sync_state` becomes `synced` or `rejected`.
///
/// Shifts and cash movements are not in the pull feed yet
/// (docs/BE_GAPS_PARITY.md G5), so [apply] ignores anything pulled. A
/// rejected `shift.open` or movement voids the row (kept, excluded from every
/// figure); a rejected close or count keeps the shift as it is and only
/// records the error, because the shift itself exists on the server.
class ShiftApplier implements ChangeApplier {
  ShiftApplier._(this.entity, this._table);

  factory ShiftApplier.shift() => ShiftApplier._('shift', 'shifts');
  factory ShiftApplier.cashMovement() =>
      ShiftApplier._('cash_movement', 'cash_movements');

  @override
  final String entity;
  final String _table;

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => {_table};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async => null;

  @override
  Future<void> apply(Transaction txn, PullChange change) async {}

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    final creates = entity == 'cash_movement' || sent.op == 'open';
    final values = <String, Object?>{};
    switch (result.status) {
      case PushStatus.applied:
      case PushStatus.duplicate:
        if (!creates) return;
        values['sync_state'] = 'synced';
        values['error_code'] = null;
        values['error_message'] = null;
      case PushStatus.rejected:
        if (creates) values['sync_state'] = 'rejected';
        values['error_code'] = result.code;
        values['error_message'] = result.message;
      case PushStatus.retry:
        return;
    }
    await txn.update(
      _table,
      values,
      where: 'id = ?',
      whereArgs: [sent.entityId],
    );
  }
}
