import 'dart:io';

import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_paper.dart';
import 'package:amana_pos/l10n/app_localizations_ar.dart';
import 'package:amana_pos/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures shared with the desktop comparison (docs/audits/receipt-compare).
final _at = DateTime.utc(2026, 11, 26, 12, 5);

ReceiptDoc _base({
  List<ReceiptDocLine>? lines,
  double subtotal = 13,
  double discount = 0,
  double tax = 0,
  double net = 13,
  String method = 'cash',
  List<ReceiptDocPayment> payments = const [],
  List<ReceiptDocRefund> refunds = const [],
  bool synced = true,
  String status = 'completed',
  double? owes,
  double rate = 0,
  String taxName = '',
  bool incl = false,
  String business = 'Al-Noor Market',
}) => ReceiptDoc(
  businessName: business,
  phone: '+249 912 345 678',
  currency: 'SDG',
  number: 'S-00123',
  at: _at,
  status: status,
  lines:
      lines ??
      const [
        ReceiptDocLine(
          name: 'Sugar 1kg',
          quantity: 2,
          unitPrice: 4,
          total: 8,
        ),
        ReceiptDocLine(
          name: 'Tea',
          quantity: 1,
          unitPrice: 5,
          total: 5,
        ),
      ],
  subtotal: subtotal,
  discount: discount,
  tax: tax,
  net: net,
  paymentMethod: method,
  payments: payments,
  refunds: refunds,
  isSynced: synced,
  cashierName: 'Omar',
  customerOwes: owes,
  timezone: 'Africa/Khartoum',
  taxName: taxName,
  taxRate: rate,
  taxInclusive: incl,
);

final fixtures = <String, ReceiptDoc>{
  'plain': _base(),
  'discount_tax': _base(
    lines: const [
      ReceiptDocLine(
        name: 'Tea',
        quantity: 1.5,
        unitPrice: 5,
        total: 7,
        discount: 0.5,
      ),
    ],
    subtotal: 7,
    discount: 1,
    tax: 0.9,
    net: 6.9,
    rate: 15,
    taxName: 'VAT',
  ),
  'tax_inclusive': _base(tax: 1.7, rate: 15, taxName: 'VAT', incl: true),
  'split_credit': _base(
    method: 'split',
    payments: const [
      ReceiptDocPayment(method: 'cash', amount: 8),
      ReceiptDocPayment(method: 'credit', amount: 5),
    ],
    owes: 25,
  ),
  'refunded': _base(
    status: 'partial_refund',
    refunds: [ReceiptDocRefund(at: _at, method: 'cash', total: 4)],
    lines: const [
      ReceiptDocLine(
        name: 'Sugar 1kg',
        quantity: 2,
        unitPrice: 4,
        total: 8,
        returned: 1,
      ),
    ],
    subtotal: 8,
    net: 8,
  ),
  'not_synced_long': _base(
    synced: false,
    lines: const [
      ReceiptDocLine(
        name:
            'Extra long product name that must wrap onto a second line cleanly',
        quantity: 3,
        unitPrice: 12.5,
        total: 37.5,
      ),
    ],
    subtotal: 37.5,
    net: 37.5,
  ),
};

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }

  await load('Selawik', ['Selawik-Regular.ttf', 'Selawik-Bold.ttf']);
  await load('IBMPlexSansArabic', [
    'IBMPlexSansArabic-Regular.ttf',
    'IBMPlexSansArabic-Bold.ttf',
  ]);
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: RepaintBoundary(key: const ValueKey('paper'), child: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    ReceiptDoc doc, {
    required bool ar,
    int mm = 80,
  }) async {
    final l = ar ? AppLocalizationsAr() : AppLocalizationsEn();
    final w = ReceiptPaper.widthFor(mm);
    tester.view.physicalSize = Size(w, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        ReceiptPaper(
          doc: doc,
          settings: ReceiptSettings(paperMm: mm),
          l: l,
          isRtl: ar,
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('paper')),
      matchesGoldenFile('goldens/${name}_${ar ? 'ar' : 'en'}_$mm.png'),
    );
  }

  for (final e in fixtures.entries) {
    testWidgets('${e.key} en 80', (t) => shoot(t, e.key, e.value, ar: false));
    testWidgets('${e.key} ar 80', (t) => shoot(t, e.key, e.value, ar: true));
  }
  testWidgets('plain en 58', (t) => shoot(t, 'plain', fixtures['plain']!, ar: false, mm: 58));
  testWidgets('long en 58', (t) => shoot(t, 'not_synced_long', fixtures['not_synced_long']!, ar: false, mm: 58));

  test('widths: 80 mm and 58 mm', () {
    expect(ReceiptPaper.widthFor(80), closeTo(302.36, 0.01));
    expect(ReceiptPaper.widthFor(58), closeTo(219.21, 0.01));
    expect(ReceiptPaper.widthFor(72), closeTo(302.36, 0.01));
  });
}
