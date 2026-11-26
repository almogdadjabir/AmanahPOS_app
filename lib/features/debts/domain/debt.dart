enum DebtLedgerKind { sale, payment, writeoff }

/// One row of a customer's ledger. [amount] is always positive; the kind says
/// whether it adds to the debt (sale on account) or takes from it.
class DebtLedgerEntry {
  const DebtLedgerEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.at,
    this.method = '',
    this.note = '',
    this.userName,
    this.receiptNumber,
    this.rejected = false,
  });

  final String id;
  final DebtLedgerKind kind;
  final BigInt amount;
  final DateTime at;
  final String method;
  final String note;
  final String? userName;
  final String? receiptNumber;

  /// The server refused it (a payment or write-off). Kept for the record, not
  /// counted in the balance.
  final bool rejected;

  bool get adds => kind == DebtLedgerKind.sale;
}

/// A customer who owes money.
class Debtor {
  const Debtor({
    required this.customerId,
    required this.name,
    required this.balance,
    this.lastAt,
  });

  final String customerId;
  final String name;
  final BigInt balance;
  final DateTime? lastAt;
}
