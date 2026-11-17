import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_list_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

SaleHistoryItem _sale(
  SaleHistoryStatus status, {
  bool offline = false,
  String? id = 's1',
}) => SaleHistoryItem(
  id: id,
  clientSaleId: 'c1',
  receiptNumber: 'AM-1',
  shopId: null,
  shopName: null,
  customerId: null,
  customerName: null,
  paymentMethod: 'cash',
  total: 100,
  itemCount: 1,
  status: status,
  createdAt: DateTime(2026, 11, 15),
  isOfflinePending: offline,
  offlineErrorMessage: null,
  items: const [],
);

void main() {
  group('SaleHistoryItem.canBeReturned', () {
    test('completed and partly returned sales can be returned', () {
      expect(_sale(SaleHistoryStatus.completed).canBeReturned, isTrue);
      expect(_sale(SaleHistoryStatus.partialRefund).canBeReturned, isTrue);
    });

    test('refunded, cancelled, pending and failed sales cannot', () {
      for (final s in [
        SaleHistoryStatus.refunded,
        SaleHistoryStatus.cancelled,
        SaleHistoryStatus.pending,
        SaleHistoryStatus.failed,
      ]) {
        expect(_sale(s).canBeReturned, isFalse, reason: '$s');
      }
    });

    test('an unsynced completed sale can (the refund queues behind it)', () {
      expect(
        _sale(SaleHistoryStatus.completed, offline: true).canBeReturned,
        isTrue,
      );
      expect(
        _sale(SaleHistoryStatus.completed, id: null).canBeReturned,
        isFalse,
      );
    });
  });

  group('line quantities', () {
    test('returnableQuantity is what is left, never negative', () {
      const l = SaleHistoryLineItem(
        productId: 'p',
        productName: 'x',
        quantity: 2.5,
        unitPrice: 10,
        subtotal: 25,
        returnedQuantity: 1,
      );
      expect(l.returnableQuantity, 1.5);
      const over = SaleHistoryLineItem(
        productId: 'p',
        productName: 'x',
        quantity: 1,
        unitPrice: 10,
        subtotal: 10,
        returnedQuantity: 3,
      );
      expect(over.returnableQuantity, 0);
    });
  });

  test('SaleDto parses cashier, discount, refunds and per line returns', () {
    final dto = SaleDto.fromJson({
      'id': 's1',
      'receipt_number': 'AM-1',
      'cashier_name': 'Mohamed',
      'discount_amount': '50.00',
      'notes': 'hi',
      'net_amount': '950.00',
      'status': 'partial_refund',
      'created_at': '2026-11-15T09:00:00Z',
      'refunds': [
        {
          'reference': 'AM-1-R1',
          'total': '19000.00',
          'created_at': '2026-11-15T10:00:00Z',
        },
      ],
      'items': [
        {
          'id': 'i1',
          'product': null,
          'product_name': 'Custom amount',
          'is_custom': true,
          'quantity': '2.500',
          'unit_price': '10.00',
          'subtotal': '25.00',
          'returned_quantity': '1.000',
        },
      ],
    });
    final item = SaleHistoryItem.fromDto(dto);
    expect(item.cashierName, 'Mohamed');
    expect(item.discount, 50);
    expect(item.refundedTotal, 19000);
    expect(item.refunds.single.reference, 'AM-1-R1');
    final line = item.items.single;
    expect(line.lineId, 'i1');
    expect(line.isCustom, isTrue);
    expect(line.returnedQuantity, 1);
    expect(line.returnableQuantity, 1.5);
    expect(item.status, SaleHistoryStatus.partialRefund);
  });
}
