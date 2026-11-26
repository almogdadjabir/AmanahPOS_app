import 'package:amana_pos/features/pos/domain/split_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final total = BigInt.from(500000); // 5,000.00

  test('nothing typed is incomplete with the full total left', () {
    final e = SplitPayment.evaluate(total: total, cash: '', bankak: '');
    expect(e.status, SplitStatus.incomplete);
    expect(e.left, total);
    expect(e.parts, isEmpty);
  });

  test('parts that add up exactly give two parts', () {
    final e = SplitPayment.evaluate(total: total, cash: '3000', bankak: '2000.00');
    expect(e.status, SplitStatus.exact);
    expect([for (final p in e.parts) '${p.method}:${p.amount}'], [
      'cash:3000.00',
      'bankak:2000.00',
    ]);
  });

  test('one row equal to the total is one part', () {
    final e = SplitPayment.evaluate(total: total, cash: '', bankak: '5000');
    expect(e.status, SplitStatus.exact);
    expect(e.parts.single.method, 'bankak');
  });

  test('a zero row is dropped', () {
    final e = SplitPayment.evaluate(total: total, cash: '0', bankak: '5000');
    expect(e.parts.length, 1);
  });

  test('over reports how much too much', () {
    final e = SplitPayment.evaluate(total: total, cash: '3500', bankak: '2000');
    expect(e.status, SplitStatus.over);
    expect(e.left, BigInt.from(50000));
    expect(e.parts, isEmpty);
  });

  test('one cent short is not exact', () {
    final e = SplitPayment.evaluate(total: total, cash: '3000', bankak: '1999.99');
    expect(e.status, SplitStatus.incomplete);
    expect(e.left, BigInt.one);
  });

  test('garbage and negatives are invalid', () {
    expect(SplitPayment.evaluate(total: total, cash: 'abc', bankak: '').status,
        SplitStatus.invalid);
    expect(SplitPayment.evaluate(total: total, cash: '-5', bankak: '').status,
        SplitStatus.invalid);
  });

  test('fill rest adds what is left to the row', () {
    expect(
      SplitPayment.fillRest(total: total, cash: '3000', bankak: '', intoCash: false),
      '2000.00',
    );
    expect(
      SplitPayment.fillRest(total: total, cash: '1000', bankak: '500', intoCash: true),
      '4500.00',
    );
  });

  test('fill rest does nothing when exact or over', () {
    expect(
      SplitPayment.fillRest(total: total, cash: '5000', bankak: '', intoCash: false),
      isNull,
    );
    expect(
      SplitPayment.fillRest(total: total, cash: '6000', bankak: '', intoCash: true),
      isNull,
    );
  });

  test('matches detects a changed cart total', () {
    final parts = SplitPayment.evaluate(total: total, cash: '3000', bankak: '2000').parts;
    expect(SplitPayment.matches(parts, total), isTrue);
    expect(SplitPayment.matches(parts, total + BigInt.one), isFalse);
  });
}
