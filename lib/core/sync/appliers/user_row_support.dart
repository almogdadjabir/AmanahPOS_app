import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../outbox/outbox_entry.dart';
import '../sync_schema.dart';

/// Row json key holding the member's last server json while local edits are
/// queued (written by `UserService`).
const String kUserServerKey = '_server';

/// Open (waiting / being sent) outbox rows of member [id] in [scope], in
/// `seq` order, optionally without [exceptMutation].
Future<List<OutboxEntry>> openUserRows(
  DatabaseExecutor db,
  String id, {
  required String scope,
  String? exceptMutation,
}) async {
  final rows = await db.query(
    SyncTables.outbox,
    where:
        "entity = 'user' AND entity_id = ? AND scope = ? "
        "AND status IN ('pending','blocked','inflight')"
        '${exceptMutation == null ? '' : ' AND mutation_id != ?'}',
    whereArgs: [id, scope, ?exceptMutation],
    orderBy: 'seq ASC',
  );
  return rows.map(OutboxEntry.fromRow).toList();
}

/// [base] (server json) with the queued edits of [open] laid over it, in
/// order. The row the UI shows while edits are waiting.
Map<String, dynamic> overlayUserEdits(
  Map<String, dynamic> base,
  List<OutboxEntry> open,
) {
  final out = {...base};
  for (final e in open) {
    if (e.op == 'deactivate') {
      out['is_active'] = false;
      continue;
    }
    if (e.op == 'create') continue;
    e.payload.forEach((k, v) {
      out[k == 'default_shop_id' ? 'default_shop' : k] = v;
    });
  }
  return out;
}

/// Rewrites the stored json of member [id] to [server] + queued edits
/// (`_server` kept only while edits remain), with [version].
Future<void> rewriteUserRow(
  DatabaseExecutor txn,
  String id, {
  required Map<String, dynamic> server,
  required int? version,
  required List<OutboxEntry> open,
}) async {
  final clean = {...server}..remove(kUserServerKey);
  final shown = overlayUserEdits(clean, open);
  if (open.isNotEmpty) shown[kUserServerKey] = clean;
  await txn.update(
    'synced_entities',
    {
      'json': jsonEncode(shown),
      'version': version,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    where: "entity = 'user' AND id = ?",
    whereArgs: [id],
  );
}

/// The member's server json: `_server` when local edits are queued, else the
/// stored json itself.
Map<String, dynamic> serverJsonOf(Map<String, dynamic> json) {
  final s = json[kUserServerKey];
  return s is Map<String, dynamic> ? s : ({...json}..remove(kUserServerKey));
}
