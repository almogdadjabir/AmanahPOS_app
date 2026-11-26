import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';

import 'sale.dart';

/// Where the typed amounts stand against the sale total.
enum SplitStatus { incomplete, exact, over, invalid }

/// What the split sheet shows for the current inputs (cash, Bankak and on-account rows).
class SplitEvaluation {
  const SplitEvaluation({
    required this.status,
    required this.left,
    required this.parts,
  });

  final SplitStatus status;

  /// What is still unpaid, or how much too much was entered. Never negative.
  final BigInt left;

  /// The parts to charge: only rows above zero, in cash, Bankak, account order.
  /// Empty unless [status] is [SplitStatus.exact].
  final List<SalePaymentPart> parts;
}

/// Pure maths of the split payment sheet (port of desktop
/// `SplitPaymentViewModel`). Money is exact cents, never a double.
abstract final class SplitPayment {
  /// An empty row is nothing paid that way; text that is not a number, or is
  /// negative, is invalid (null).
  static BigInt? _part(String text) {
    if (text.trim().isEmpty) return BigInt.zero;
    return Cents.parse(text, allowNegative: false);
  }

  static SplitEvaluation evaluate({
    required BigInt total,
    required String cash,
    required String bankak,
    String account = '',
  }) {
    final c = _part(cash);
    final b = _part(bankak);
    final a = _part(account);
    if (c == null || b == null || a == null) {
      return SplitEvaluation(
        status: SplitStatus.invalid,
        left: BigInt.zero,
        parts: const [],
      );
    }
    final entered = c + b + a;
    if (entered == total) {
      return SplitEvaluation(
        status: SplitStatus.exact,
        left: BigInt.zero,
        parts: [
          if (c > BigInt.zero)
            SalePaymentPart(method: 'cash', amount: Cents.format(c)),
          if (b > BigInt.zero)
            SalePaymentPart(method: 'bankak', amount: Cents.format(b)),
          if (a > BigInt.zero)
            SalePaymentPart(method: 'credit', amount: Cents.format(a)),
        ],
      );
    }
    final diff = total - entered;
    return SplitEvaluation(
      status: entered > total ? SplitStatus.over : SplitStatus.incomplete,
      left: diff.abs(),
      parts: const [],
    );
  }

  /// "Fill rest": the row's own amount plus what is left, as `0.00` text.
  /// Null when nothing is left to fill. [row] is `cash`, `bankak` or `credit`.
  static String? fillRest({
    required BigInt total,
    required String cash,
    required String bankak,
    String account = '',
    bool intoCash = false,
    String row = '',
  }) {
    final target = row.isNotEmpty ? row : (intoCash ? 'cash' : 'bankak');
    final c = _part(cash);
    final b = _part(bankak);
    final a = _part(account);
    if (c == null || b == null || a == null) return null;
    final left = total - c - b - a;
    if (left <= BigInt.zero) return null;
    final own = switch (target) {
      'cash' => c,
      'credit' => a,
      _ => b,
    };
    return Cents.format(own + left);
  }

  /// True when saved [parts] still add up to [total] to the cent (the cart can
  /// change after the split was confirmed).
  static bool matches(List<SalePaymentPart> parts, BigInt total) {
    var sum = BigInt.zero;
    for (final p in parts) {
      final v = Cents.parse(p.amount, allowNegative: false);
      if (v == null) return false;
      sum += v;
    }
    return sum == total;
  }
}
