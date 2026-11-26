import 'dart:convert';

import 'package:amana_pos/features/receipt/data/receipt_context_loader.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';

SaleHistoryItem _sale() => SaleHistoryItem(
  id: 's1',
  clientSaleId: 's1',
  receiptNumber: 'R1',
  shopId: null,
  shopName: null,
  customerId: null,
  customerName: null,
  paymentMethod: 'cash',
  total: 1,
  itemCount: 0,
  status: SaleHistoryStatus.completed,
  createdAt: DateTime.utc(2026),
  isOfflinePending: false,
  offlineErrorMessage: null,
  items: const [],
);

void main() {
  test('reads settings from the business feed row', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    await db.insert('synced_entities', {
      'entity': 'business',
      'id': 'b1',
      'json': jsonEncode({
        'name': 'Al Noor',
        'phone': '+249111',
        'currency': 'SDG',
        'receipt_paper_width': 58,
        'receipt_footer': ' ' + 'x' * 100,
      }),
    });
    final c = await ReceiptContextLoader(odb).load(_sale());
    expect(c.business.name, 'Al Noor');
    expect(c.settings.paperMm, 58);
    expect(c.settings.footer.length, 80);
  });

  test('no row gives the defaults', () async {
    final odb = await openTestDb();
    addTearDown((await odb.database).close);
    final c = await ReceiptContextLoader(odb).load(_sale());
    expect(c.settings.paperMm, 80);
    expect(c.settings.showLogo, isTrue);
    expect(c.business.name, '');
  });
}
