import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import '../sync_scope.dart';
import 'applier_support.dart';

/// Server shop -> `shops`. The feed has no business key, so `business_id`
/// comes from the tenant of the sync scope (`userId|tenantId`); the legacy
/// shop filter depends on it (NULL would show the shop to every tenant, so an
/// existing value is kept when no scope is known).
class ShopApplier implements ChangeApplier {
  ShopApplier({String? Function()? scopeProvider})
    : _scope = scopeProvider ?? (() => SyncScope.current);

  final String? Function() _scope;

  @override
  String get entity => 'shop';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {'shops'};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      storedVersion(txn, 'shops', change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      await txn.delete('shops', where: 'id = ?', whereArgs: [id]);
      return;
    }
    final d = change.data;
    final version = versionOf(change);
    final name = d?['name'];
    if (d == null || version == null || name is! String || name.isEmpty) {
      return logSkip(entity, id, 'malformed');
    }
    final existing = await txn.query(
      'shops',
      columns: ['business_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final tenant =
        tenantOfScope(_scope()) ??
        (existing.isEmpty ? null : existing.first['business_id'] as String?);
    if (tenant == null) {
      return logSkip(entity, id, 'no tenant (no scope, no existing row)');
    }
    final json = <String, dynamic>{...d, 'id': id, 'business': tenant};
    await upsertVersioned(txn, 'shops', id, version, {
      'business_id': tenant,
      'json': jsonEncode(json),
      'updated_at': d['updated_at'] is String ? d['updated_at'] : null,
    });
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {}
}
