import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import 'applier_support.dart';

/// Server customer -> legacy `customers`. `loyalty_points` is server-owned
/// and stored exactly as sent. `total_purchases` is not in the feed (left
/// absent). A row with NULL version (REST-written) is older than any feed
/// version.
class CustomerApplier implements ChangeApplier {
  @override
  String get entity => 'customer';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {'customers'};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      storedVersion(txn, 'customers', change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
      return;
    }
    final d = change.data;
    final version = versionOf(change);
    final name = d?['name'];
    if (d == null ||
        version == null ||
        name is! String ||
        name.isEmpty ||
        d['loyalty_points'] is! int ||
        d['is_active'] is! bool ||
        (d['phone'] != null && d['phone'] is! String) ||
        (d['email'] != null && d['email'] is! String)) {
      return logSkip(entity, id, 'malformed');
    }
    await upsertVersioned(txn, 'customers', id, version, {
      'name': name,
      'phone': d['phone'],
      'email': d['email'],
      'json': jsonEncode({...d, 'id': id}),
      'updated_at': d['updated_at'] is String ? d['updated_at'] : null,
      'server_json': jsonEncode({...d, 'id': id, 'version': version}),
    });
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    final replaced = await catalogPushResult(txn, 'customers', sent, result);
    if (!replaced) return;
    // The row's fields came from `server_state`: refresh the searchable
    // columns derived from the json.
    final rows = await txn.query(
      'customers',
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [sent.entityId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final j = decodeJsonMap(rows.first['json']);
    await txn.update(
      'customers',
      {
        if (j['name'] is String) 'name': j['name'],
        'phone': j['phone'] is String ? j['phone'] : null,
        'email': j['email'] is String ? j['email'] : null,
      },
      where: 'id = ?',
      whereArgs: [sent.entityId],
    );
  }
}
