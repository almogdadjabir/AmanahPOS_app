import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/sync/appliers/user_row_support.dart';
import '../../../../core/sync/catalog_sync_marks.dart';
import '../../../../core/sync/local_writer.dart';
import '../../../../core/sync/outbox/outbox_entry.dart';
import '../../../../core/sync/sync_schema.dart';
import '../../../../core/sync/sync_scope.dart';
import '../models/responses/user_response_dto.dart';

/// Local reads of the team: `synced_entities` rows of entity `user`, with
/// pending/failed marks and the rejected outbox row ("conflict") derived
/// from the outbox of the signed-in scope. A cashier's store holds only
/// their own row (the BE scopes the feed).
class UserLocalStore {
  UserLocalStore(this._writer);

  final LocalWriter _writer;

  static const String entity = 'user';

  Future<List<UserData>> readAll() => _writer.read((db) => _load(db, null));

  Future<UserData?> readOne(String id) async {
    final all = await _writer.read((db) => _load(db, id));
    return all.isEmpty ? null : all.first;
  }

  Future<List<UserData>> _load(DatabaseExecutor db, String? id) async {
    final scope = SyncScope.current;
    final marks = await CatalogSyncMarks.load(db, entity, scope: scope);
    final rejected = await db.query(
      SyncTables.outbox,
      where:
          "entity = ? AND status = 'rejected'"
          '${scope == null ? '' : ' AND scope = ?'}',
      whereArgs: [entity, ?scope],
      orderBy: 'seq ASC',
    );
    final conflicts = <String, UserConflict>{};
    for (final r in rejected) {
      final e = OutboxEntry.fromRow(r);
      conflicts[e.entityId] = UserConflict(
        mutationId: e.mutationId,
        op: e.op,
        code: e.errorCode ?? 'rejected',
        message: e.errorMessage,
        payload: e.payload,
      );
    }
    final rows = await db.query(
      'synced_entities',
      where: id == null ? 'entity = ?' : 'entity = ? AND id = ?',
      whereArgs: [entity, ?id],
    );
    final users = <UserData>[];
    for (final r in rows) {
      final j = jsonDecode(r['json'] as String) as Map<String, dynamic>;
      j.remove(kUserServerKey);
      final uid = r['id'] as String;
      final u = UserData.fromJson({...j, 'id': uid, 'version': r['version']});
      users.add(
        u.withMarks(switch (marks.markOf(uid)) {
          CatalogSyncMark.synced => UserSyncMark.synced,
          CatalogSyncMark.pending => UserSyncMark.pending,
          CatalogSyncMark.failed => UserSyncMark.failed,
        }, conflicts[uid]),
      );
    }
    users.sort(
      (a, b) => (a.fullName ?? a.phone ?? '').toLowerCase().compareTo(
        (b.fullName ?? b.phone ?? '').toLowerCase(),
      ),
    );
    return users;
  }
}
