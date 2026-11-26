import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';

/// Builds the receipt of one sale. Refunds the server rejected are left out:
/// they never happened (same rule as the desktop `BuildReceipt`).
ReceiptDoc buildReceiptDoc(
  SaleHistoryItem sale, {
  required ReceiptBusiness business,
  String? cashierName,
  String? customerName,
  double? customerOwes,
}) {
  final lineSum = sale.items.fold<double>(0, (a, i) => a + i.subtotal);
  return ReceiptDoc(
    businessName: business.name,
    phone: business.phone,
    logo: business.logo,
    currency: business.currency,
    number: sale.displayRef,
    at: sale.createdAt,
    status: _statusKey(sale.status),
    lines: [
      for (final l in sale.items)
        ReceiptDocLine(
          name: l.productName,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
          total: l.subtotal,
          returned: l.returnedQuantity,
          discount: l.discount,
        ),
    ],
    subtotal: sale.subtotal > 0 ? sale.subtotal : lineSum,
    discount: sale.discount,
    tax: sale.taxAmount,
    net: sale.total,
    paymentMethod: sale.paymentMethod,
    payments: [
      for (final p in sale.payments)
        ReceiptDocPayment(method: p.method, amount: p.amount),
    ],
    refunds: [
      for (final r in sale.refunds.where((r) => !r.isRejected))
        ReceiptDocRefund(at: r.createdAt, method: r.method, total: r.total),
    ]..sort((a, b) => a.at.compareTo(b.at)),
    isSynced:
        !(sale.isOfflinePending || sale.status == SaleHistoryStatus.pending),
    customerName: customerName ?? sale.customerName,
    customerOwes: customerOwes,
    cashierName: cashierName ?? sale.cashierName,
    timezone: business.timezone,
    taxName: sale.taxName,
    taxRate: sale.taxRate,
    taxInclusive: sale.taxInclusive,
  );
}

String _statusKey(SaleHistoryStatus s) => switch (s) {
  SaleHistoryStatus.completed => 'completed',
  SaleHistoryStatus.refunded => 'refunded',
  SaleHistoryStatus.partialRefund => 'partial_refund',
  SaleHistoryStatus.cancelled => 'cancelled',
  SaleHistoryStatus.failed => 'failed',
  SaleHistoryStatus.pending => 'pending',
  SaleHistoryStatus.unknown => 'completed',
};
