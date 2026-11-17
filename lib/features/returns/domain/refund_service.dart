import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/sync/decimal3.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../../pos/data/local/sale_local_store.dart';
import '../../pos/domain/sale_math.dart';

class RefundValidationException implements Exception {
  const RefundValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The only writer of local refunds. One [LocalWriter.write]: the pending
/// `sale_refunds` row, the sale status and the `sale.refund` outbox row
/// commit together. Money is exact decimal strings. The BE restocks; stock
/// is re-based from `stock_after` by `SaleApplier`, never changed here.
///
/// The local total is provisional: `SaleApplier.onPushResult` adopts the
/// server's `refund_total` on `applied`.
class RefundService {
  RefundService({
    required LocalWriter writer,
    SaleLocalStore store = const SaleLocalStore(),
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _store = store,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final SaleLocalStore _store;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const Set<String> tables = {
    'sale_refunds',
    SaleLocalStore.sales,
    SaleLocalStore.items,
    SyncTables.outbox,
  };

  /// Refunds [quantitiesByLineId] (`sale_items.id` -> quantity string) of
  /// [saleId]. Returns the refund `reference` (client UUID, the BE
  /// idempotency key, stable across retries).
  Future<String> refund({
    required String saleId,
    required Map<String, String> quantitiesByLineId,
    required String method,
    String? reason,
  }) async {
    if (method.trim().isEmpty) {
      throw const RefundValidationException('Refund method is required');
    }
    final now = _now().toUtc();
    final reference = _uuid.v4();
    return _writer.write(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final sale = await txn.query(
          SaleLocalStore.sales,
          where: 'id = ?',
          whereArgs: [saleId],
          limit: 1,
        );
        if (sale.isEmpty) {
          throw const RefundValidationException('Sale not found');
        }
        final s = sale.first;
        final status = s['status'] as String?;
        if (status == 'cancelled' || s['sync_state'] == 'rejected') {
          throw const RefundValidationException(
            'This sale cannot be refunded',
          );
        }
        final shopId = s['shop_id'] as String;
        final lines = {
          for (final l in await txn.query(
            SaleLocalStore.items,
            where: 'sale_id = ?',
            whereArgs: [saleId],
          ))
            l['id'] as String: l,
        };
        final done = await _store.refundedQuantities(txn, saleId);
        var cents = BigInt.zero;
        final items = <Map<String, String>>[];
        final payloadItems = <Map<String, String>>[];
        for (final e in quantitiesByLineId.entries) {
          final line = lines[e.key];
          final q = Decimal3.tryParse(e.value);
          if (line == null) {
            throw const RefundValidationException('Unknown sale line');
          }
          if (q == null || q <= BigInt.zero) {
            throw const RefundValidationException('Invalid quantity');
          }
          final sold = Decimal3.parse('${line['quantity']}');
          final back = done[e.key] ?? BigInt.zero;
          if (back + q > sold) {
            throw const RefundValidationException(
              'Quantity exceeds what is left to return',
            );
          }
          final lineTotal = ExactDecimal.parse('${line['line_total']}');
          // Cumulative proration: successive partial refunds of one line sum
          // exactly to its total (never 0.03 + 0.03 of a 0.05 line).
          BigInt prorated(BigInt qty) => ExactDecimal.divRoundHalfUp(
            lineTotal.units * qty * BigInt.from(100),
            sold * BigInt.from(10).pow(lineTotal.scale),
          );
          final amount = prorated(back + q) - prorated(back);
          cents += amount;
          final qs = Decimal3.format(q);
          items.add({
            'sale_item': e.key,
            'quantity': qs,
            'amount': ExactDecimal.formatUnits(amount, 2),
          });
          payloadItems.add({'sale_item_id': e.key, 'quantity': qs});
        }
        if (items.isEmpty) {
          throw const RefundValidationException('Nothing selected');
        }
        final total = ExactDecimal.formatUnits(cents, 2);
        final trimmed = reason?.trim();
        await txn.insert('sale_refunds', {
          'id': reference,
          'sale_id': saleId,
          'shop_id': shopId,
          'total': total,
          'occurred_at': now.toIso8601String(),
          'method': method,
          'reference': reference,
          'sync_state': 'pending',
          'reason': trimmed,
          'json': jsonEncode({
            'id': reference,
            'sale': saleId,
            'shop': shopId,
            'reference': reference,
            'total': total,
            'method': method,
            'notes': trimmed ?? '',
            'items': items,
          }),
        });
        await _store.recomputeRefundStatus(txn, saleId);
        final saleUnsent = s['sync_state'] != 'synced';
        await scope.enqueue(
          entity: 'sale',
          op: 'refund',
          entityId: saleId,
          occurredAt: now,
          payload: {
            'sale_id': saleId,
            'reference': reference,
            'items': payloadItems,
            'method': method,
            if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed,
            'occurred_at': now.toIso8601String(),
          },
          dependsOn: saleUnsent ? [saleId] : const [],
        );
        return reference;
      },
    );
  }

  /// What the "return recorded" sheet shows for [reference]: the stored
  /// refund with each returned line's name and unit price, and whether the
  /// sale is now fully returned.
  Future<RefundReceipt> receiptFor(String reference) {
    return _writer.read((db) async {
      final r = (await db.query(
        'sale_refunds',
        where: 'reference = ?',
        whereArgs: [reference],
        limit: 1,
      )).single;
      final saleId = r['sale_id'] as String;
      final j = jsonDecode(r['json'] as String) as Map;
      final lines = {
        for (final l in await db.query(
          SaleLocalStore.items,
          where: 'sale_id = ?',
          whereArgs: [saleId],
        ))
          l['id'] as String: l,
      };
      final sale = (await db.query(
        SaleLocalStore.sales,
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [saleId],
      )).single;
      return RefundReceipt(
        reference: reference,
        total: '${r['total']}',
        fullRefund: sale['status'] == 'refunded',
        items: [
          for (final it in (j['items'] as List).cast<Map>())
            RefundReceiptItem(
              productId: lines['${it['sale_item']}']?['product_id'] as String?,
              productName:
                  '${lines['${it['sale_item']}']?['product_name'] ?? ''}',
              quantity: '${it['quantity']}',
              unitPrice: '${lines['${it['sale_item']}']?['unit_price'] ?? '0'}',
              subtotal: '${it['amount']}',
            ),
        ],
      );
    });
  }
}

class RefundReceiptItem {
  const RefundReceiptItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
  final String? productId;
  final String productName;
  final String quantity;
  final String unitPrice;
  final String subtotal;
}

class RefundReceipt {
  const RefundReceipt({
    required this.reference,
    required this.total,
    required this.fullRefund,
    required this.items,
  });
  final String reference;
  final String total;
  final bool fullRefund;
  final List<RefundReceiptItem> items;
}
