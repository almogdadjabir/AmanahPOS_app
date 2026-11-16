import 'package:amana_pos/features/pos/domain/sale_math.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected values were produced with Python `decimal` using the exact
/// formulas of the BE `apps/sales/services.py::create_sale` (ROUND_HALF_UP to
/// 0.01 for tax and net when the rate is > 0; net = taxable otherwise).
void main() {
  SaleTotals run(
    List<SaleMathLine> lines, {
    String discount = '0',
    String rate = '0',
    bool inclusive = false,
  }) => SaleMath.compute(
    lines: lines,
    discount: discount,
    taxRate: rate,
    taxInclusive: inclusive,
  );

  SaleMathLine line(String qty, String price, {String discount = '0'}) =>
      SaleMathLine(quantity: qty, unitPrice: price, discount: discount);

  group('mirrors BE create_sale', () {
    test('exclusive 15% on 90.00', () {
      final t = run([line('1', '90.00')], rate: '15');
      expect(t.subtotal, '90.00');
      expect(t.taxAmount, '13.50');
      expect(t.netAmount, '103.50');
    });

    test('inclusive 15% on 90.00', () {
      final t = run([line('1', '90.00')], rate: '15', inclusive: true);
      expect(t.taxAmount, '11.74');
      expect(t.netAmount, '90.00');
    });

    test('exclusive half-cent boundary 1.50 @ 15% rounds half up', () {
      // A double-based calculator gives 0.22 / 1.72 here.
      final t = run([line('1', '1.50')], rate: '15');
      expect(t.taxAmount, '0.23');
      expect(t.netAmount, '1.73');
    });

    test('inclusive with sale discount', () {
      final t = run(
        [line('1', '100.00')],
        discount: '10',
        rate: '5',
        inclusive: true,
      );
      expect(t.subtotal, '100.00');
      expect(t.discount, '10.00');
      expect(t.taxAmount, '4.29');
      expect(t.netAmount, '90.00');
    });

    test('exclusive 7.5% on 33.33', () {
      final t = run([line('3', '11.11')], rate: '7.5');
      expect(t.subtotal, '33.33');
      expect(t.taxAmount, '2.50');
      expect(t.netAmount, '35.83');
    });

    test('inclusive 16% on 19.99', () {
      final t = run([line('1', '19.99')], rate: '16', inclusive: true);
      expect(t.taxAmount, '2.76');
      expect(t.netAmount, '19.99');
    });

    test('fractional quantity, line discount, exclusive 12.5%', () {
      // total 12.345, sale discount 1.10 -> taxable 11.245
      final t = run([line('2.469', '5.00')], discount: '1.10', rate: '12.5');
      expect(t.taxAmount, '1.41');
      expect(t.netAmount, '12.65');
    });

    test('inclusive 33.33% on 7.77', () {
      final t = run([line('1', '7.77')], rate: '33.33', inclusive: true);
      expect(t.taxAmount, '1.94');
      expect(t.netAmount, '7.77');
    });

    test('no tax: net = taxable rounded to cents', () {
      final t = run([line('0.333', '1.00')]);
      expect(t.taxAmount, '0.00');
      expect(t.netAmount, '0.33');
    });

    test('line discount is subtracted from the line total', () {
      final t = run([line('2', '10.00', discount: '1.50')]);
      expect(t.lineTotals, ['18.50']);
      expect(t.netAmount, '18.50');
    });

    test('0.1 + 0.2 sums exactly (no double drift)', () {
      final t = run([line('1', '0.10'), line('1', '0.20')]);
      expect(t.subtotal, '0.30');
      expect(t.netAmount, '0.30');
    });
  });

  group('tax snapshot of a TaxConfig', () {
    test('inactive config sends rate 0 (BE would otherwise use rate>0)', () {
      const c = TaxConfig(
        enabled: false,
        name: 'VAT',
        rate: 15,
        inclusive: true,
      );
      expect(SaleMath.taxRateOf(c), '0');
    });

    test('active config: 2 decimals, trimmed', () {
      expect(
        SaleMath.taxRateOf(
          const TaxConfig(
            enabled: true,
            name: 'VAT',
            rate: 15,
            inclusive: false,
          ),
        ),
        '15',
      );
      expect(
        SaleMath.taxRateOf(
          const TaxConfig(
            enabled: true,
            name: 'VAT',
            rate: 7.5,
            inclusive: false,
          ),
        ),
        '7.5',
      );
    });
  });

  group('payments tolerance', () {
    test('within 0.01 accepted, beyond rejected', () {
      expect(SaleMath.paymentsMatch(['103.50'], '103.50'), isTrue);
      expect(SaleMath.paymentsMatch(['100', '3.49'], '103.50'), isTrue);
      expect(SaleMath.paymentsMatch(['100', '3.48'], '103.50'), isFalse);
      expect(SaleMath.paymentsMatch(['103.52'], '103.50'), isFalse);
    });
  });

  test('money parsing rejects garbage and normalises to cents', () {
    expect(SaleMath.money('12.5'), '12.50');
    expect(SaleMath.money('12.505'), '12.51');
    expect(() => SaleMath.money('abc'), throwsFormatException);
  });
}
