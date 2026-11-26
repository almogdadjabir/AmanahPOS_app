import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';

enum CancelOutcome { done, hasRefunds, notAllowed, notFound }

/// The only writer of local sale cancels. One [LocalWriter.write]: the sale
/// status and the `sale.cancel` outbox row commit together. Stock is
/// re-based from the server's `stock_after` when it syncs (like refunds).
class CancelSaleService {
  CancelSaleService({required LocalWriter writer, DateTime Function()? now})
    : _writer = writer,
      _now = now ?? DateTime.now;

  final LocalWriter _writer;
  final DateTime Function() _now;

  static const int reasonMax = 500;

  static const Set<String> tables = {
    'sale_refunds',
    SaleLocalStore.sales,
    SaleLocalStore.items,
    SyncTables.outbox,
  };

  /// Trim, cut to [reasonMax] by whole characters; null when blank.
  static String? cutReason(String? raw) {
    final t = String.fromCharCodes(
      (raw ?? '').trim().runes.take(reasonMax),
    );
    return t.isEmpty ? null : t;
  }

  Future<CancelOutcome> cancel({required String saleId, String? reason}) {
    final now = _now().toUtc();
    final why = cutReason(reason);
    return _writer.write(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final rows = await txn.query(
          SaleLocalStore.sales,
          where: 'id = ?',
          whereArgs: [saleId],
          limit: 1,
        );
        if (rows.isEmpty) return CancelOutcome.notFound;
        final s = rows.first;
        if (s['status'] == 'cancelled' || s['sync_state'] == 'rejected') {
          return CancelOutcome.notAllowed;
        }
        final refunds = await txn.query(
          'sale_refunds',
          columns: ['id'],
          where: "sale_id = ? AND sync_state != 'rejected'",
          whereArgs: [saleId],
          limit: 1,
        );
        if (refunds.isNotEmpty) return CancelOutcome.hasRefunds;
        await txn.update(
          SaleLocalStore.sales,
          {'status': 'cancelled'},
          where: 'id = ?',
          whereArgs: [saleId],
        );
        await scope.enqueue(
          entity: 'sale',
          op: 'cancel',
          entityId: saleId,
          occurredAt: now,
          payload: {
            'sale_id': saleId,
            if (why != null) 'reason': why,
            'occurred_at': now.toIso8601String(),
          },
          dependsOn: s['sync_state'] != 'synced' ? [saleId] : const [],
        );
        return CancelOutcome.done;
      },
    );
  }
}
