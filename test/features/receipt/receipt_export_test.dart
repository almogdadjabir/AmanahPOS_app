import 'dart:convert';
import 'dart:typed_data';

import 'package:amana_pos/features/receipt/services/receipt_export.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  test('pdf is built from the picture and starts with %PDF', () async {
    final pdf = await buildReceiptPdf(
      Uint8List.fromList(_png),
      widthPx: 302.36,
      heightPx: 400,
    );
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    expect(pdf.length, greaterThan(200));
  });

  test('file names are safe', () {
    expect(receiptFileName('S-00123', 'png'), 'receipt_S-00123.png');
    expect(receiptFileName('a/b c', 'pdf'), 'receipt_a_b_c.pdf');
  });
}
