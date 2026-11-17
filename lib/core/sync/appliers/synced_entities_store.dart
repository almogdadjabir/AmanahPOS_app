import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Generic table for synced entities that have no legacy reader (`business`
/// scalar keys, `expiry_batch`, `user`, `subscription`, `notification`,
/// `bankak_account`). Use only with the apply [Transaction].
class SyncedEntitiesStore {
  const SyncedEntitiesStore();

  static const table = 'synced_entities';

  /// Inserts or replaces (entity, id).
  Future<void> upsert(
    DatabaseExecutor txn,
    String entity,
    String id,
    int? version,
    Map<String, dynamic> json,
  ) => txn.insert(table, {
    'entity': entity,
    'id': id,
    'version': version,
    'json': jsonEncode(json),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> delete(DatabaseExecutor txn, String entity, String id) => txn
      .delete(table, where: 'entity = ? AND id = ?', whereArgs: [entity, id]);

  /// Stored version of (entity, id), or null when absent / unversioned.
  Future<int?> localVersion(
    DatabaseExecutor txn,
    String entity,
    String id,
  ) async {
    final r = await txn.query(
      table,
      columns: ['version'],
      where: 'entity = ? AND id = ?',
      whereArgs: [entity, id],
      limit: 1,
    );
    return r.isEmpty ? null : r.first['version'] as int?;
  }
}
