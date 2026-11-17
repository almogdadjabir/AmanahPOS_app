import 'dart:developer' as developer;

import '../../offline/offline_db.dart';
import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../db_change_notifier.dart';
import '../deferred_pull.dart';
import '../sync_engine.dart' show AuthedCall;
import '../transport/sync_transport.dart';

/// Targeted repair for a checksum mismatch: re-pages the given entities
/// (default sale, refund, stock) through the existing appliers.
///
/// Unlike a bootstrap it keeps NO progress and never touches the pull cursor,
/// the `bootstrapped` flag or the deferred-pull stash. It only ever applies
/// rows (version-guarded: a row whose local version is >= the server's is
/// left alone, a row with a local pending edit is skipped) and never deletes:
/// a surplus local row is reported by the audit, not removed.
class ChecksumRepair {
  ChecksumRepair({
    required OfflineDb db,
    required SyncTransport transport,
    required ChangeApplierRegistry appliers,
    required DbChangeNotifier notifier,
    required AuthedCall Function(String scope) authedFor,
    required Future<void> Function() assertScope,
    this.pageSize = 200,
    this.maxPagesPerEntity = 20000,
  }) : _db = db,
       _transport = transport,
       _appliers = appliers,
       _notifier = notifier,
       _authedFor = authedFor,
       _assertScope = assertScope;

  final OfflineDb _db;
  final SyncTransport _transport;
  final ChangeApplierRegistry _appliers;
  final DbChangeNotifier _notifier;
  final AuthedCall Function(String scope) _authedFor;
  final Future<void> Function() _assertScope;
  final int pageSize;
  final int maxPagesPerEntity;

  /// Rows applied. Throws on transport/scope errors (the audit catches).
  Future<int> repair({
    required String scope,
    List<String> entities = const ['sale', 'refund', 'stock'],
    int salesSinceDays = 7,
  }) async {
    final authed = _authedFor(scope);
    final manifest = await authed(
      () => _transport.bootstrapManifest(scope: scope),
    );
    var applied = 0;
    for (final entity in entities) {
      if (!manifest.entities.contains(entity)) continue;
      final applier = _appliers.of(entity);
      if (applier == null) continue;
      String? cursor;
      var pages = 0;
      while (true) {
        if (++pages > maxPagesPerEntity) {
          throw FormatException('repair of "$entity" exceeded page cap');
        }
        await _assertScope();
        final sent = cursor;
        final page = await authed(
          () => _transport.bootstrapPage(
            entity: entity,
            pageCursor: sent,
            limit: pageSize,
            snapshotCursor: manifest.snapshotCursor,
            salesSinceDays: salesSinceDays,
            scope: scope,
          ),
        );
        if (page.hasMore &&
            (page.nextPageCursor == null || page.nextPageCursor == sent)) {
          throw const FormatException('repair page cursor did not advance');
        }
        final touched = <String>{};
        final n = await (await _db.database).transaction((txn) async {
          var count = 0;
          for (final item in page.items) {
            final id = _idOf(item);
            if (id == null) continue;
            final v = item['version'];
            final change = PullChange(
              seq: 0,
              entity: entity,
              op: 'upsert',
              id: id,
              version: v is int ? v : null,
              data: item,
            );
            final version = change.version;
            if (version != null) {
              final local = await applier.localVersion(txn, change);
              if (local != null && version <= local) continue;
            }
            if (applier.skipWhenLocalPending &&
                await hasLocalPendingOutbox(
                  txn,
                  entity: entity,
                  id: id,
                  scope: scope,
                )) {
              continue; // the normal pull applies it once the edit is done
            }
            await applier.apply(txn, change);
            touched.addAll(applier.tables);
            count++;
          }
          await _assertScope(); // throwing rolls the page back
          return count;
        });
        applied += n;
        if (touched.isNotEmpty) _notifier.notify(touched);
        if (!page.hasMore) break;
        cursor = page.nextPageCursor;
      }
    }
    developer.log(
      'checksum repair applied $applied rows',
      name: 'ChecksumRepair',
    );
    return applied;
  }

  static String? _idOf(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is String && id.trim().isNotEmpty) return id;
    if (id is int) return '$id';
    return null;
  }
}
