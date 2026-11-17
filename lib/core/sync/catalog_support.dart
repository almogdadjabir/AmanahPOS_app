import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../permissions/app_permissions.dart';
import 'appliers/applier_support.dart';
import 'outbox/outbox_entry.dart';
import 'sync_schema.dart';

/// Thrown before anything is written when a catalog change is refused
/// locally (the server would answer `forbidden` / reject it).
class CatalogValidationException implements Exception {
  const CatalogValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Who is changing the catalog: read from the signed-in session (injected,
/// like `StockActor`).
class CatalogActor {
  const CatalogActor({required this.businessType, required this.role});

  final AppBusinessType businessType;
  final AppUserRole role;

  /// Catalog writes are owner/manager only (BE `forbidden` otherwise).
  bool get canWrite => role == AppUserRole.owner || role == AppUserRole.manager;
}

/// Shared helpers of the catalog services (category, vendor, product).
class CatalogSupport {
  const CatalogSupport._();

  /// Throws unless [actor] may write the catalog.
  static void requireWrite(CatalogActor actor) {
    if (!actor.canWrite) {
      throw const CatalogValidationException(
        'Only owners and managers can change the catalog',
      );
    }
  }

  /// Ids of [entity] with an open outbox row (anything not `done`, so
  /// pending, blocked, inflight and rejected). Used by UI "waiting to sync"
  /// markers.
  ///
  /// [scope] (M6): only that account's rows; null = every scope (no one
  /// signed in).
  static Future<Set<String>> pendingEntityIds(
    DatabaseExecutor db,
    String entity, {
    String? scope,
  }) async {
    final rows = await db.rawQuery(
      'SELECT DISTINCT entity_id FROM ${SyncTables.outbox} '
      "WHERE entity = ? AND status != 'done'"
      '${scope == null ? '' : ' AND scope = ?'}',
      [entity, ?scope],
    );
    return {for (final r in rows) r['entity_id'] as String};
  }

  /// Ids of [entity] with a `rejected` outbox row (the server refused a
  /// create/update/delete; the user acts on the pending-sync screen). Used
  /// by UI "sync failed" markers.
  ///
  /// [scope] (M6): only that account's rows; null = every scope (no one
  /// signed in).
  static Future<Set<String>> rejectedEntityIds(
    DatabaseExecutor db,
    String entity, {
    String? scope,
  }) async {
    final rows = await db.rawQuery(
      'SELECT DISTINCT entity_id FROM ${SyncTables.outbox} '
      "WHERE entity = ? AND status = 'rejected'"
      '${scope == null ? '' : ' AND scope = ?'}',
      [entity, ?scope],
    );
    return {for (final r in rows) r['entity_id'] as String};
  }

  /// LIKE pattern escaping (same as `OutboxStore`), with `ESCAPE '\'`.
  static String _likeEscape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// True when an outbox row of [scope] that is still waiting or being sent
  /// (`blocked`, `pending`, `inflight`) lists [entityId] as a dependency.
  static Future<bool> hasOpenDependents(
    DatabaseExecutor txn,
    String entityId, {
    required String scope,
  }) async {
    final rows = await txn.rawQuery(
      'SELECT depends_on_json FROM ${SyncTables.outbox} WHERE scope = ? '
      "AND status IN ('blocked','pending','inflight') "
      'AND depends_on_json IS NOT NULL AND depends_on_json LIKE ? '
      "ESCAPE '\\'",
      [scope, '%${_likeEscape(jsonEncode(entityId))}%'],
    );
    return rows.any(
      (r) =>
          OutboxEntry.decodeDependsOn(r['depends_on_json']).contains(entityId),
    );
  }

  /// Dependencies of [e] that no longer exist on this device: no `create`
  /// row in [e]'s scope (any status) and no local product / category /
  /// vendor row. A row naming one, if sent, is stored by the BE without
  /// that link (a sale line with product = NULL). T5 I4: retry asks first.
  static Future<Set<String>> goneDependencies(
    DatabaseExecutor db,
    OutboxEntry e,
  ) async {
    final gone = <String>{};
    for (final d in e.dependsOn.toSet()) {
      final create = await db.rawQuery(
        'SELECT 1 FROM ${SyncTables.outbox} '
        "WHERE op = 'create' AND entity_id = ? AND scope = ? LIMIT 1",
        [d, e.scope],
      );
      if (create.isNotEmpty) continue;
      var local = false;
      for (final t in const ['products', 'categories', 'vendors']) {
        final r = await db.query(
          t,
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [d],
          limit: 1,
        );
        if (r.isNotEmpty) {
          local = true;
          break;
        }
      }
      if (!local) gone.add(d);
    }
    return gone;
  }

  /// R7: a never-sent create with NO open dependent is removed together with
  /// every outbox row of the entity, in the caller's transaction; nothing
  /// ever reached the server. Returns true when dropped. When any row waits
  /// on it, or the create may have reached the server, nothing is changed
  /// and the caller enqueues a normal `delete` (after the create).
  ///
  /// "Never sent" (Task 5, found by the convergence test): the create is
  /// `rejected` (the server answered: it holds nothing), or `pending` /
  /// `blocked` and NEVER claimed (`claimed_at` NULL). A `pending` create can
  /// have been applied by the server already: its response was lost, or the
  /// app died after sending (lease expiry puts it back to `pending`).
  /// Dropping it then left a live server row no device knew it had deleted.
  static Future<bool> dropNeverSentCreate(
    DatabaseExecutor txn,
    String entity,
    String entityId, {
    required String scope,
  }) async {
    final rows = await txn.query(
      SyncTables.outbox,
      columns: ['op', 'status', 'claimed_at'],
      where: 'entity = ? AND entity_id = ? AND scope = ?',
      whereArgs: [entity, entityId, scope],
    );
    final creates = rows.where((r) => r['op'] == 'create').toList();
    if (creates.isEmpty) return false;
    bool unsent(Map<String, Object?> r) =>
        r['status'] == 'rejected' ||
        ((r['status'] == 'pending' || r['status'] == 'blocked') &&
            r['claimed_at'] == null);
    if (!creates.every(unsent)) return false;
    // An inflight/done non-create row cannot exist before its create is
    // done, but never drop a row that may be in the server's hands.
    if (rows.any((r) => r['status'] == 'inflight')) return false;
    if (await hasOpenDependents(txn, entityId, scope: scope)) return false;
    await txn.delete(
      SyncTables.outbox,
      where: "entity = ? AND entity_id = ? AND scope = ? AND status != 'done'",
      whereArgs: [entity, entityId, scope],
    );
    return true;
  }

  /// [value] (decoded JSON) with every string EQUAL to [from] replaced by
  /// [to], at any depth (map values, list items). Ids are UUIDs, so an equal
  /// string is a reference; substrings and map keys are left alone. Used by
  /// "Merge into existing" only.
  static Object? replaceIdDeep(Object? value, String from, String to) {
    if (value is String) return value == from ? to : value;
    if (value is Map) {
      return <String, dynamic>{
        for (final e in value.entries)
          '${e.key}': replaceIdDeep(e.value, from, to),
      };
    }
    if (value is List) {
      return [for (final v in value) replaceIdDeep(v, from, to)];
    }
    return value;
  }

  /// Fields of [proposed] whose value differs from [current] (null and ''
  /// are the same, values compared trimmed when strings).
  static Map<String, dynamic> changedFields(
    Map<String, dynamic> current,
    Map<String, dynamic> proposed,
  ) {
    Object? norm(Object? v) => v is String ? v.trim() : v;
    final out = <String, dynamic>{};
    proposed.forEach((k, v) {
      final a = norm(current[k]) ?? '';
      final b = norm(v) ?? '';
      if (a != b) out[k] = v;
    });
    return out;
  }

  /// `json` map and `version` of a catalog row, or null when absent.
  static Future<({Map<String, dynamic> json, int? version})?> loadRow(
    DatabaseExecutor txn,
    String table,
    String id,
  ) async {
    final r = await txn.query(
      table,
      columns: ['json', 'version'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return (
      json: decodeJsonMap(r.first['json']),
      version: r.first['version'] as int?,
    );
  }
}
