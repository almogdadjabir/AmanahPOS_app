/// Exact decimal arithmetic for stock quantities: values are scaled integers
/// with 3 fractional digits ([BigInt] units of 0.001). Never accumulate
/// quantities with `double`.
class Decimal3 {
  const Decimal3._();

  static final BigInt _scale = BigInt.from(1000);

  static final RegExp _re = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?$');

  /// Parses a decimal string ("12", "-0.5", "1.250") into units of 0.001.
  /// Digits beyond the third fractional digit are rounded half away from
  /// zero. Throws [FormatException] for anything that is not a plain decimal.
  static BigInt parse(String raw) {
    final s = raw.trim();
    final m = _re.firstMatch(s);
    if (m == null) throw FormatException('Bad decimal: $raw');
    final whole = m.group(2)!;
    final frac = m.group(3) ?? '';
    if (whole.isEmpty && frac.isEmpty) {
      throw FormatException('Bad decimal: $raw');
    }
    final padded = frac.padRight(3, '0');
    var units =
        BigInt.parse(whole.isEmpty ? '0' : whole) * _scale +
        BigInt.parse(padded.substring(0, 3));
    if (padded.length > 3 && padded.codeUnitAt(3) >= 0x35) {
      units += BigInt.one;
    }
    return m.group(1) == '-' ? -units : units;
  }

  /// Like [parse] but returns null for null/invalid input.
  static BigInt? tryParse(Object? raw) {
    if (raw == null) return null;
    try {
      return parse(raw is num ? _numToString(raw) : raw.toString());
    } on FormatException {
      return null;
    }
  }

  static String _numToString(num n) {
    final s = n.toString();
    // Avoid exponent notation from very small/large doubles.
    return s.contains('e') || s.contains('E') ? n.toStringAsFixed(3) : s;
  }

  /// Formats [units] as a trimmed decimal string ("7", "0.3", "-1.25").
  static String format(BigInt units) {
    final neg = units.isNegative;
    final a = units.abs();
    final whole = a ~/ _scale;
    final frac = (a % _scale)
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    final body = frac.isEmpty ? '$whole' : '$whole.$frac';
    return neg && a != BigInt.zero ? '-$body' : body;
  }

  /// Display value for the legacy REAL columns. Only for display/legacy
  /// readers, never for accumulation.
  static double toDouble(BigInt units) => units.toDouble() / 1000.0;

  static BigInt add(BigInt a, BigInt b) => a + b;
  static BigInt sub(BigInt a, BigInt b) => a - b;
}
