import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/receipt/domain/receipt_doc_builder.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _biz = ReceiptBusiness(name: 'Shop', phone: '+249', currency: 'SDG');

SaleHistoryItem _sale({
  List<SaleHistoryRefund> refunds = const [],
  bool offline = false,
  List<SaleHistoryPayment> payments = const [],
  double qty = 2,
}) => SaleHistoryItem(
  id: 's1',
  clientSaleId: 's1',
  receiptNumber: 'R-1',
  shopId: 'sh',
  shopName: null,
  customerId: null,
  customerName: null,
  paymentMethod: 'cash',
  total: 10,
  itemCount: 1,
  status: SaleHistoryStatus.completed,
  createdAt: DateTime.utc(2026, 11, 26, 10),
  isOfflinePending: offline,
  offlineErrorMessage: null,
  items: [
    SaleHistoryLineItem(
      productId: 'p',
      productName: 'Sugar',
      quantity: qty,
      unitPrice: 5,
      subtotal: 10,
      discount: 1,
    ),
  ],
  refunds: refunds,
  payments: payments,
);

void main() {
  test('plain sale copies number, totals and line discount', () {
    final d = buildReceiptDoc(_sale(), business: _biz);
    expect(d.number, 'R-1');
    expect(d.net, 10);
    expect(d.subtotal, 10);
    expect(d.lines.single.discount, 1);
    expect(d.isSynced, isTrue);
  });

  test('fractional quantity is kept', () {
    final d = buildReceiptDoc(_sale(qty: 1.5), business: _biz);
    expect(d.lines.single.quantity, 1.5);
  });

  test('rejected refunds are dropped', () {
    final d = buildReceiptDoc(
      _sale(
        refunds: [
          SaleHistoryRefund(
            reference: 'a',
            total: 3,
            createdAt: DateTime.utc(2026, 11, 26),
            syncState: 'rejected',
          ),
          SaleHistoryRefund(
            reference: 'b',
            total: 4,
            createdAt: DateTime.utc(2026, 11, 26),
            method: 'cash',
          ),
        ],
      ),
      business: _biz,
    );
    expect(d.refunds.length, 1);
    expect(d.refunded, 4);
  });

  test('payment parts are copied', () {
    final d = buildReceiptDoc(
      _sale(
        payments: const [
          SaleHistoryPayment(method: 'cash', amount: 6),
          SaleHistoryPayment(method: 'credit', amount: 4),
        ],
      ),
      business: _biz,
    );
    expect(d.payments.length, 2);
  });

  test('isSynced is false when offline pending', () {
    expect(buildReceiptDoc(_sale(offline: true), business: _biz).isSynced,
        isFalse);
  });
}
