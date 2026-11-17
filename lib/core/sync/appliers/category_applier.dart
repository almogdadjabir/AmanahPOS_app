import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import '../sync_scope.dart';
import 'applier_support.dart';

/// Server category -> `categories`. Tenant comes from the sync scope; the
/// flat legacy shape is kept (`children` null, `product_count` derived from
/// local products). A write also refreshes `category_name` of its products.
class CategoryApplier implements ChangeApplier {
  CategoryApplier({String? Function()? scopeProvider})
    : _scope = scopeProvider ?? (() => SyncScope.current);

  final String? Function() _scope;

  @override
  String get entity => 'category';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {
    'categories',
    'products',
    kSyncedAssetsTable,
  };

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      storedVersion(txn, 'categories', change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      await unregisterAssets(txn, entity, id);
      return;
    }
    final d = change.data;
    final version = versionOf(change);
    final name = d?['name'];
    final parent = d?['parent'];
    if (d == null ||
        version == null ||
        name is! String ||
        name.isEmpty ||
        (parent != null && parent is! String)) {
      return logSkip(entity, id, 'malformed');
    }
    final existing = await txn.query(
      'categories',
      columns: ['tenant_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final tenant =
        tenantOfScope(_scope()) ??
        (existing.isEmpty ? null : existing.first['tenant_id'] as String?);
    if (tenant == null) {
      return logSkip(entity, id, 'no tenant (no scope, no existing row)');
    }
    final count =
        Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM products WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;
    final json = <String, dynamic>{
      ...d,
      'id': id,
      'tenant': tenant,
      'parent': parent,
      'product_count': count,
      'children': null,
    }..remove('image_hash');
    final wrote = await upsertVersioned(txn, 'categories', id, version, {
      'tenant_id': tenant,
      'parent_id': parent,
      'name': name,
      'json': jsonEncode(json),
      'updated_at': d['updated_at'] is String ? d['updated_at'] : null,
      'image_hash': d['image_hash'] is String ? d['image_hash'] : null,
    });
    if (!wrote) return;
    await registerRowAssets(txn, entity, id, d);
    await refreshProductsCategoryName(txn, id, name);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {}
}
