import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../../../features/inventory/data/local/stock_local_store.dart';
import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../decimal3.dart';
import '../outbox/outbox_entry.dart';

/// Server stock -> local `stock` + `products`.
///
/// Local quantity = server base + signed deltas of this device's open outbox
/// rows, so it always receives pulled changes (`skipWhenLocalPending` false).
/// Ordering note: the engine marks the sent outbox row `done`/`rejected`
/// BEFORE calling [onPushResult], so recomputing here already excludes it.
class StockApplier implements ChangeApplier {
  StockApplier({StockLocalStore store = const StockLocalStore()})
    : _store = store;

  final StockLocalStore _store;

  @override
  String get entity => 'stock';

  @override
  bool get skipWhenLocalPending => false;

  @override
  Set<String> get tables => const {'stock', 'products'};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async => null;

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    if (change.op == 'delete') {
      // BE deletes carry no data; `id` is the StockLevel id (stock.id).
      await _store.deleteByServerId(txn, change.id);
      return;
    }
    final d = change.data;
    final productId = d?['product_id'] ?? d?['product'];
    final shopId = d?['shop_id'] ?? d?['shop'] ?? change.shopId;
    final q = d?['quantity'];
    if (productId is! String ||
        shopId is! String ||
        q == null ||
        Decimal3.tryParse(q) == null) {
      // A malformed change must not poison the pull page transaction.
      developer.log(
        'StockApplier: skipping malformed stock change ${change.id}',
        name: 'sync',
      );
      return;
    }
    await _store.upsertServerBase(txn, change.id, productId, shopId, '$q');
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    switch (result.status) {
      case PushStatus.applied:
        // Only `applied` carries a fresh stock_after; a `duplicate` replays
        // the original (stale) one and must never re-base.
        await _store.rebaseFromStockAfter(txn, result.stockAfter);
      case PushStatus.rejected:
      // A `duplicate` never re-bases (stale stock_after), but the row is no
      // longer pending: re-derive quantity = base + remaining pending. If
      // a pull already brought the server level (which includes this
      // mutation) while the row was pending, keeping the old quantity would
      // count the delta twice until some later stock change.
      case PushStatus.duplicate:
        for (final (p, s) in StockLocalStore.affectedBy(
          sent.op,
          sent.payload,
        )) {
          await _store.recompute(txn, p, s);
        }
      case PushStatus.retry:
        break;
    }
  }
}
