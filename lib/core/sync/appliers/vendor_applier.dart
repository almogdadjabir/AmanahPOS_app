import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import 'applier_support.dart';

/// Server vendor -> legacy `vendors` (`VendorData` json shape). A row with
/// NULL version (REST-written) is older than any feed version.
class VendorApplier implements ChangeApplier {
  @override
  String get entity => 'vendor';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {'vendors'};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      storedVersion(txn, 'vendors', change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      await txn.delete('vendors', where: 'id = ?', whereArgs: [id]);
      return;
    }
    final d = change.data;
    final version = versionOf(change);
    final name = d?['name'];
    if (d == null ||
        version == null ||
        name is! String ||
        name.isEmpty ||
        d['is_active'] is! bool) {
      return logSkip(entity, id, 'malformed');
    }
    await upsertVersioned(txn, 'vendors', id, version, {
      'json': jsonEncode({...d, 'id': id}),
      'updated_at': d['updated_at'] is String ? d['updated_at'] : null,
      'server_json': jsonEncode({...d, 'id': id, 'version': version}),
    });
  }

  /// Spec "Push results": see [catalogPushResult].
  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    await catalogPushResult(txn, 'vendors', sent, result);
  }
}
