/// Money as whole cents (two decimals), exact. Shifts never use doubles.
abstract final class Cents {
  static final _re = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?$');

  /// Parses a plain amount like `250`, `12.5` or `-3.05`. Null when it is not
  /// a number. A third decimal is rounded half up.
  static BigInt? parse(String raw, {bool allowNegative = true}) {
    final m = _re.firstMatch(raw.trim());
    if (m == null) return null;
    final whole = m.group(2)!;
    final frac = m.group(3) ?? '';
    if (whole.isEmpty && frac.isEmpty) return null;
    final f = frac.padRight(3, '0');
    var cents = BigInt.parse('${whole.isEmpty ? '0' : whole}${f.substring(0, 2)}');
    if (int.parse(f[2]) >= 5) cents += BigInt.one;
    if (m.group(1) == '-') {
      if (!allowNegative) return null;
      cents = -cents;
    }
    return cents;
  }

  /// `1250` -> `12.50`.
  static String format(BigInt cents) {
    final neg = cents.isNegative && cents != BigInt.zero;
    final a = cents.abs();
    final frac = (a % BigInt.from(100)).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}${a ~/ BigInt.from(100)}.$frac';
  }
}

/// The cash parts of one shift. Every part is a positive amount; the sign
/// comes from what it is (port of desktop `CashParts`).
class CashParts {
  const CashParts({
    required this.opening,
    required this.cashSales,
    required this.debtPayments,
    required this.payIns,
    required this.refunds,
    required this.cancels,
    required this.payOuts,
  });

  factory CashParts.openingOnly(BigInt opening) => CashParts(
    opening: opening,
    cashSales: BigInt.zero,
    debtPayments: BigInt.zero,
    payIns: BigInt.zero,
    refunds: BigInt.zero,
    cancels: BigInt.zero,
    payOuts: BigInt.zero,
  );

  final BigInt opening;
  final BigInt cashSales;
  final BigInt debtPayments;
  final BigInt payIns;
  final BigInt refunds;
  final BigInt cancels;
  final BigInt payOuts;
}

/// Expected drawer cash and the count difference. Pure money maths.
abstract final class CashExpectation {
  static BigInt expected(CashParts p) =>
      p.opening + p.cashSales + p.debtPayments + p.payIns -
      p.refunds - p.cancels - p.payOuts;

  /// Counted minus expected: negative means cash is missing.
  static BigInt difference(BigInt counted, BigInt expected) =>
      counted - expected;

  /// A pay-out larger than the cash the drawer should hold is allowed but
  /// flagged.
  static bool payOutExceeds(BigInt expectedNow, BigInt amount) =>
      amount > expectedNow;
}
