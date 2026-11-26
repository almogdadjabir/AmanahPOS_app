import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';

import '../domain/debt.dart';
import 'debt_store.dart';

/// A customer as the picker shows it.
class PickCustomer {
  const PickCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.owes,
  });

  final String id;
  final String name;
  final String phone;
  final BigInt owes;
}

/// Live reads of what customers owe, for screens. Everything re-reads when a
/// sale, a payment row or a customer changes.
class DebtReader {
  DebtReader({required OfflineDb db, required DbChangeNotifier notifier})
    : _db = db,
      _notifier = notifier;

  final OfflineDb _db;
  final DbChangeNotifier _notifier;
  static const DebtStore _store = DebtStore();
  static const Set<String> _tables = {
    'sales',
    'sale_payments',
    'debt_entries',
    'customers',
  };

  Future<BigInt> balance(String customerId) async =>
      _store.balance(await _db.database, customerId);

  Stream<BigInt> watchBalance(String customerId) => _notifier.watch(
    tables: _tables,
    query: () => balance(customerId),
  );

  Stream<List<DebtLedgerEntry>> watchLedger(String customerId) =>
      _notifier.watch(
        tables: _tables,
        query: () async => _store.ledger(await _db.database, customerId),
      );

  Stream<List<Debtor>> watchDebtors() => _notifier.watch(
    tables: _tables,
    query: () async => _store.debtors(await _db.database),
  );

  /// Active customers matching [query] (name or phone), by name.
  Future<List<PickCustomer>> customers(String query) async {
    final db = await _db.database;
    final q = query.trim().replaceAll('%', r'\%').replaceAll('_', r'\_');
    final rows = await db.query(
      'customers',
      where: q.isEmpty
          ? null
          : "name LIKE ? ESCAPE '\\' OR phone LIKE ? ESCAPE '\\'",
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE ASC, id ASC',
      limit: 200,
    );
    final owing = {
      for (final d in await _store.debtors(db)) d.customerId: d.balance,
    };
    return [
      for (final r in rows)
        if (!'${r['json']}'.contains('"is_active":false'))
          PickCustomer(
            id: r['id'] as String,
            name: (r['name'] as String?) ?? '',
            phone: (r['phone'] as String?) ?? '',
            owes: owing[r['id']] ?? BigInt.zero,
          ),
    ];
  }
}
