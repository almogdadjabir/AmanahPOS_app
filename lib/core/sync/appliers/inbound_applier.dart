import 'dart:convert';
import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../../../features/inventory/data/local/stock_local_store.dart';
import '../../../features/inventory/data/models/responses/inbound_response_dto.dart';
import '../../offline/offline_constants.dart';
import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../decimal3.dart';
import '../outbox/outbox_entry.dart';

/// Server inbound receipts -> local `inbound_transactions` (history only).
///
/// Pulled inbound changes never touch stock (StockApplier owns pulled
/// stock). Push results of this device's `inbound.create` arrive ONLY here
/// (the engine routes results to the mutation's own entity applier), so
/// stock is re-based from `stock_after` here, on `applied` only. The engine
/// has already marked the sent outbox row done/rejected when [onPushResult]
/// runs, so a recompute no longer counts this receipt as pending.
class InboundApplier implements ChangeApplier {
  InboundApplier({StockLocalStore stock = const StockLocalStore()})
    : _stock = stock;

  final StockLocalStore _stock;

  static const String _table = OfflineConstants.inboundTransactionsTable;

  @override
  String get entity => 'inbound';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {'stock', 'products', _table};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async => null;

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    if (change.op == 'delete') {
      await txn.delete(_table, where: 'id = ?', whereArgs: [change.id]);
      return;
    }
    final InboundTransactionData data;
    try {
      data = _fromFeed(change);
    } on FormatException catch (e) {
      // A malformed change must not poison the pull page transaction.
      developer.log(
        'InboundApplier: skipping malformed inbound ${change.id}: $e',
        name: 'sync',
      );
      return;
    }
    await txn.insert(_table, {
      'id': change.id,
      'shop_id': data.shop,
      'json': jsonEncode(data.toJson()),
      'created_at': data.createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
        await _stock.rebaseFromStockAfter(txn, result.stockAfter);
        await _recomputeLines(txn, sent);
      case PushStatus.rejected:
        // Its local increase lived only in quantity (never in base), and the
        // row is no longer pending: quantity = base + remaining pending. The
        // receipt never happened on the server, so it leaves local history
        // (the rejected outbox row keeps the payload for the user).
        await _recomputeLines(txn, sent);
        await txn.delete(_table, where: 'id = ?', whereArgs: [sent.entityId]);
      case PushStatus.duplicate:
        // Never re-base on a replay, but the receipt is no longer pending: a
        // server level pulled meanwhile already includes it, so keeping the
        // old quantity would count it twice (until some later stock change).
        await _recomputeLines(txn, sent);
      case PushStatus.retry:
        break;
    }
  }

  Future<void> _recomputeLines(Transaction txn, OutboxEntry sent) async {
    final shop = sent.payload['shop_id'];
    if (shop is! String) return;
    for (final p in StockLocalStore.inboundProducts(sent.payload)) {
      await _stock.recompute(txn, p, shop);
    }
  }

  /// Feed shape: apps/sync/feed.py `ser_inbound` (`shop`, `vendor` as ids,
  /// `items[].product`), mapped to the local history json
  /// ([InboundTransactionData.toJson]).
  static InboundTransactionData _fromFeed(PullChange c) {
    final d = c.data;
    if (d == null) throw const FormatException('no data');
    final shop = d['shop'] ?? c.shopId;
    if (shop is! String) throw const FormatException('no shop');
    final rawItems = d['items'];
    final items = <InboundTransactionItemData>[
      if (rawItems is List)
        for (final it in rawItems)
          if (it is Map)
            InboundTransactionItemData(
              product: _strN(it['product']),
              quantity: _strN(it['quantity']),
              unitCost: _strN(it['unit_cost']),
              expiryDate: _strN(it['expiry_date']),
              batchNumber: _strN(it['batch_number']),
            ),
    ];
    var total = BigInt.zero;
    for (final it in items) {
      total += Decimal3.tryParse(it.quantity) ?? BigInt.zero;
    }
    return InboundTransactionData(
      id: c.id,
      reference: _strN(d['reference']),
      notes: _strN(d['notes']),
      shop: shop,
      vendorId: _strN(d['vendor']),
      totalQuantity: Decimal3.format(total),
      itemCount: items.length,
      items: items,
      createdAt: _strN(d['created_at']),
    );
  }

  static String? _strN(Object? v) => v == null ? null : '$v';
}
