import 'package:sqflite/sqflite.dart';

import 'contract/sync_contract.dart';
import 'outbox/outbox_entry.dart';

/// Writes server state for one entity into the local DB.
///
/// Both methods run inside a transaction owned by the sync engine and must
/// only use [txn] (never `OfflineDb.database`, which would deadlock). They
/// must be idempotent: a page or a push result can be applied again after a
/// crash (e.g. a `duplicate` replay of an `applied` mutation).
abstract class ChangeApplier {
  /// Wire entity name, e.g. `product`, `sale`, `stock`.
  String get entity;

  /// Applies one pulled change (`upsert` or `delete`).
  Future<void> apply(Transaction txn, PullChange change);

  /// Called for `applied`, `duplicate` and `rejected` results of a mutation
  /// this device sent (e.g. re-base stock from `stock_after`, adopt the
  /// server `version`, or store `server_state` of a conflict).
  ///
  /// WARNING (found by the convergence test): a `duplicate` result replays the
  /// ORIGINAL `stock_after`. Re-basing stock from it after a newer pull wrote
  /// fresher quantities makes local stock go stale with nothing to correct it.
  /// Re-base stock from `stock_after` ONLY when `result.status` is `applied`.
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  );

  /// Local tables this applier writes; notified after commit.
  Set<String> get tables;

  /// When true (default) a pulled change is not applied while the same
  /// (entity, id) still has a non-done outbox row (pending/inflight/
  /// blocked): the local edit wins until the server confirms it. The change
  /// is kept and applied once the local rows are resolved. Appliers whose
  /// local value is derived from server base + pending deltas (stock) return
  /// false and always receive the change.
  bool get skipWhenLocalPending => true;

  /// Version of the local row [change] targets, or null when unknown. A
  /// deferred change whose version is not newer than this is dropped
  /// instead of applied (it would roll the row back).
  Future<int?> localVersion(Transaction txn, PullChange change) async => null;
}

class ChangeApplierRegistry {
  final Map<String, ChangeApplier> _byEntity = {};

  /// Registers [a]. Registering two appliers for one entity is a programming
  /// error and throws [StateError].
  void register(ChangeApplier a) {
    if (_byEntity.containsKey(a.entity)) {
      throw StateError('ChangeApplier for "${a.entity}" already registered');
    }
    _byEntity[a.entity] = a;
  }

  ChangeApplier? of(String entity) => _byEntity[entity];

  Iterable<ChangeApplier> get all => _byEntity.values;
}
