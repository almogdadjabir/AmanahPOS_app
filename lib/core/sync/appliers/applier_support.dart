import 'dart:convert';
import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../contract/sync_contract.dart';
import '../decimal3.dart';
import '../outbox/outbox_entry.dart';

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

// ---------------------------------------------------------------- push results

/// `server_state` of a BE result is `handlers.snapshot(obj)`: model
/// attnames (`category_id`, `parent_id`, `tenant_id`) and storage keys for
/// images. This maps it onto the feed `data` shape the local json uses and
/// drops what must not overwrite local columns (tenant, image keys: the
/// image is adopted by the feed / the image uploader, never from a
/// snapshot).
Map<String, dynamic> feedShapeOf(Map<String, dynamic> state) {
  final out = <String, dynamic>{...state};
  for (final (from, to) in kSnapshotFeedKeys) {
    if (out.containsKey(from)) out[to] = out.remove(from);
  }
  for (final k in const [
    'tenant_id',
    'tenant',
    'image',
    'thumbnail',
    'thumbnail_url',
    'image_hash',
    'image_bytes',
    'thumbnail_bytes',
    'version',
  ]) {
    out.remove(k);
  }
  return out;
}

/// BE `snapshot()` attname -> feed key (FKs; feed.py `ser_category`,
/// `ser_product`, `ser_vendor`).
const List<(String, String)> kSnapshotFeedKeys = [
  ('category_id', 'category'),
  ('parent_id', 'parent'),
  ('shop_id', 'shop'),
];

/// Keys the local json derives (legacy readers) that are not server state:
/// never stored in `server_json`.
const Set<String> kLocalDerivedKeys = {
  'category_name',
  'stock_level',
  'product_count',
  'children',
  'tenant',
};

/// [m] without [kLocalDerivedKeys]: the pure server snapshot.
Map<String, dynamic> withoutDerivedKeys(Map<String, dynamic> m) => {
  for (final e in m.entries)
    if (!kLocalDerivedKeys.contains(e.key)) e.key: e.value,
};

/// Mutation payload keys that are not row fields.
const Set<String> kNonFieldPayloadKeys = _nonFieldPayloadKeys;
const Set<String> _nonFieldPayloadKeys = {
  'id',
  'image_pending',
  'image_upload',
};

/// Whether [txn] has an unconfirmed outbox row (anything but `done`) of
/// [sent]'s entity other than [sent] itself: a later local edit the row
/// still shows, which a server snapshot must not overwrite.
Future<bool> hasOtherOpenRows(Transaction txn, OutboxEntry sent) async {
  final r = await txn.rawQuery(
    'SELECT 1 FROM outbox WHERE entity = ? AND entity_id = ? AND scope = ? '
    "AND mutation_id != ? AND status != 'done' LIMIT 1",
    [sent.entity, sent.entityId, sent.scope, sent.mutationId],
  );
  return r.isNotEmpty;
}

/// Local columns derived from the catalog json of [table] (`products`:
/// category_id, name, sku, barcode, price; `categories`: parent_id, name).
Map<String, Object?> catalogColumnsOf(String table, Map<String, dynamic> j) =>
    _catalogColumns(table, j);

Map<String, Object?> _catalogColumns(String table, Map<String, dynamic> j) {
  String? str(Object? v) => v is String ? v : null;
  return switch (table) {
    'products' => {
      'category_id': str(j['category']),
      'name': str(j['name']),
      'sku': str(j['sku']),
      'barcode': str(j['barcode']),
      if (j['price'] != null) 'price': '${j['price']}',
    },
    'categories' => {'parent_id': str(j['parent']), 'name': str(j['name'])},
    _ => const {},
  };
}

/// Spec "Push results" for `applied` / `duplicate` of a catalog row
/// (`categories`, `products`, `vendors`: `json`, `version`, `server_json`).
///
/// - Never rolls back: nothing happens when the stored `version` is already
///   >= `r.version` (a `duplicate` replays the ORIGINAL result).
/// - `merged` + `server_state`: the local fields are replaced from the
///   (feed-shaped) state and `version` adopted, unless another unconfirmed
///   local row of the entity exists (its edit keeps showing; that row's own
///   result brings the merged truth later).
/// - Otherwise the version is adopted only when nobody else can have written
///   in between: a `create`, or an edit with `version == base_version + 1`.
///   An edit sent with no base (queued behind its unsent create) leaves the
///   version alone, so the pulled echo of the server row still applies.
/// - `server_json` (last server state, feed-shaped + `version`) is written
///   whenever the version is adopted.
///
/// [sent] null = trust the result (no outbox context). Returns whether the
/// local fields were replaced from `server_state`.
Future<bool> adoptServerRow(
  Transaction txn,
  String table,
  String id,
  PushResult r, {
  OutboxEntry? sent,
}) async {
  final v = r.version;
  if (v == null) return false;
  final rows = await txn.query(
    table,
    columns: ['json', 'version', 'server_json'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (rows.isEmpty) return false;
  final stored = rows.first['version'] as int?;
  if (stored != null && stored >= v) return false;
  final state = r.serverState == null ? null : feedShapeOf(r.serverState!);
  final merged = r.merged && state != null;
  final base = sent?.baseVersion;
  final trusted =
      merged ||
      sent == null ||
      sent.op == 'create' ||
      (base != null && v == base + 1);
  if (!trusted) return false;
  final json = decodeJsonMap(rows.first['json']);
  final otherOpen = sent != null && await hasOtherOpenRows(txn, sent);
  final Map<String, dynamic> server;
  if (merged) {
    server = {...state};
  } else {
    final previous = decodeJsonMap(rows.first['server_json']);
    server = {
      ...(otherOpen ? previous : {...previous, ...json}),
      if (sent != null)
        for (final e in sent.payload.entries)
          if (!_nonFieldPayloadKeys.contains(e.key)) e.key: e.value,
    };
  }
  final pure = withoutDerivedKeys(server)
    ..['id'] = id
    ..['version'] = v;
  final replace = merged && !otherOpen;
  final next = replace ? <String, dynamic>{...json, ...state, 'id': id} : json;
  await txn.update(
    table,
    {
      'version': v,
      'server_json': jsonEncode(pure),
      if (replace) 'json': jsonEncode(next),
      if (replace) ..._catalogColumns(table, next),
    },
    where: 'id = ?',
    whereArgs: [id],
  );
  return replace;
}

/// Spec: `rejected entity_deleted` on an update: the server deleted the row.
/// The local row stays (the user decides) but is marked inactive
/// (`json.is_active = false`); a feed-shaped `server_state` becomes its
/// `server_json`. The pulled delete normally removes the row right after.
Future<void> markServerDeleted(
  Transaction txn,
  String table,
  String id,
  PushResult r,
) async {
  final rows = await txn.query(
    table,
    columns: ['json'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (rows.isEmpty) return;
  final json = decodeJsonMap(rows.first['json'])..['is_active'] = false;
  final state = r.serverState;
  await txn.update(
    table,
    {
      'json': jsonEncode(json),
      if (state != null)
        'server_json': jsonEncode({
          ...feedShapeOf(state),
          'id': id,
          if (state['version'] is int) 'version': state['version'],
        }),
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// The shared catalog `onPushResult` decision (spec "Push results"):
/// returns true when the row's fields were replaced from `server_state`, so
/// the applier refreshes what it derives (names, counts).
Future<bool> catalogPushResult(
  Transaction txn,
  String table,
  OutboxEntry sent,
  PushResult r,
) async {
  switch (r.status) {
    case PushStatus.rejected:
      // The engine already stored code/message/conflict id on the outbox
      // row; the local row stays (conflict policy A: no id rewrite).
      if (r.code == 'entity_deleted' && sent.op != 'create') {
        await markServerDeleted(txn, table, sent.entityId, r);
      }
      return false;
    case PushStatus.applied:
    case PushStatus.duplicate:
      // A delete: the pulled tombstone removes the row.
      if (sent.op == 'delete') return false;
      return adoptServerRow(txn, table, sent.entityId, r, sent: sent);
    case PushStatus.retry:
      return false;
  }
}
