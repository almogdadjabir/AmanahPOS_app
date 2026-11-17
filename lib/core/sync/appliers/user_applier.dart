import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import '../sync_schema.dart';
import 'synced_entity_applier.dart';
import 'user_row_support.dart';

/// Server user -> `synced_entities` (no legacy reader). Local team edits
/// (`UserService`) keep the server json under `_server`; push results adopt
/// the server version, re-base our own queued edits and revert refused ones.
class UserApplier extends SyncedEntityApplier {
  UserApplier({super.store});

  @override
  String get entity => 'user';

  @override
  bool get versioned => true;

  @override
  String? validate(Map<String, dynamic> d) {
    if (d['phone'] is! String || d['role'] is! String) return 'malformed';
    return null;
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    final rows = await txn.query(
      'synced_entities',
      columns: ['json', 'version'],
      where: "entity = 'user' AND id = ?",
      whereArgs: [sent.entityId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final json =
        jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
    final stored = rows.first['version'] as int?;
    final open = await openUserRows(
      txn,
      sent.entityId,
      scope: sent.scope,
      exceptMutation: sent.mutationId,
    );
    switch (result.status) {
      case PushStatus.applied:
      case PushStatus.duplicate:
        final v = result.version;
        if (v == null) return;
        await rewriteUserRow(
          txn,
          sent.entityId,
          // The server now holds what we sent: it joins the base.
          server: overlayUserEdits(serverJsonOf(json), [sent]),
          version: v > (stored ?? 0) ? v : stored,
          open: open,
        );
        await _rebase(txn, sent, v);
      case PushStatus.rejected:
        if (sent.op == 'create') return; // the owner dismisses it
        final state = result.serverState;
        final Map<String, dynamic> server;
        int? version = stored;
        if (state != null) {
          server = {...state}
            ..remove('version')
            ..remove('tenant_id');
          // Feed key is `default_shop`; never keep the payload spelling.
          final shop = server.remove('default_shop_id');
          if (shop != null && !server.containsKey('default_shop')) {
            server['default_shop'] = shop;
          }
          final sv = state['version'];
          if (sv is int && sv > (stored ?? 0)) version = sv;
        } else {
          server = serverJsonOf(json);
        }
        await rewriteUserRow(
          txn,
          sent.entityId,
          server: server,
          version: version,
          open: open,
        );
      case PushStatus.retry:
        return;
    }
  }

  /// Our own write moved the member from `v - 1` to [v]: queued role/shop
  /// edits based on `v - 1` (or on nothing, behind a create) now base on
  /// [v]. A foreign write in between makes [v] larger, nothing matches, and
  /// the server returns `conflict_version` (the owner decides).
  Future<void> _rebase(Transaction txn, OutboxEntry sent, int v) async {
    const ops = "('update','set_role','set_shop')";
    final target = sent.op == 'create' ? 'base_version IS NULL' : null;
    await txn.rawUpdate(
      'UPDATE ${SyncTables.outbox} SET base_version = ? '
      "WHERE entity = 'user' AND entity_id = ? AND scope = ? "
      "AND status IN ('pending','blocked') AND mutation_id != ? "
      'AND op IN $ops AND (${target ?? '0'} OR base_version = ?)',
      [v, sent.entityId, sent.scope, sent.mutationId, v - 1],
    );
  }
}
