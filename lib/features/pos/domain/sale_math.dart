import 'tax_config.dart';

/// Exact decimal value: [units] / 10^[scale]. Never a double.
class ExactDecimal {
  const ExactDecimal(this.units, this.scale);

  final BigInt units;
  final int scale;

  static final RegExp _re = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?$');

  static ExactDecimal parse(String raw) {
    final m = _re.firstMatch(raw.trim());
    if (m == null) throw FormatException('Bad decimal: $raw');
    final whole = m.group(2)!;
    final frac = m.group(3) ?? '';
    if (whole.isEmpty && frac.isEmpty) {
      throw FormatException('Bad decimal: $raw');
    }
    var units = BigInt.parse('${whole.isEmpty ? '0' : whole}$frac');
    if (m.group(1) == '-') units = -units;
    return ExactDecimal(units, frac.length);
  }

  static ExactDecimal get zero => ExactDecimal(BigInt.zero, 0);

  ExactDecimal _rescale(int s) =>
      ExactDecimal(units * BigInt.from(10).pow(s - scale), s);

  ExactDecimal operator +(ExactDecimal o) {
    final s = scale > o.scale ? scale : o.scale;
    return ExactDecimal(_rescale(s).units + o._rescale(s).units, s);
  }

  ExactDecimal operator -(ExactDecimal o) {
    final s = scale > o.scale ? scale : o.scale;
    return ExactDecimal(_rescale(s).units - o._rescale(s).units, s);
  }

  ExactDecimal operator *(ExactDecimal o) =>
      ExactDecimal(units * o.units, scale + o.scale);

  bool get isNegative => units.isNegative;

  /// Rounds to [s] decimals, half away from zero (Python ROUND_HALF_UP).
  BigInt roundTo(int s) {
    if (s >= scale) return units * BigInt.from(10).pow(s - scale);
    return divRoundHalfUp(units, BigInt.from(10).pow(scale - s));
  }

  /// `"12.50"` style fixed string with [s] decimals.
  String toFixed(int s) => formatUnits(roundTo(s), s);

  /// round(num / den), half away from zero. [den] must be positive.
  static BigInt divRoundHalfUp(BigInt num, BigInt den) {
    final neg = num.isNegative;
    final a = num.abs();
    var q = a ~/ den;
    if ((a % den) * BigInt.two >= den) q += BigInt.one;
    return neg ? -q : q;
  }

  static String formatUnits(BigInt units, int s) {
    final neg = units.isNegative && units != BigInt.zero;
    final a = units.abs();
    if (s == 0) return '${neg ? '-' : ''}$a';
    final p = BigInt.from(10).pow(s);
    final frac = (a % p).toString().padLeft(s, '0');
    return '${neg ? '-' : ''}${a ~/ p}.$frac';
  }
}

class SaleMathLine {
  const SaleMathLine({
    required this.quantity,
    required this.unitPrice,
    this.discount = '0',
  });

  final String quantity;
  final String unitPrice;
  final String discount;
}

class SaleTotals {
  const SaleTotals({
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    required this.netAmount,
    required this.lineTotals,
  });

  /// Σ line totals, 2 decimals.
  final String subtotal;
  final String discount;
  final String taxAmount;

  /// What the customer owes; payments must add up to it.
  final String netAmount;

  /// Per line: unit_price * quantity - discount, 2 decimals.
  final List<String> lineTotals;
}

/// Exact sale arithmetic mirroring the BE `apps/sales/services.py`
/// `create_sale` so the local net equals the server net:
///
///  * line subtotal = unit_price * quantity - discount (exact);
///  * taxable = Σ line subtotals - sale discount (exact);
///  * rate > 0, exclusive: tax = taxable * rate/100, net = taxable + tax,
///    both quantized to 0.01 ROUND_HALF_UP from the exact values;
///  * rate > 0, inclusive: tax = taxable - taxable/(1 + rate/100), net =
///    taxable, quantized the same way (computed as an exact rational);
///  * rate == 0: tax 0, net = taxable (the BE keeps it unquantized; locally
///    it is rounded half up to cents, within the BE's ±0.01 payments check).
class SaleMath {
  const SaleMath._();

  static final BigInt _hundred = BigInt.from(100);

  static SaleTotals compute({
    required List<SaleMathLine> lines,
    required String discount,
    required String taxRate,
    required bool taxInclusive,
  }) {
    var total = ExactDecimal.zero;
    final lineTotals = <String>[];
    for (final l in lines) {
      final sub =
          ExactDecimal.parse(l.unitPrice) * ExactDecimal.parse(l.quantity) -
          ExactDecimal.parse(l.discount);
      total = total + sub;
      lineTotals.add(sub.toFixed(2));
    }
    final disc = ExactDecimal.parse(discount);
    final taxable = total - disc;
    final rate = ExactDecimal.parse(taxRate);

    String tax;
    String net;
    if (rate.units > BigInt.zero) {
      // taxable = T / 10^a ; rate% = R / 10^b
      final t = taxable.units;
      final ta = BigInt.from(10).pow(taxable.scale);
      final r = rate.units;
      final rb = BigInt.from(10).pow(rate.scale);
      if (taxInclusive) {
        // tax = taxable * rate / (100 + rate)
        //     = T*R / (10^a * (100*10^b + R)); in cents: * 100.
        final cents = ExactDecimal.divRoundHalfUp(
          t * r * _hundred,
          ta * (_hundred * rb + r),
        );
        tax = ExactDecimal.formatUnits(cents, 2);
        net = taxable.toFixed(2);
      } else {
        // tax = T*R / (10^a * 100 * 10^b); net = taxable + tax (exact).
        final den = ta * _hundred * rb;
        tax = ExactDecimal.formatUnits(
          ExactDecimal.divRoundHalfUp(t * r * _hundred, den),
          2,
        );
        net = ExactDecimal.formatUnits(
          ExactDecimal.divRoundHalfUp(
            (t * _hundred * rb + t * r) * _hundred,
            den,
          ),
          2,
        );
      }
    } else {
      tax = '0.00';
      net = taxable.toFixed(2);
    }

    return SaleTotals(
      subtotal: total.toFixed(2),
      discount: disc.toFixed(2),
      taxAmount: tax,
      netAmount: net,
      lineTotals: lineTotals,
    );
  }

  /// The rate sent as the sale's tax snapshot. The BE applies tax whenever
  /// the snapshot rate is > 0 (it has no `enabled` flag), so an inactive
  /// config must send `'0'`. Two decimals (BE `tax_rate` is 5,2), trimmed.
  static String taxRateOf(TaxConfig c) {
    if (!c.isActive) return '0';
    final fixed = c.rate.toStringAsFixed(2);
    return _trim(fixed);
  }

  static String _trim(String fixed) {
    if (!fixed.contains('.')) return fixed;
    var s = fixed.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// Normalises a money string to 2 decimals (half away from zero). Throws
  /// [FormatException] for anything that is not a plain decimal.
  static String money(String raw) => ExactDecimal.parse(raw).toFixed(2);

  /// BE rule: |Σ parts - net| <= 0.01.
  static bool paymentsMatch(List<String> amounts, String net) {
    var paid = ExactDecimal.zero;
    for (final a in amounts) {
      paid = paid + ExactDecimal.parse(a);
    }
    final diff = (paid - ExactDecimal.parse(net)).units.abs();
    final s = (paid - ExactDecimal.parse(net)).scale;
    // diff / 10^s <= 0.01  <=>  diff * 100 <= 10^s
    return diff * _hundred <= BigInt.from(10).pow(s);
  }
}
