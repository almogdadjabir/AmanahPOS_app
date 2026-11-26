import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/debt.dart';

/// Reads what customers owe from this phone's records:
/// balance = sales on account (the `credit` part of a live sale)
///           - payments - write-offs (rows not rejected by the server).
/// Refunds of an on-account sale are not created on mobile, so none count.
class DebtStore {
  const DebtStore();

  static const _liveSale = "s.status != 'cancelled' AND s.sync_state != 'rejected'";

  static BigInt _c(Object? v) => Cents.parse('$v') ?? BigInt.zero;

  /// Credit taken in the sale rows of [customerId]: from the payment parts, or
  /// the whole net for an old single-method `credit` sale with no parts.
  Future<List<Map<String, Object?>>> _creditSales(
    DatabaseExecutor db, {
    String? customerId,
  }) async {
    final where = customerId == null ? '' : 'AND s.customer_id = ?';
    final args = customerId == null ? <Object?>[] : [customerId];
    final parts = await db.rawQuery(
      'SELECT s.id AS sale_id, s.customer_id, s.occurred_at, s.receipt_number, '
      's.local_receipt_number, p.amount '
      'FROM sale_payments p JOIN sales s ON s.id = p.sale_id '
      "WHERE p.method = 'credit' AND s.customer_id IS NOT NULL AND $_liveSale $where",
      args,
    );
    final legacy = await db.rawQuery(
      'SELECT s.id AS sale_id, s.customer_id, s.occurred_at, s.receipt_number, '
      's.local_receipt_number, s.net_amount AS amount FROM sales s '
      "WHERE s.payment_method = 'credit' AND s.customer_id IS NOT NULL "
      'AND NOT EXISTS (SELECT 1 FROM sale_payments p WHERE p.sale_id = s.id) '
      'AND $_liveSale $where',
      args,
    );
    return [...parts, ...legacy];
  }

  Future<BigInt> balance(DatabaseExecutor db, String customerId) async {
    var sum = BigInt.zero;
    for (final r in await _creditSales(db, customerId: customerId)) {
      sum += _c(r['amount']);
    }
    for (final r in await db.rawQuery(
      'SELECT amount FROM debt_entries WHERE customer_id = ? '
      "AND sync_state != 'rejected'",
      [customerId],
    )) {
      sum -= _c(r['amount']);
    }
    return sum;
  }

  /// Newest first.
  Future<List<DebtLedgerEntry>> ledger(
    DatabaseExecutor db,
    String customerId,
  ) async {
    final out = <DebtLedgerEntry>[];
    for (final r in await _creditSales(db, customerId: customerId)) {
      out.add(
        DebtLedgerEntry(
          id: 'sale-${r['sale_id']}',
          kind: DebtLedgerKind.sale,
          amount: _c(r['amount']),
          at: DateTime.parse('${r['occurred_at']}').toUtc(),
          receiptNumber:
              (r['receipt_number'] ?? r['local_receipt_number']) as String?,
        ),
      );
    }
    for (final r in await db.query(
      'debt_entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    )) {
      out.add(
        DebtLedgerEntry(
          id: r['id'] as String,
          kind: r['kind'] == 'writeoff'
              ? DebtLedgerKind.writeoff
              : DebtLedgerKind.payment,
          amount: _c(r['amount']),
          at: DateTime.parse('${r['occurred_at']}').toUtc(),
          method: (r['method'] as String?) ?? '',
          note: (r['note'] as String?) ?? '',
          userName: r['user_name'] as String?,
          rejected: r['sync_state'] == 'rejected',
        ),
      );
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  /// Every customer with a balance above zero, biggest first.
  Future<List<Debtor>> debtors(DatabaseExecutor db) async {
    final bal = <String, BigInt>{};
    final last = <String, DateTime>{};
    void seen(String id, String at) {
      final t = DateTime.parse(at).toUtc();
      final o = last[id];
      if (o == null || t.isAfter(o)) last[id] = t;
    }

    for (final r in await _creditSales(db)) {
      final id = r['customer_id'] as String;
      bal[id] = (bal[id] ?? BigInt.zero) + _c(r['amount']);
      seen(id, '${r['occurred_at']}');
    }
    for (final r in await db.query(
      'debt_entries',
      where: "sync_state != 'rejected'",
    )) {
      final id = r['customer_id'] as String;
      bal[id] = (bal[id] ?? BigInt.zero) - _c(r['amount']);
      seen(id, '${r['occurred_at']}');
    }
    final names = <String, String>{
      for (final c in await db.query('customers', columns: ['id', 'name']))
        c['id'] as String: (c['name'] as String?) ?? '',
    };
    final out = [
      for (final e in bal.entries)
        if (e.value > BigInt.zero)
          Debtor(
            customerId: e.key,
            name: names[e.key] ?? '',
            balance: e.value,
            lastAt: last[e.key],
          ),
    ]..sort((a, b) => b.balance.compareTo(a.balance));
    return out;
  }

  /// Cash debt payments taken in [shopId] over `[from, to)` (UTC texts), for
  /// the shift's drawer.
  Future<BigInt> cashPaymentsIn(
    DatabaseExecutor db, {
    required String shopId,
    required String from,
    required String to,
  }) async {
    var sum = BigInt.zero;
    for (final r in await db.rawQuery(
      "SELECT amount FROM debt_entries WHERE kind = 'payment' "
      "AND method = 'cash' AND sync_state != 'rejected' "
      'AND shop_id = ? AND occurred_at >= ? AND occurred_at < ?',
      [shopId, from, to],
    )) {
      sum += _c(r['amount']);
    }
    return sum;
  }
}
