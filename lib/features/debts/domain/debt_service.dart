import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../data/debt_store.dart';

class DebtActor {
  const DebtActor({
    required this.id,
    required this.name,
    required this.canManage,
  });

  final String id;
  final String name;

  /// Owner or manager: may write a debt off.
  final bool canManage;
}

enum DebtError {
  disabled,
  noSession,
  notAllowed,
  amountInvalid,
  exceedsBalance,
  nothingOwed,
  methodInvalid,
}

sealed class DebtResult {
  const DebtResult();
}

class DebtDone extends DebtResult {
  const DebtDone({required this.entryId, required this.balanceAfter});
  final String entryId;
  final BigInt balanceAfter;
}

class DebtFailed extends DebtResult {
  const DebtFailed(this.error);
  final DebtError error;
}

/// The only writer of debt payments and write-offs. One [LocalWriter.write]
/// per call: the local row and its outbox row (`debt.payment` or
/// `debt.writeoff`) commit together, and the balance used for the checks is
/// read in the same transaction. A sale on account is written by the sale
/// service, not here.
class DebtService {
  DebtService({
    required LocalWriter writer,
    required BusinessFeatures Function() features,
    required DebtActor? Function() actor,
    required String? Function() shopId,
    DebtStore store = const DebtStore(),
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _features = features,
       _actor = actor,
       _shopId = shopId,
       _store = store,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final BusinessFeatures Function() _features;
  final DebtActor? Function() _actor;
  final String? Function() _shopId;
  final DebtStore _store;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const Set<String> tables = {'debt_entries', SyncTables.outbox};

  Future<DebtResult> receivePayment({
    required String customerId,
    required BigInt amount,
    required String method,
    String note = '',
  }) {
    if (method != 'cash' && method != 'bankak') {
      return Future.value(const DebtFailed(DebtError.methodInvalid));
    }
    return _write(
      customerId: customerId,
      amount: amount,
      kind: 'payment',
      method: method,
      note: note,
      needsManager: false,
    );
  }

  Future<DebtResult> writeOff({
    required String customerId,
    required BigInt amount,
    String note = '',
  }) => _write(
    customerId: customerId,
    amount: amount,
    kind: 'writeoff',
    method: '',
    note: note,
    needsManager: true,
  );

  Future<DebtResult> _write({
    required String customerId,
    required BigInt amount,
    required String kind,
    required String method,
    required String note,
    required bool needsManager,
  }) async {
    if (!_features().onAccount) return const DebtFailed(DebtError.disabled);
    final actor = _actor();
    if (actor == null) return const DebtFailed(DebtError.noSession);
    if (needsManager && !actor.canManage) {
      return const DebtFailed(DebtError.notAllowed);
    }
    if (amount <= BigInt.zero) return const DebtFailed(DebtError.amountInvalid);
    final at = _now().toUtc();
    final id = _uuid.v4();
    final text = Cents.format(amount);
    final why = note.trim();

    return _writer.write<DebtResult>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final balance = await _store.balance(txn, customerId);
        if (balance <= BigInt.zero) {
          return const DebtFailed(DebtError.nothingOwed);
        }
        if (amount > balance) return const DebtFailed(DebtError.exceedsBalance);
        await txn.insert('debt_entries', {
          'id': id,
          'customer_id': customerId,
          'shop_id': _shopId(),
          'kind': kind,
          'amount': text,
          'method': method,
          'note': why,
          'occurred_at': at.toIso8601String(),
          'user_id': actor.id,
          'user_name': actor.name,
          'sync_state': 'pending',
        });
        await scope.enqueue(
          entity: 'debt',
          op: kind,
          entityId: id,
          occurredAt: at,
          payload: {
            'customer': customerId,
            'amount': text,
            if (method.isNotEmpty) 'method': method,
            'note': why,
            'occurred_at': at.toIso8601String(),
          },
        );
        return DebtDone(entryId: id, balanceAfter: balance - amount);
      },
    );
  }
}
