import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/inventory/data/local/stock_local_store.dart';
import 'appliers/applier_support.dart';
import 'sync_schema.dart';

/// Review M1: logout wipes the catalog tables but keeps the outbox. A
/// product / category / vendor with an unsynced outbox row (a local-only
/// create, a rejected create, a pending edit) would then be missing after
/// the next sign-in: from the POS until its push lands, and for good from
/// "Edit and retry" ("edit gone").
///
/// [stashForLogout] copies those local rows (and a product's stock rows),
/// per outbox scope, into `sync_state` in the logout's own transaction.
/// [restore] puts them back when the SAME scope finishes its bootstrap
/// (`Bootstrapper` final commit), only where the bootstrap wrote no row
/// (a server row always wins; a row with a pending edit was deferred by the
/// bootstrap, so the local copy stands in until its push lands). Another
/// account never sees them: the stash is keyed by scope.
class CatalogStash {
  const CatalogStash._();

  static const String _keyPrefix = 'catalog_stash|';

  /// Catalog entity -> local table.
  static const Map<String, String> _tables = {
    'product': 'products',
    'category': 'categories',
    'vendor': 'vendors',
  };

  static String keyOf(String scope) => '$_keyPrefix$scope';

  /// Copies every catalog row with an open outbox row into the stash of
  /// that row's scope. Call inside the logout transaction, BEFORE the
  /// tables are wiped. An existing stash of a scope (two logouts without a
  /// bootstrap in between) is kept and extended.
  static Future<void> stashForLogout(Transaction txn) async {
    final open = await txn.rawQuery(
      'SELECT DISTINCT scope, entity, entity_id FROM ${SyncTables.outbox} '
      "WHERE status != 'done' AND scope IS NOT NULL "
      "AND entity IN ('product','category','vendor')",
    );
    final byScope = <String, List<Map<String, Object?>>>{};
    for (final o in open) {
      final scope = o['scope'] as String;
      final entity = o['entity'] as String;
      final id = o['entity_id'] as String;
      final table = _tables[entity]!;
      final rows = await _query(txn, table, 'id', id);
      if (rows.isEmpty) continue;
      final list = byScope.putIfAbsent(scope, () => []);
      list.add({'t': table, 'r': rows.first});
      if (entity == 'product') {
        for (final s in await _query(txn, 'stock', 'product_id', id)) {
          list.add({'t': 'stock', 'r': s});
        }
      }
    }
    for (final e in byScope.entries) {
      final key = keyOf(e.key);
      final prev = await _read(txn, key);
      final seen = {
        for (final x in e.value) '${x['t']}|${(x['r'] as Map)['id']}',
      };
      final merged = [
        for (final x in prev)
          if (!seen.contains('${x['t']}|${(x['r'] as Map)['id']}')) x,
        ...e.value,
      ];
      await txn.insert(SyncTables.syncState, {
        'key': key,
        'value': jsonEncode(merged),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Puts [scope]'s stashed rows back where no row exists, re-derives the
  /// restored products' stock and category counts, and clears the stash.
  /// Returns the tables written.
  static Future<Set<String>> restore(Transaction txn, String scope) async {
    final key = keyOf(scope);
    final stash = await _read(txn, key);
    if (stash.isEmpty) {
      await txn.delete(
        SyncTables.syncState,
        where: 'key = ?',
        whereArgs: [key],
      );
      return const {};
    }
    final touched = <String>{};
    final restoredProducts = <String>{};
    final pairs = <(String, String)>{};
    final categories = <String?>{};
    // Catalog rows first: a stock row is only restored for a product that
    // was restored itself (a server product keeps the bootstrapped stock).
    for (final x in stash) {
      final table = x['t'] as String;
      if (table == 'stock') continue;
      final row = Map<String, Object?>.from(x['r'] as Map);
      final n = await _insertIfAbsent(txn, table, row);
      if (n == 0) continue;
      touched.add(table);
      if (table == 'products') {
        restoredProducts.add(row['id'] as String);
        categories.add(row['category_id'] as String?);
      }
    }
    for (final x in stash) {
      if (x['t'] != 'stock') continue;
      final row = Map<String, Object?>.from(x['r'] as Map);
      final pid = row['product_id'] as String?;
      final shop = row['shop_id'] as String?;
      if (pid == null || shop == null || !restoredProducts.contains(pid)) {
        continue;
      }
      await _insertIfAbsent(txn, 'stock', row);
      pairs.add((pid, shop));
    }
    for (final (pid, shop) in pairs) {
      await const StockLocalStore().recompute(txn, pid, shop);
      touched.add('stock');
    }
    for (final c in categories) {
      await refreshCategoryProductCount(txn, c);
    }
    await txn.delete(SyncTables.syncState, where: 'key = ?', whereArgs: [key]);
    return touched;
  }

  static Future<int> _insertIfAbsent(
    DatabaseExecutor txn,
    String table,
    Map<String, Object?> row,
  ) async {
    final exists = await _query(txn, table, 'id', row['id'] as String);
    if (exists.isNotEmpty) return 0;
    try {
      await txn.insert(table, row);
      return 1;
    } on DatabaseException {
      // A column dropped by a later schema, or a unique clash with a
      // bootstrapped row (stock product+shop): the server row wins.
      return 0;
    }
  }

  static Future<List<Map<String, Object?>>> _query(
    DatabaseExecutor txn,
    String table,
    String column,
    String value,
  ) async {
    try {
      return await txn.query(table, where: '$column = ?', whereArgs: [value]);
    } on DatabaseException {
      return const []; // table missing on an old schema
    }
  }

  static Future<List<Map<String, Object?>>> _read(
    DatabaseExecutor txn,
    String key,
  ) async {
    final r = await txn.query(
      SyncTables.syncState,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (r.isEmpty) return const [];
    try {
      final v = jsonDecode(r.first['value'] as String);
      return v is List
          ? [
              for (final x in v)
                if (x is Map) Map<String, Object?>.from(x),
            ]
          : const [];
    } on FormatException {
      return const [];
    }
  }
}
