import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';

final RegExp _arabic = RegExp(r'[؀-ۿ]');
final RegExp _latin = RegExp(r'[A-Za-z]');

bool _isArabic(String s) => s.isNotEmpty && _arabic.hasMatch(s[0]);

/// First character, upper-cased for Latin and with hamza forms of alef folded
/// to a plain alef for Arabic. Digits and symbols fall under "#".
String customerHeaderLetter(CustomerData c) {
  final name = (c.name ?? '').trim();
  if (name.isEmpty) return '#';
  final first = String.fromCharCode(name.runes.first);
  if (_arabic.hasMatch(first)) {
    return const {'إ': 'أ', 'آ': 'أ', 'ٱ': 'أ'}[first] ?? first;
  }
  if (_latin.hasMatch(first)) return first.toUpperCase();
  return '#';
}

/// Arabic: first letter. Latin: first letters of up to two words.
String customerInitials(CustomerData c) {
  final name = (c.name ?? '').trim();
  if (name.isEmpty) return '#';
  if (_isArabic(name)) return String.fromCharCode(name.runes.first);
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words
      .take(2)
      .map((w) => String.fromCharCode(w.runes.first).toUpperCase())
      .join();
}

/// Keeps a phone number left-to-right inside right-to-left text.
String ltrIsolate(String s) => '\u2066$s\u2069';

/// Digits only, for wa.me links.
String phoneDigits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

/// Groups consecutive customers that share a header letter.
List<MapEntry<String, List<CustomerData>>> groupCustomers(
  List<CustomerData> customers,
) {
  final groups = <MapEntry<String, List<CustomerData>>>[];
  for (final c in customers) {
    final letter = customerHeaderLetter(c);
    if (groups.isNotEmpty && groups.last.key == letter) {
      groups.last.value.add(c);
    } else {
      groups.add(MapEntry(letter, [c]));
    }
  }
  return groups;
}
