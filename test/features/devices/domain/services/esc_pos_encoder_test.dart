import 'package:amana_pos/features/devices/domain/entities/receipt_data.dart';
import 'package:amana_pos/features/devices/domain/services/esc_pos_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const encoder = EscPosEncoder();

  ReceiptData receipt({String businessName = 'Amana Store'}) {
    return ReceiptData(
      businessName: businessName,
      reference: 'Ref: RCP-001',
      dateLabel: '12 Jun 2026 10:30',
      lines: const [
        ReceiptLine(name: 'Sugar 1kg', quantity: 2, amount: '2,400 SDG'),
        ReceiptLine(
          name: 'A very very very long product name that overflows',
          quantity: 1,
          amount: '900 SDG',
        ),
      ],
      summary: const [
        ReceiptRow(label: 'Subtotal', value: '3,300 SDG'),
        ReceiptRow(label: 'TOTAL', value: '3,300 SDG', emphasized: true),
      ],
      paymentLabel: 'Cash',
      offlineNote: 'Saved offline - pending sync',
    );
  }

  String decodeLines(List<int> bytes) => String.fromCharCodes(bytes);

  group('EscPosEncoder.encodeReceipt', () {
    test('starts with printer initialization (ESC @)', () {
      final bytes = encoder.encodeReceipt(receipt());
      expect(bytes.sublist(0, 2), [0x1B, 0x40]);
    });

    test('ends with feed and partial cut (GS V 66)', () {
      final bytes = encoder.encodeReceipt(receipt());
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    });

    test('item lines are exactly charsPerLine wide', () {
      final bytes = encoder.encodeReceipt(receipt());
      final text = decodeLines(bytes);
      final itemLine = text
          .split('\n')
          .firstWhere((line) => line.contains('Sugar 1kg'));
      expect(itemLine.length, EscPosEncoder.defaultCharsPerLine);
      expect(itemLine, endsWith('x2  2,400 SDG'));
    });

    test('long item names are truncated to keep amounts aligned', () {
      final bytes = encoder.encodeReceipt(receipt());
      final text = decodeLines(bytes);
      final longLine = text
          .split('\n')
          .firstWhere((line) => line.contains('A very very'));
      expect(longLine.length, EscPosEncoder.defaultCharsPerLine);
      expect(longLine, endsWith('x1  900 SDG'));
    });

    test('replaces non-ASCII characters with ?', () {
      final bytes = encoder.encodeReceipt(receipt(businessName: 'متجر أمانة'));
      final text = decodeLines(bytes);
      expect(text, isNot(contains('متجر')));
      expect(text, contains('?'));
    });

    test('includes summary rows, payment and footer', () {
      final text = decodeLines(encoder.encodeReceipt(receipt()));
      expect(text, contains('Subtotal'));
      expect(text, contains('TOTAL'));
      expect(text, contains('Cash'));
      expect(text, contains('Powered by AmanaPOS'));
      expect(text, contains('Saved offline - pending sync'));
    });

    test('58mm width (32 cols) keeps lines at 32 chars', () {
      const narrow = EscPosEncoder(charsPerLine: 32);
      final text = decodeLines(narrow.encodeReceipt(receipt()));
      final itemLine =
          text.split('\n').firstWhere((line) => line.contains('Sugar 1kg'));
      expect(itemLine.length, 32);
    });
  });

  group('EscPosEncoder.encodeTestTicket', () {
    test('contains printer name and cut command', () {
      final bytes = encoder.encodeTestTicket(
        businessName: 'Amana Store',
        printerName: 'SAM4s Compact 3"',
        dateLabel: '12 Jun 2026 10:30',
      );
      final text = decodeLines(bytes);
      expect(text, contains('SAM4s Compact 3"'));
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    });
  });
}
