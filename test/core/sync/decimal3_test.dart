import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse and format round trip', () {
    expect(Decimal3.parse('12'), BigInt.from(12000));
    expect(Decimal3.parse('-0.5'), BigInt.from(-500));
    expect(Decimal3.parse('1.250'), BigInt.from(1250));
    expect(Decimal3.parse('.5'), BigInt.from(500));
    expect(Decimal3.parse('+3'), BigInt.from(3000));
    expect(Decimal3.format(BigInt.from(7000)), '7');
    expect(Decimal3.format(BigInt.from(-1250)), '-1.25');
    expect(Decimal3.format(BigInt.from(300)), '0.3');
    expect(Decimal3.format(BigInt.zero), '0');
    expect(Decimal3.format(BigInt.from(-5)), '-0.005');
  });

  test('extra fractional digits round half away from zero', () {
    expect(Decimal3.parse('0.0005'), BigInt.one);
    expect(Decimal3.parse('0.0004'), BigInt.zero);
    expect(Decimal3.parse('-0.0005'), BigInt.from(-1));
  });

  test('bad input throws; tryParse returns null', () {
    for (final bad in ['', '.', 'abc', '1e3', '1.2.3', '--1']) {
      expect(() => Decimal3.parse(bad), throwsFormatException, reason: bad);
      expect(Decimal3.tryParse(bad), isNull, reason: bad);
    }
    expect(Decimal3.tryParse(null), isNull);
    expect(Decimal3.tryParse(2.5), BigInt.from(2500));
  });

  test('0.1 summed ten times is exactly 1 (double would drift)', () {
    var sum = BigInt.zero;
    for (var i = 0; i < 10; i++) {
      sum = Decimal3.add(sum, Decimal3.parse('0.1'));
    }
    expect(Decimal3.format(sum), '1');
    expect(Decimal3.format(Decimal3.sub(sum, Decimal3.parse('0.3'))), '0.7');
  });
}
