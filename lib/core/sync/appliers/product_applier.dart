import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../decimal3.dart';
import '../outbox/outbox_entry.dart';
import 'applier_support.dart';

/// Server product -> `products`. Money stays a string. Derives what the feed
/// lacks and legacy readers need: `stock_level` (exact sum of local stock),
/// `category_name`, and the `product_count` of the old and new category.
class ProductApplier implements ChangeApplier {
  @override
  String get entity => 'product';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {
    'products',
    'categories',
    kSyncedAssetsTable,
  };

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      storedVersion(txn, 'products', change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      final old = await _categoryOf(txn, id);
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      await unregisterAssets(txn, entity, id);
      await refreshCategoryProductCount(txn, old);
      return;
    }
    final d = change.data;
    final version = versionOf(change);
    final name = d?['name'];
    final category = d?['category'];
    final cost = d?['cost_price'];
    if (d == null ||
        version == null ||
        name is! String ||
        name.isEmpty ||
        !decimalOk(d['price']) ||
        (cost != null && !decimalOk(cost)) ||
        (category != null && category is! String)) {
      return logSkip(entity, id, 'malformed');
    }
    final oldCategory = await _categoryOf(txn, id);
    final json = <String, dynamic>{
      ...d,
      'id': id,
      'category_name': await _categoryName(txn, category as String?),
      'stock_level': await _stockLevel(txn, id),
    };
    final wrote = await upsertVersioned(txn, 'products', id, version, {
      'category_id': category,
      'name': name,
      'sku': d['sku'] is String ? d['sku'] : null,
      'barcode': d['barcode'] is String ? d['barcode'] : null,
      'price': '${d['price']}',
      'stock_level': json['stock_level'],
      'thumbnail_url': d['thumbnail_url'] is String ? d['thumbnail_url'] : null,
      'image_url': d['image'] is String ? d['image'] : null,
      'image_hash': d['image_hash'] is String ? d['image_hash'] : null,
      'json': jsonEncode(json),
      'updated_at': d['updated_at'] is String ? d['updated_at'] : null,
      'server_json': jsonEncode({...d, 'id': id, 'version': version}),
    });
    if (!wrote) return;
    await registerRowAssets(txn, entity, id, d);
    await refreshCategoryProductCount(txn, category);
    if (oldCategory != category) {
      await refreshCategoryProductCount(txn, oldCategory);
    }
  }

  Future<String?> _categoryOf(Transaction txn, String id) async {
    final r = await txn.query(
      'products',
      columns: ['category_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return r.isEmpty ? null : r.first['category_id'] as String?;
  }

  Future<String?> _categoryName(Transaction txn, String? categoryId) async {
    if (categoryId == null) return null;
    final r = await txn.query(
      'categories',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return r.isEmpty ? null : r.first['name'] as String?;
  }

  Future<double> _stockLevel(Transaction txn, String productId) async {
    final rows = await txn.query(
      'stock',
      columns: ['quantity'],
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    var sum = BigInt.zero;
    for (final r in rows) {
      sum += Decimal3.tryParse(r['quantity']) ?? BigInt.zero;
    }
    return Decimal3.toDouble(sum);
  }

  /// Spec "Push results": see [catalogPushResult]. Fields taken from a
  /// merged `server_state` may move the product to another category:
  /// `category_name` and both categories' `product_count` follow.
  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    final id = sent.entityId;
    final oldCategory = await _categoryOf(txn, id);
    if (!await catalogPushResult(txn, 'products', sent, result)) return;
    final category = await _categoryOf(txn, id);
    final r = await txn.query(
      'products',
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (r.isEmpty) return;
    final json = decodeJsonMap(r.first['json'])
      ..['category_name'] = await _categoryName(txn, category);
    await txn.update(
      'products',
      {'json': jsonEncode(json)},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (oldCategory != category) {
      await refreshCategoryProductCount(txn, oldCategory);
      await refreshCategoryProductCount(txn, category);
    }
  }
}
