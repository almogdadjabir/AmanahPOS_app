import 'package:intl/intl.dart';

class AppFormat {
  AppFormat._();

  static const String currency = 'SDG';

  static final NumberFormat _money =
  NumberFormat.decimalPattern('en_US')..maximumFractionDigits = 0;

  /// Returns "2,200" — pair with [currency] in the UI.
  static String money(num value) => _money.format(value);

  /// Returns "2,200 SDG" (use sparingly; UI usually splits amount and unit).
  static String moneyWithUnit(num value) => '${_money.format(value)} $currency';

  /// "ABC" → "AB" — used as image placeholder fallback.
  static String initials(String text, {int max = 2}) {
    final parts = text.trim().split(RegExp(r'\s+'));
    final letters = parts.map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.substring(0, letters.length < max ? letters.length : max).toUpperCase();
  }
}
