import 'dart:convert';
import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../contract/sync_contract.dart';
import '../decimal3.dart';

/// True when [v] is a plain decimal (string or number). Money stays a string
/// on the wire and in storage; this only validates.
bool decimalOk(Object? v) => v != null && Decimal3.tryParse(v) != null;

void logSkip(String entity, String id, String reason) =>
    developer.log('Applier($entity): skipping $id: $reason', name: 'sync');

/// Tenant part of a `userId|tenantId` scope, or null.
String? tenantOfScope(String? scope) {
  if (scope == null) return null;
  final i = scope.indexOf('|');
  if (i < 0 || i == scope.length - 1) return null;
  return scope.substring(i + 1);
}

/// Version of [c]: the wrapper's, else the row's own `version`.
int? versionOf(PullChange c) {
  final v = c.version ?? c.data?['version'];
  return v is int ? v : null;
}

Map<String, dynamic> decodeJsonMap(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    try {
      final d = jsonDecode(raw);
      if (d is Map) return Map<String, dynamic>.from(d);
    } on FormatException {
      // fall through
    }
  }
  return <String, dynamic>{};
}

/// Stored `version` of `table.id`, or null when absent / unversioned.
Future<int?> storedVersion(Transaction txn, String table, String id) async {
  final r = await txn.query(
    table,
    columns: ['version'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return r.isEmpty ? null : r.first['version'] as int?;
}

/// Writes [row] (must hold `id`) into [table] unless the stored row has a
/// `version` >= [version] (equal or older never overwrites). Returns whether
/// it wrote.
Future<bool> upsertVersioned(
  Transaction txn,
  String table,
  String id,
  int version,
  Map<String, Object?> row,
) async {
  final stored = await storedVersion(txn, table, id);
  if (stored != null && stored >= version) return false;
  await txn.insert(table, {
    ...row,
    'id': id,
    'version': version,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  return true;
}

/// `categories.json.product_count` = number of local products of the
/// category (all rows, like the REST list).
Future<void> refreshCategoryProductCount(
  Transaction txn,
  String? categoryId,
) async {
  if (categoryId == null || categoryId.isEmpty) return;
  final rows = await txn.query(
    'categories',
    columns: ['json'],
    where: 'id = ?',
    whereArgs: [categoryId],
    limit: 1,
  );
  if (rows.isEmpty) return;
  final n =
      Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM products WHERE category_id = ?',
          [categoryId],
        ),
      ) ??
      0;
  final j = decodeJsonMap(rows.first['json']);
  if (j['product_count'] == n) return;
  j['product_count'] = n;
  await txn.update(
    'categories',
    {'json': jsonEncode(j)},
    where: 'id = ?',
    whereArgs: [categoryId],
  );
}

/// Rewrites `products.json.category_name` of every product of [categoryId].
Future<void> refreshProductsCategoryName(
  Transaction txn,
  String categoryId,
  String? name,
) async {
  final rows = await txn.query(
    'products',
    columns: ['id', 'json'],
    where: 'category_id = ?',
    whereArgs: [categoryId],
  );
  for (final r in rows) {
    final j = decodeJsonMap(r['json']);
    if (j['category_name'] == name) continue;
    j['category_name'] = name;
    await txn.update(
      'products',
      {'json': jsonEncode(j)},
      where: 'id = ?',
      whereArgs: [r['id']],
    );
  }
}

/// `json[key]` of `table.id` as a non-empty string, or null.
Future<String?> localJsonString(
  DatabaseExecutor db,
  String table,
  String? id,
  String key,
) async {
  if (id == null || id.isEmpty) return null;
  final r = await db.query(
    table,
    columns: ['json'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (r.isEmpty) return null;
  final v = decodeJsonMap(r.first['json'])[key];
  return v is String && v.isNotEmpty ? v : null;
}

/// `full_name` of a synced `user` row (`synced_entities`), or null.
Future<String?> localUserName(DatabaseExecutor db, String? id) async {
  if (id == null || id.isEmpty) return null;
  final r = await db.query(
    'synced_entities',
    columns: ['json'],
    where: 'entity = ? AND id = ?',
    whereArgs: ['user', id],
    limit: 1,
  );
  if (r.isEmpty) return null;
  final v = decodeJsonMap(r.first['json'])['full_name'];
  return v is String && v.isNotEmpty ? v : null;
}

/// Hash-driven image registrations (DB v12, see `AssetSync`).
const String kSyncedAssetsTable = 'synced_assets';

/// Registers the image [url] of `type/id/variant` (`thumb|full`) for
/// `AssetSync`. [expectedHash] is the feed `image_hash`, a CHANGE TOKEN only
/// (ruling T1-a): a new token marks the row `pending` again, an unchanged
/// token does nothing. An empty token is keyed by url instead (re-download
/// only when the url changes). A null/empty [url] removes the registration;
/// the file is removed later by the orphan sweep. The existing local file is
/// never touched here (it stays until a new one is verified).
Future<void> registerAsset(
  Transaction txn,
  String type,
  String id,
  String variant,
  String? url,
  String? expectedHash,
) async {
  const where = 'type = ? AND id = ? AND variant = ?';
  final args = [type, id, variant];
  if (url == null || url.trim().isEmpty) {
    await txn.delete(kSyncedAssetsTable, where: where, whereArgs: args);
    return;
  }
  final token = expectedHash?.trim() ?? '';
  final existing = await txn.query(
    kSyncedAssetsTable,
    columns: ['url', 'expected_hash', 'local_path', 'local_hash'],
    where: where,
    whereArgs: args,
    limit: 1,
  );
  if (existing.isEmpty) {
    await txn.insert(kSyncedAssetsTable, {
      'type': type,
      'id': id,
      'variant': variant,
      'url': url,
      'expected_hash': token,
      'state': 'pending',
      'attempts': 0,
    });
    return;
  }
  final oldUrl = existing.first['url'] as String?;
  final oldToken = (existing.first['expected_hash'] as String?) ?? '';
  final changed = token.isEmpty
      ? (oldToken.isNotEmpty || oldUrl != url)
      : token != oldToken;
  // A -> B -> A before B was downloaded: the local file already is A.
  final haveIt =
      token.isNotEmpty &&
      existing.first['local_path'] != null &&
      existing.first['local_hash'] == token;
  if (changed) {
    await txn.update(
      kSyncedAssetsTable,
      {
        'url': url,
        'expected_hash': token,
        'state': haveIt ? 'ok' : 'pending',
        'attempts': 0,
        'next_attempt_at': null,
      },
      where: where,
      whereArgs: args,
    );
  } else if (oldUrl != url) {
    // Same token, new address (host move): follow it, no re-download.
    await txn.update(
      kSyncedAssetsTable,
      {'url': url},
      where: where,
      whereArgs: args,
    );
  }
}

/// Registers the `thumb` (`thumbnail_url`) and `full` (`image`) variants of
/// a feed row [d]. Keys absent from [d] leave that variant untouched.
Future<void> registerRowAssets(
  Transaction txn,
  String type,
  String id,
  Map<String, dynamic> d,
) async {
  final token = d['image_hash'] is String ? d['image_hash'] as String : null;
  String? s(Object? v) => v is String ? v : null;
  if (d.containsKey('thumbnail_url')) {
    await registerAsset(txn, type, id, 'thumb', s(d['thumbnail_url']), token);
  }
  if (d.containsKey('image')) {
    await registerAsset(txn, type, id, 'full', s(d['image']), token);
  }
}

/// Drops every image registration of `type/id` (row deleted).
Future<void> unregisterAssets(Transaction txn, String type, String id) =>
    txn.delete(
      kSyncedAssetsTable,
      where: 'type = ? AND id = ?',
      whereArgs: [type, id],
    );
