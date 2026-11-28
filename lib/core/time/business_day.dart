/// Business-timezone calendar days for local reporting (dashboard "today",
/// sales-history date filters).
///
/// The BE reports a day as `[00:00, 24:00)` in `business.timezone`
/// (default `Africa/Khartoum`). The app has no tz database package, so only
/// zones with a FIXED UTC offset (no DST) are supported, from a small tested
/// table; any other zone falls back to [defaultZone]'s offset.
///
/// Sales store `occurred_at` as UTC ISO text, so a business day becomes a
/// UTC text range `[start, end)` and the query never depends on the device
/// timezone. Which day is "today" is the device clock converted to the
/// business timezone: a wrong device clock shifts "today", but the sale it
/// stamps (`occurred_at` = the same clock) lands in that same day, so the
/// dashboard and the sales list always agree with each other.
class BusinessDay {
  const BusinessDay._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const String defaultZone = 'Africa/Khartoum';

  /// Fixed offsets (minutes east of UTC) of the zones the app supports.
  /// Africa/Khartoum is UTC+2 (CAT) since 2017-11-01 and has no DST.
  static const Map<String, int> _offsetMinutes = {
    'Africa/Khartoum': 120,
    'Africa/Juba': 120,
    'Africa/Addis_Ababa': 180,
    'Africa/Nairobi': 180,
    'Asia/Riyadh': 180,
    'Asia/Dubai': 240,
    'UTC': 0,
    'Etc/UTC': 0,
  };

  /// Whether [zone] has an exact entry in the offset table.
  static bool isSupported(String zone) => _offsetMinutes.containsKey(zone);

  /// UTC offset of [zone]; unknown zones use [defaultZone]'s.
  static Duration offsetOf(String? zone) =>
      Duration(minutes: _offsetMinutes[zone] ?? _offsetMinutes[defaultZone]!);

  /// The business day containing the instant [instant].
  factory BusinessDay.of(DateTime instant, String? zone) {
    final local = instant.toUtc().add(offsetOf(zone));
    return BusinessDay._(local.year, local.month, local.day);
  }

  /// The business day for the calendar date of [date] (its y/m/d only).
  factory BusinessDay.fromDate(DateTime date) =>
      BusinessDay._(date.year, date.month, date.day);

  /// Parses `YYYY-MM-DD`.
  factory BusinessDay.parse(String iso) {
    final d = DateTime.parse(iso);
    return BusinessDay._(d.year, d.month, d.day);
  }

  BusinessDay addDays(int n) {
    final d = DateTime.utc(year, month, day + n);
    return BusinessDay._(d.year, d.month, d.day);
  }

  /// UTC instant of 00:00 of this day in [zone].
  DateTime startUtc(String? zone) =>
      DateTime.utc(year, month, day).subtract(offsetOf(zone));

  /// UTC instant of 24:00 of this day in [zone].
  DateTime endUtc(String? zone) => addDays(1).startUtc(zone);

  /// `[start, end)` bounds comparable with stored `occurred_at` text.
  ///
  /// Bounds are second-precision without a zone suffix
  /// (`2026-11-15T22:00:00`): every stored value inside the second (with
  /// any fraction and the `Z`) sorts at or after its prefix, so `>= start`
  /// and `< end` are exact for `DateTime.toIso8601String()` UTC text.
  ({String start, String end}) utcTextRange(String? zone) =>
      (start: utcText(startUtc(zone)), end: utcText(endUtc(zone)));

  static String utcText(DateTime utc) {
    final s = utc.toUtc().toIso8601String();
    return s.substring(0, 19);
  }

  /// The ONE place a user-picked calendar day becomes a REST `date_from` /
  /// `date_to` value. The backend reads these as UTC calendar days (it does
  /// not convert to the business time zone), so the picked y/m/d is sent
  /// as-is. Limitation: a local day that straddles two UTC days cannot be
  /// expressed (zones east of UTC lose their first hours, zones west gain
  /// extra ones). See docs/date-ranges.md; the fix is backend ISO-datetime
  /// bounds. Local (SQLite) queries use [utcTextRange] and are exact.
  static String restDateParam(DateTime pickedDay) =>
      BusinessDay.fromDate(pickedDay).iso;

  /// `YYYY-MM-DD`.
  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}'
      '-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is BusinessDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
