import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';

/// Push results of `debt.payment` and `debt.writeoff`: the local row's
/// `sync_state` becomes `synced` or `rejected` (a rejected row stays visible
/// in the ledger but no longer counts in the balance). Debts are not in the
/// pull feed yet (docs/BE_GAPS_PARITY.md G5), so [apply] ignores anything pulled.
class DebtApplier implements ChangeApplier {
  DebtApplier._(this.entity, this._table);

  factory DebtApplier.debt() => DebtApplier._('debt', 'debt_entries');

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
    final values = <String, Object?>{};
    switch (result.status) {
      case PushStatus.applied:
      case PushStatus.duplicate:
        values['sync_state'] = 'synced';
        values['error_code'] = null;
        values['error_message'] = null;
      case PushStatus.rejected:
        values['sync_state'] = 'rejected';
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
