import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';

import 'catalog_support.dart';
import 'sync_schema.dart';

/// Row marker of a catalog list (product / category / vendor).
enum CatalogSyncMark { synced, pending, failed }

/// Which rows of one catalog entity are waiting to sync or failed, derived
/// from the outbox ([CatalogSupport.pendingEntityIds] minus rejected rows,
/// and [CatalogSupport.rejectedEntityIds]) and from staged image uploads
/// (`pending_uploads`: waiting = pending, failed = failed).
class CatalogSyncMarks extends Equatable {
  const CatalogSyncMarks({
    this.pending = const <String>{},
    this.failed = const <String>{},
  });

  static const CatalogSyncMarks none = CatalogSyncMarks();

  /// Open outbox rows / waiting uploads, none rejected or failed.
  final Set<String> pending;

  /// A rejected outbox row or a failed upload (wins over [pending]).
  final Set<String> failed;

  bool isPendingSync(String? id) =>
      id != null && pending.contains(id) && !failed.contains(id);

  bool syncFailed(String? id) => id != null && failed.contains(id);

  CatalogSyncMark markOf(String? id) => syncFailed(id)
      ? CatalogSyncMark.failed
      : isPendingSync(id)
      ? CatalogSyncMark.pending
      : CatalogSyncMark.synced;

  /// Reads the marks of [entity] (`product`, `category`, `vendor`) for
  /// [scope] (the signed-in account; null = every scope). Another
  /// account's queued rows never mark this account's list (M6).
  static Future<CatalogSyncMarks> load(
    DatabaseExecutor db,
    String entity, {
    String? scope,
  }) async {
    final pending = await CatalogSupport.pendingEntityIds(
      db,
      entity,
      scope: scope,
    );
    final failed = await CatalogSupport.rejectedEntityIds(
      db,
      entity,
      scope: scope,
    );
    final uploads = await db.query(
      SyncTables.pendingUploads,
      columns: ['entity_id', 'state'],
      where: 'entity = ?${scope == null ? '' : ' AND scope = ?'}',
      whereArgs: [entity, ?scope],
    );
    for (final u in uploads) {
      final id = u['entity_id'] as String;
      if (u['state'] == 'failed') {
        failed.add(id);
      } else {
        pending.add(id);
      }
    }
    pending.removeAll(failed);
    return CatalogSyncMarks(pending: pending, failed: failed);
  }

  @override
  List<Object?> get props => [pending, failed];
}
