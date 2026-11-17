import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/sync/appliers/user_row_support.dart';
import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/outbox/outbox_store.dart';
import '../../../core/sync/outbox/outbox_entry.dart';
import '../../../core/sync/sync_schema.dart';

/// What the owner does with a refused team change. Nothing here is ever
/// automatic: "Apply mine again" re-sends the same change against the
/// member's CURRENT server version (the server still refuses it if the
/// member changed again); "Dismiss" drops the change and shows the server
/// state.
class UserConflictService {
  UserConflictService({
    required LocalWriter writer,
    required OutboxStore outbox,
  }) : _writer = writer,
       _outbox = outbox;

  final LocalWriter _writer;
  final OutboxStore _outbox;

  static const Set<String> _tables = {'synced_entities', SyncTables.outbox};

  Future<void> applyMineAgain(String mutationId) => _writer.write(
    tables: _tables,
    body: (scope) async {
      final txn = scope.txn;
      final old = await _rejected(txn, mutationId);
      if (old == null || old.errorCode != 'conflict_version') {
        throw const CatalogValidationException(
          'This change is not waiting for a decision',
        );
      }
      final row = await txn.query(
        'synced_entities',
        columns: ['json', 'version'],
        where: "entity = 'user' AND id = ?",
        whereArgs: [old.entityId],
        limit: 1,
      );
      if (row.isEmpty) {
        throw const CatalogValidationException('Member not found');
      }
      final json =
          jsonDecode(row.first['json'] as String) as Map<String, dynamic>;
      final version = row.first['version'] as int?;
      // The same outbox row goes back to the queue where it was (its seq,
      // time and mutation id kept) with the fresh base version: it cannot
      // jump ahead of or behind the member's other queued edits.
      if (!await _outbox.retryRejectedIn(txn, mutationId)) {
        throw const CatalogValidationException('Nothing to apply any more');
      }
      await txn.update(
        SyncTables.outbox,
        {'base_version': version},
        where: 'mutation_id = ?',
        whereArgs: [mutationId],
      );
      await rewriteUserRow(
        txn,
        old.entityId,
        server: serverJsonOf(json),
        version: version,
        open: await openUserRows(txn, old.entityId, scope: old.scope),
      );
    },
  );

  Future<void> dismiss(String mutationId) => _writer.write(
    tables: _tables,
    body: (scope) async {
      final txn = scope.txn;
      final old = await _rejected(txn, mutationId);
      if (old == null) {
        throw const CatalogValidationException(
          'This change is not waiting for a decision',
        );
      }
      if (old.op == 'create') {
        // The server holds nothing: drop the member and everything queued
        // behind the create.
        final dropped = await CatalogSupport.dropNeverSentCreate(
          txn,
          'user',
          old.entityId,
          scope: old.scope,
        );
        if (!dropped) {
          throw const CatalogValidationException('Being sent, try again');
        }
        await txn.delete(
          SyncTables.outbox,
          where: 'mutation_id = ?',
          whereArgs: [mutationId],
        );
        await txn.delete(
          'synced_entities',
          where: "entity = 'user' AND id = ?",
          whereArgs: [old.entityId],
        );
        return;
      }
      await txn.delete(
        SyncTables.outbox,
        where: 'mutation_id = ?',
        whereArgs: [mutationId],
      );
      final row = await txn.query(
        'synced_entities',
        columns: ['json', 'version'],
        where: "entity = 'user' AND id = ?",
        whereArgs: [old.entityId],
        limit: 1,
      );
      if (row.isEmpty) return;
      await rewriteUserRow(
        txn,
        old.entityId,
        server: serverJsonOf(
          jsonDecode(row.first['json'] as String) as Map<String, dynamic>,
        ),
        version: row.first['version'] as int?,
        open: await openUserRows(txn, old.entityId, scope: old.scope),
      );
    },
  );

  Future<OutboxEntry?> _rejected(
    DatabaseExecutor txn,
    String mutationId,
  ) async {
    final r = await txn.query(
      SyncTables.outbox,
      where: "mutation_id = ? AND entity = 'user' AND status = 'rejected'",
      whereArgs: [mutationId],
      limit: 1,
    );
    return r.isEmpty ? null : OutboxEntry.fromRow(r.first);
  }
}
