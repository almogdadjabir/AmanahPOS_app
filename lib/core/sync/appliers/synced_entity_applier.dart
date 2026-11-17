import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import 'applier_support.dart';
import 'synced_entities_store.dart';

/// Base for entities with no legacy reader: the full feed row goes to
/// `synced_entities`. Equal/older versions never overwrite (unversioned
/// entities are always replaced). [validate] returns null when the row is
/// well formed, else a skip reason; malformed rows are skipped and logged.
abstract class SyncedEntityApplier implements ChangeApplier {
  SyncedEntityApplier({SyncedEntitiesStore store = const SyncedEntitiesStore()})
    : _store = store;

  final SyncedEntitiesStore _store;

  /// True when the feed row carries a `version` that must be present.
  bool get versioned => false;

  String? validate(Map<String, dynamic> d);

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {SyncedEntitiesStore.table};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      _store.localVersion(txn, entity, change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') return _store.delete(txn, entity, id);
    final d = change.data;
    if (d == null) return logSkip(entity, id, 'no data');
    final version = versionOf(change);
    if (versioned && version == null) {
      return logSkip(entity, id, 'missing version');
    }
    final reason = validate(d);
    if (reason != null) return logSkip(entity, id, reason);
    if (version != null) {
      final stored = await _store.localVersion(txn, entity, id);
      if (stored != null && stored >= version) return;
    }
    await _store.upsert(txn, entity, id, version, {...d, 'id': id});
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {}
}
