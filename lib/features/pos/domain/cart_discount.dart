import '../../shifts/domain/cash_expectation.dart';

enum DiscountKind { percent, amount }

/// Why a typed discount is not accepted.
enum DiscountProblem { notANumber, zero, overBase }

/// A discount typed by the cashier: a percent (0.01 to 100) or an amount. It
/// is kept as typed and turned into cents against the current base, so a
/// percent follows quantity changes and an amount is cut to the base. All
/// exact (cents as [BigInt]); half a cent rounds up.
class CartDiscount {
  const CartDiscount.percent(this.value) : kind = DiscountKind.percent;
  const CartDiscount.amount(this.value) : kind = DiscountKind.amount;

  final DiscountKind kind;

  /// What was typed, normalised: `10`, `7.5`, `2.00`.
  final String value;

  /// Cents taken off [base] (never negative, never above [base]).
  BigInt cutOf(BigInt base) {
    if (base <= BigInt.zero) return BigInt.zero;
    final v = Cents.parse(value, allowNegative: false);
    if (v == null || v <= BigInt.zero) return BigInt.zero;
    final BigInt cut = switch (kind) {
      // v is the percent in hundredths (7.5 -> 750).
      DiscountKind.percent =>
        (base * v + BigInt.from(5000)) ~/ BigInt.from(10000),
      DiscountKind.amount => v,
    };
    return cut > base ? base : cut;
  }

  /// Null when [raw] is a usable discount on [base].
  static DiscountProblem? check(DiscountKind kind, String raw, BigInt base) {
    final v = Cents.parse(raw, allowNegative: false);
    if (v == null) return DiscountProblem.notANumber;
    if (v <= BigInt.zero) return DiscountProblem.zero;
    final tooBig = kind == DiscountKind.percent
        ? v > BigInt.from(10000)
        : v > base;
    return tooBig ? DiscountProblem.overBase : null;
  }

  @override
  bool operator ==(Object other) =>
      other is CartDiscount && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => '${kind.name}:$value';
}
