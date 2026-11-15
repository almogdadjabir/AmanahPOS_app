import 'package:intl/intl.dart';

/// Whole-number amount with thousands separators, always Latin digits
/// (matches the rest of the app, including in Arabic).
String homeMoney(double value) {
  final whole = value.round().toString();
  return whole.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

/// Quantity without a trailing ".0".
String homeQty(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _latin(String s) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final i = arabicIndic.indexOf(c);
    b.write(i >= 0 ? '$i' : c);
  }
  return b.toString();
}

/// "Sun 15 Nov 2026" in the app language, Latin digits.
String homeDate(String isoDate, String locale) {
  final parsed = DateTime.tryParse(isoDate) ?? DateTime.now();
  return _latin(DateFormat('EEE d MMM yyyy', locale).format(parsed));
}
