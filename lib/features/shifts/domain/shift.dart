import 'cash_expectation.dart';

enum ShiftOrigin {
  auto,
  manual;

  static ShiftOrigin parse(Object? v) =>
      v == 'auto' ? ShiftOrigin.auto : ShiftOrigin.manual;
}

enum ShiftState { open, needsCount, counted }

/// One shift. [expected] is frozen when the shift closes; [counted] is
/// entered at or after the close. Money is cents, exact.
class ShiftInfo {
  const ShiftInfo({
    required this.id,
    required this.shopId,
    required this.openedAt,
    required this.openedByName,
    required this.origin,
    required this.openingCash,
    this.closedAt,
    this.closedByName,
    this.counted,
    this.expected,
    this.note,
    this.syncState = 'pending',
  });

  final String id;
  final String shopId;
  final DateTime openedAt;
  final String? openedByName;
  final ShiftOrigin origin;
  final BigInt openingCash;
  final DateTime? closedAt;
  final String? closedByName;
  final BigInt? counted;
  final BigInt? expected;
  final String? note;
  final String syncState;

  ShiftState get state => closedAt == null
      ? ShiftState.open
      : counted == null
      ? ShiftState.needsCount
      : ShiftState.counted;

  bool get isOpen => closedAt == null;

  /// Counted minus expected, once both exist.
  BigInt? get difference => counted != null && expected != null
      ? CashExpectation.difference(counted!, expected!)
      : null;
}

enum CashMovementKind { payIn, payOut }

/// A pay-in or pay-out inside a shift.
class CashMovementInfo {
  const CashMovementInfo({
    required this.id,
    required this.shiftId,
    required this.kind,
    required this.amount,
    required this.reason,
    required this.userName,
    required this.at,
  });

  final String id;
  final String shiftId;
  final CashMovementKind kind;
  final BigInt amount;
  final String reason;
  final String? userName;
  final DateTime at;
}

/// Takings of a method other than cash (information, not part of the drawer).
class OtherTaking {
  const OtherTaking(this.method, this.amount);
  final String method;
  final BigInt amount;
}

/// The cash parts of a shift and the other takings, worked out from its time
/// range.
class ShiftFigures {
  const ShiftFigures({
    required this.parts,
    this.other = const [],
    this.salesCount = 0,
    this.salesTotal,
  });

  final CashParts parts;
  final List<OtherTaking> other;

  /// Number and total of the shift's non-cancelled sales (all methods).
  final int salesCount;
  final BigInt? salesTotal;

  BigInt get expected => CashExpectation.expected(parts);
}
