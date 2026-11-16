import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../../../features/inventory/data/local/stock_local_store.dart';
import '../../../features/pos/data/local/sale_local_store.dart';
import '../../../features/pos/domain/sale.dart';
import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';

/// Server sales -> local `sales` / `sale_items` / `sale_payments`.
///
/// Pulled sales never touch stock (StockApplier owns pulled stock). Push
/// results of this device's `sale.create` arrive ONLY here (the engine
/// routes results to the mutation's own entity applier), so stock is
/// re-based from `stock_after` here, on `applied` only. The engine has
/// already marked the sent outbox row done/rejected when [onPushResult]
/// runs, so a recompute no longer counts this sale as pending.
class SaleApplier implements ChangeApplier {
  SaleApplier({
    SaleLocalStore store = const SaleLocalStore(),
    StockLocalStore stock = const StockLocalStore(),
  }) : _store = store,
       _stock = stock;

  final SaleLocalStore _store;
  final StockLocalStore _stock;

  @override
  String get entity => 'sale';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {
    ...SaleLocalStore.tables,
    'stock',
    'products',
  };

  /// The BE does not version sales (apps/sync/tracking.py: every sale
  /// change carries version 0), so 0 is "no version": only a positive
  /// version may make a pulled change look stale. Otherwise a later cancel
  /// or refund would be dropped as "not newer" forever.
  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async {
    final v = await _store.version(txn, change.id);
    return v == null || v <= 0 ? null : v;
  }

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    if (change.op == 'delete') {
      await _store.delete(txn, change.id);
      return;
    }
    final local = await localVersion(txn, change);
    final v = change.version;
    // Older or replay; unversioned (0) changes apply in feed (seq) order.
    if (v != null && v > 0 && local != null && v <= local) return;

    final Sale sale;
    try {
      sale = _fromFeed(change, await _warnings(txn, change.id));
    } on FormatException catch (e) {
      // A malformed change must not poison the pull page transaction.
      developer.log(
        'SaleApplier: skipping malformed sale ${change.id}: $e',
        name: 'sync',
      );
      return;
    }
    await _store.replaceFromServer(txn, sale);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    switch (result.status) {
      case PushStatus.applied:
        await _store.markSynced(
          txn,
          sent.entityId,
          receiptNumber: result.receiptNumber,
          warnings: result.warnings,
          version: result.version,
        );
        // Only `applied` carries a fresh stock_after; a `duplicate` replays
        // the original (stale) one and must never re-base.
        await _stock.rebaseFromStockAfter(txn, result.stockAfter);
        await _recomputeLines(txn, sent);
      case PushStatus.duplicate:
        await _store.markSynced(
          txn,
          sent.entityId,
          receiptNumber: result.receiptNumber,
          warnings: result.warnings,
          version: result.version,
        );
        // Never re-base on a replay, but the sale is no longer pending: a
        // server level pulled meanwhile already includes it, so keeping the
        // old quantity would count it twice (until some later stock change).
        await _recomputeLines(txn, sent);
      case PushStatus.rejected:
        // Never delete a sale: the pending-sync screen shows it.
        await _store.markRejected(
          txn,
          sent.entityId,
          code: result.code,
          message: result.message,
        );
        // Its local decrement lived only in quantity (never in base), and
        // the row is no longer pending: quantity = base + remaining pending.
        await _recomputeLines(txn, sent);
      case PushStatus.retry:
        break;
    }
  }

  Future<void> _recomputeLines(Transaction txn, OutboxEntry sent) async {
    final shop = sent.payload['shop'];
    final items = sent.payload['items'];
    if (shop is! String || items is! List) return;
    final products = <String>{
      for (final it in items)
        if (it is Map && it['custom'] != true && it['product_id'] is String)
          it['product_id'] as String,
    };
    for (final p in products) {
      await _stock.recompute(txn, p, shop);
    }
  }

  Future<List<String>> _warnings(Transaction txn, String id) async {
    final existing = await _store.read(txn, id);
    return existing?.warnings ?? const [];
  }

  /// Builds a [Sale] from the BE feed shape (apps/sync/feed.py ser_sale).
  static Sale _fromFeed(PullChange c, List<String> warnings) {
    final d = c.data;
    if (d == null) throw const FormatException('no data');
    final shop = d['shop'] ?? c.shopId;
    if (shop is! String) throw const FormatException('no shop');
    // The BE reports a sale on `created_at`: the device `occurred_at`,
    // except when that was > 7 days ahead (`occurred_at_suspect`), where it
    // keeps the server receipt time. Local reporting must use the same day.
    final occurred = d['occurred_at_suspect'] == true
        ? _date(d['created_at']) ??
              _date(d['received_at']) ??
              _date(d['occurred_at'])
        : _date(d['occurred_at']) ?? _date(d['created_at']);
    if (occurred == null) throw const FormatException('no occurred_at');
    final rawItems = d['items'];
    final rawPayments = d['payments'];
    return Sale(
      id: c.id,
      shopId: shop,
      customerId: _strN(d['customer']),
      cashierId: _strN(d['cashier']),
      status: _strN(d['status']) ?? 'completed',
      paymentMethod: _strN(d['payment_method']) ?? '',
      subtotal: _dec(d['total_amount']),
      discount: _dec(d['discount_amount']),
      taxAmount: _dec(d['tax_amount']),
      netAmount: _dec(d['net_amount']),
      taxRate: _dec(d['tax_rate']),
      taxInclusive: d['tax_inclusive'] == true,
      taxName: _strN(d['tax_name']) ?? '',
      receiptNumber: _strN(d['receipt_number']),
      localReceiptNumber: _strN(d['local_receipt_number']),
      deviceId: _strN(d['device_id']),
      occurredAt: occurred,
      receivedAt: _date(d['received_at']),
      version: c.version,
      syncState: 'synced',
      warnings: warnings,
      items: [
        if (rawItems is List)
          for (final it in rawItems)
            if (it is Map) _line(Map<String, dynamic>.from(it)),
      ],
      payments: [
        if (rawPayments is List)
          for (final p in rawPayments)
            if (p is Map)
              SalePaymentPart(
                method: _strN(p['method']) ?? '',
                amount: _dec(p['amount']),
              ),
      ],
    );
  }

  static SaleLine _line(Map<String, dynamic> it) {
    final id = _strN(it['id']);
    if (id == null) throw const FormatException('line without id');
    final custom = it['is_custom'] == true;
    final note = _strN(it['note']);
    final name = _strN(it['product_name']) ?? '';
    return SaleLine(
      id: id,
      productId: _strN(it['product']),
      productName: name.isEmpty && custom ? (note ?? '') : name,
      isCustom: custom,
      quantity: _dec(it['quantity']),
      unitPrice: _dec(it['unit_price']),
      unitCost: it['unit_cost'] == null ? null : _dec(it['unit_cost']),
      discount: it['discount'] == null ? '0' : _dec(it['discount']),
      lineTotal: _dec(it['subtotal']),
      note: note,
      snapshot: const {},
    );
  }

  static String? _strN(Object? v) => v == null ? null : '$v';

  /// Decimal fields arrive as strings; a JSON number is tolerated.
  static String _dec(Object? v) {
    if (v is String && v.isNotEmpty) return v;
    if (v is num) return '$v';
    if (v == null) return '0';
    throw FormatException('bad decimal $v');
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc() : null;
}
