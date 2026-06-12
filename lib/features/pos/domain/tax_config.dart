import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:equatable/equatable.dart';

/// "15" for 15.00, "7.5" for 7.50 — used in labels like "Tax (VAT 15%)".
String formatTaxRate(double rate) {
  if (rate % 1 == 0) return rate.toStringAsFixed(0);
  final s = rate.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

/// Snapshot of the business's tax settings (docs/TAX_SUPPORT.md §1).
class TaxConfig extends Equatable {
  final bool enabled;
  final String name;

  /// Percentage 0–100, e.g. 15.0 for 15%.
  final double rate;
  final bool inclusive;

  const TaxConfig({
    required this.enabled,
    required this.name,
    required this.rate,
    required this.inclusive,
  });

  const TaxConfig.disabled()
      : enabled = false,
        name = 'VAT',
        rate = 0,
        inclusive = false;

  factory TaxConfig.fromBusiness(BusinessData? business) {
    if (business == null) return const TaxConfig.disabled();
    final name = business.taxName?.trim();
    return TaxConfig(
      enabled: business.taxEnabled ?? false,
      name: (name == null || name.isEmpty) ? 'VAT' : name,
      rate: double.tryParse(business.taxRate ?? '') ?? 0,
      inclusive: business.taxInclusive ?? false,
    );
  }

  /// Tax applies only when enabled with a positive rate.
  bool get isActive => enabled && rate > 0;

  String get rateLabel => formatTaxRate(rate);

  @override
  List<Object?> get props => [enabled, name, rate, inclusive];
}

class TaxComputation {
  final double taxAmount;
  final double netAmount;

  const TaxComputation({required this.taxAmount, required this.netAmount});
}

/// Mirrors the backend's create_sale() math (docs/TAX_SUPPORT.md §2).
/// Preview only — the server's numbers are always authoritative.
class TaxCalculator {
  static TaxComputation compute({
    required double taxableAmount,
    required TaxConfig config,
  }) {
    if (!config.isActive) {
      return TaxComputation(taxAmount: 0, netAmount: _round2(taxableAmount));
    }
    final rate = config.rate / 100;
    if (config.inclusive) {
      final tax = _round2(taxableAmount - (taxableAmount / (1 + rate)));
      return TaxComputation(taxAmount: tax, netAmount: _round2(taxableAmount));
    }
    final tax = _round2(taxableAmount * rate);
    return TaxComputation(
      taxAmount: tax,
      netAmount: _round2(taxableAmount + tax),
    );
  }

  // Dart's round() is half-away-from-zero, which equals ROUND_HALF_UP for
  // the non-negative amounts we deal with. Caveat: because inputs are binary
  // doubles, results can drift ±0.01 from the server's Decimal ROUND_HALF_UP
  // at exact half-cent boundaries (e.g. 1.50 @ 15%: true product 0.225 →
  // server 0.23, but the double is 0.2249999... → preview 0.22). Acceptable:
  // this calculator is preview-only and the server is always authoritative.
  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
