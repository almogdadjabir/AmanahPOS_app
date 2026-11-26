import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_format.dart';
import 'package:amana_pos/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptDoc _doc({double rate = 0, String name = '', bool incl = false}) =>
    ReceiptDoc(
      businessName: '',
      phone: '',
      currency: '',
      number: '1',
      at: DateTime.utc(2026, 11, 26, 12, 5),
      status: 'completed',
      lines: const [],
      subtotal: 0,
      discount: 0,
      tax: 1,
      net: 1,
      paymentMethod: 'cash',
      isSynced: true,
      taxName: name,
      taxRate: rate,
      taxInclusive: incl,
    );

void main() {
  final l = AppLocalizationsEn();
  test('amounts and quantities', () {
    expect(receiptAmount(1234.5), '1,234.50');
    expect(receiptQty(1.5), '1.5');
    expect(receiptQty(2), '2');
  });
  test('date is in business time', () {
    expect(receiptWhen(DateTime.utc(2026, 11, 26, 12, 5), 'Africa/Khartoum'),
        '26 Nov 2026 · 14:05');
  });
  test('tax labels', () {
    expect(receiptTaxLabel(_doc(rate: 15, name: 'VAT'), l),
        'Tax (VAT \u206615\u2069%)');
    expect(receiptTaxLabel(_doc(rate: 15, incl: true), l),
        'Tax incl. \u206615\u2069%');
    expect(receiptTaxLabel(_doc(), l), 'Tax');
  });
}
