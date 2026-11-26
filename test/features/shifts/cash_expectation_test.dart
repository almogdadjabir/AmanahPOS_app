import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt c(String s) => Cents.parse(s)!;

void main() {
  group('Cents', () {
    test('parses and formats two decimals', () {
      expect(Cents.parse('12.5'), BigInt.from(1250));
      expect(Cents.parse('1,250.00'), isNull);
      expect(Cents.parse(' 250 '), BigInt.from(25000));
      expect(Cents.format(BigInt.from(-505)), '-5.05');
      expect(Cents.format(BigInt.zero), '0.00');
    });
    test('rejects junk and negatives when asked', () {
      expect(Cents.parse(''), isNull);
      expect(Cents.parse('abc'), isNull);
      expect(Cents.parse('-3'), BigInt.from(-300));
      expect(Cents.parse('-3', allowNegative: false), isNull);
    });
    test('rounds a third decimal half up', () {
      expect(Cents.parse('0.005'), BigInt.one);
      expect(Cents.parse('0.004'), BigInt.zero);
    });
  });

  group('CashExpectation', () {
    test('opening only', () {
      expect(CashExpectation.expected(CashParts.openingOnly(c('500'))), c('500'));
    });

    test('adds opening, cash sales, debt payments, pay ins; subtracts the rest',
        () {
      final p = CashParts(
        opening: c('500'),
        cashSales: c('940'),
        debtPayments: c('10'),
        payIns: c('50'),
        refunds: c('60'),
        cancels: c('20'),
        payOuts: c('125'),
      );
      // 500 + 940 + 10 + 50 - 60 - 20 - 125
      expect(CashExpectation.expected(p), c('1295'));
    });

    test('difference is counted minus expected, negative when short', () {
      expect(CashExpectation.difference(c('1280'), c('1285')), c('-5'));
      expect(CashExpectation.difference(c('1287'), c('1285')), c('2'));
    });

    test('a pay out beyond the drawer is flagged but allowed', () {
      expect(CashExpectation.payOutExceeds(c('100'), c('100.01')), isTrue);
      expect(CashExpectation.payOutExceeds(c('100'), c('100')), isFalse);
    });
  });
}
