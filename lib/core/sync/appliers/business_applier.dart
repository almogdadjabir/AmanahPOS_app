import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import 'applier_support.dart';
import 'synced_entities_store.dart';

/// Server business -> `synced_entities` (full feed row) and, ONLY when the
/// legacy `businesses` row already exists, a merge of its scalar keys. The
/// legacy row is never inserted: the feed lacks owner, logo,
/// active_subscription and counts, and auth treats a cached row as complete.
class BusinessApplier implements ChangeApplier {
  BusinessApplier({SyncedEntitiesStore store = const SyncedEntitiesStore()})
    : _store = store;

  final SyncedEntitiesStore _store;

  static const _mergeKeys = [
    'name',
    'slug',
    'business_type',
    'address',
    'phone',
    'email',
    'tax_enabled',
    'tax_name',
    'tax_rate',
    'tax_inclusive',
    'is_active',
    'updated_at',
  ];

  @override
  String get entity => 'business';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {'businesses', 'synced_entities'};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      _store.localVersion(txn, entity, change.id);

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      await _store.delete(txn, entity, id);
      return;
    }
    final d = change.data;
    final version = versionOf(change);
    if (d == null || version == null || d['name'] is! String) {
      return logSkip(entity, id, 'malformed');
    }
    final tax = d['tax_rate'];
    if (tax != null && !decimalOk(tax)) {
      return logSkip(entity, id, 'bad tax_rate');
    }
    final stored = await _store.localVersion(txn, entity, id);
    if (stored != null && stored >= version) return;
    await _store.upsert(txn, entity, id, version, {...d, 'id': id});

    final rows = await txn.query(
      'businesses',
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final j = decodeJsonMap(rows.first['json']);
    for (final k in _mergeKeys) {
      if (d.containsKey(k)) j[k] = d[k];
    }
    await txn.update(
      'businesses',
      {
        'json': jsonEncode(j),
        'version': version,
        if (d['updated_at'] is String) 'updated_at': d['updated_at'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {}
}
