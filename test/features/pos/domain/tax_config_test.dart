import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaxConfig.fromBusiness', () {
    test('maps fields and parses rate', () {
      final business = BusinessData.fromJson({
        'tax_enabled': true,
        'tax_name': 'GST',
        'tax_rate': '7.50',
        'tax_inclusive': true,
      });
      final config = TaxConfig.fromBusiness(business);

      expect(config.enabled, true);
      expect(config.name, 'GST');
      expect(config.rate, 7.5);
      expect(config.inclusive, true);
      expect(config.isActive, true);
    });

    test('null business and missing fields default to disabled', () {
      expect(TaxConfig.fromBusiness(null).isActive, false);

      final config = TaxConfig.fromBusiness(BusinessData.fromJson({}));
      expect(config.enabled, false);
      expect(config.name, 'VAT');
      expect(config.rate, 0);
      expect(config.inclusive, false);
      expect(config.isActive, false);
    });

    test('enabled with zero rate is not active', () {
      final config = TaxConfig.fromBusiness(BusinessData.fromJson({
        'tax_enabled': true,
        'tax_rate': '0.00',
      }));
      expect(config.isActive, false);
    });
  });

  group('formatTaxRate', () {
    test('whole rates drop decimals', () {
      expect(formatTaxRate(15.0), '15');
    });
    test('fractional rates keep significant decimals', () {
      expect(formatTaxRate(7.5), '7.5');
    });
  });

  group('TaxCalculator.compute', () {
    const exclusive = TaxConfig(
      enabled: true, name: 'VAT', rate: 15, inclusive: false);
    const inclusive = TaxConfig(
      enabled: true, name: 'VAT', rate: 15, inclusive: true);

    test('exclusive: tax added on top (spec example)', () {
      final r = TaxCalculator.compute(taxableAmount: 90.00, config: exclusive);
      expect(r.taxAmount, 13.50);
      expect(r.netAmount, 103.50);
    });

    test('inclusive: tax extracted from price (spec example)', () {
      final r = TaxCalculator.compute(taxableAmount: 90.00, config: inclusive);
      expect(r.taxAmount, 11.74);
      expect(r.netAmount, 90.00);
    });

    test('disabled: zero tax, net = taxable', () {
      final r = TaxCalculator.compute(
        taxableAmount: 90.00, config: const TaxConfig.disabled());
      expect(r.taxAmount, 0);
      expect(r.netAmount, 90.00);
    });

    test('rounds to 2 decimals half-up', () {
      // 33.33 * 0.15 ≈ 4.9995 → 5.00. Note: exact half-cent boundaries can
      // drift ±0.01 vs the server's Decimal math (see _round2 in tax_config).
      const cfg = TaxConfig(enabled: true, name: 'VAT', rate: 15, inclusive: false);
      final r = TaxCalculator.compute(taxableAmount: 33.33, config: cfg);
      expect(r.taxAmount, 5.00);
    });
  });
}
