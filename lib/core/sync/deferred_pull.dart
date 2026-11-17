import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'contract/sync_contract.dart';
import 'sync_schema.dart';

/// Pulled (or bootstrapped) changes kept back because the same (entity, id)
/// still had an unsynced local edit. Shared by [SyncEngine] and the
/// bootstrapper so both read and write ONE encoding: a JSON map of
/// `"entity|id"` -> [PullChange.toJson], stored scoped in `sync_state`.

/// Map key of a deferred change.
String deferredPullKey(String entity, String id) => '$entity|$id';

/// Decodes the stored blob. Null/empty -> empty map; an unreadable blob ->
/// null (reported through [onError]); callers drop it and flag repair.
Map<String, PullChange>? decodeDeferredPull(
  String? json, {
  void Function(Object error, StackTrace stack)? onError,
}) {
  if (json == null || json.isEmpty) return {};
  try {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return {
      for (final e in m.entries)
        e.key: PullChange.fromJson(Map<String, dynamic>.from(e.value as Map)),
    };
  } catch (e, st) {
    onError?.call(e, st);
    return null;
  }
}

/// Encodes [pending]; null when empty (the key is then removed).
String? encodeDeferredPull(Map<String, PullChange> pending) => pending.isEmpty
    ? null
    : jsonEncode({for (final e in pending.entries) e.key: e.value.toJson()});

/// True when (entity, id) has a non-done outbox row of [scope].
Future<bool> hasLocalPendingOutbox(
  DatabaseExecutor txn, {
  required String entity,
  required String id,
  required String scope,
}) async {
  final rows = await txn.rawQuery(
    'SELECT 1 FROM ${SyncTables.outbox} WHERE entity = ? AND entity_id = ? '
    "AND scope = ? AND status IN ('pending','inflight','blocked') LIMIT 1",
    [entity, id, scope],
  );
  return rows.isNotEmpty;
}
