import 'dart:developer' as developer;

import '../../domain/entities/dashboard_summary.dart';

/// Debug-only comparison of the local "today" summary against the REST
/// `dashboard-summary` (the reference implementation, BE_GAPS §11). Lines are
/// logged, never shown. Amounts are compared in whole cents.
class DashboardParity {
  const DashboardParity();

  static int _c(double v) => (v * 100).round();

  /// Human-readable differences; empty when they agree. When the local
  /// summary still holds unsynced rows ([DashboardSummary.includesLocalPendingSales])
  /// a difference is expected and is tagged instead of reported as an error.
  List<String> diff({
    required DashboardSummary local,
    required DashboardSummary remote,
  }) {
    final l = local.today;
    final r = remote.today;
    final out = <String>[];
    void cmp(String name, num a, num b, {bool cents = false}) {
      final x = cents ? _c(a.toDouble()) : a;
      final y = cents ? _c(b.toDouble()) : b;
      if (x != y) out.add('$name: local $a vs server $b');
    }

    cmp('salesCount', l.salesCount, r.salesCount);
    cmp(
      'grossSalesAmount',
      l.grossSalesAmount,
      r.grossSalesAmount,
      cents: true,
    );
    cmp('cashAmount', l.cashAmount, r.cashAmount, cents: true);
    cmp('bankakAmount', l.bankakAmount, r.bankakAmount, cents: true);
    cmp('refundAmount', l.refundAmount, r.refundAmount, cents: true);
    cmp('refundCount', l.refundCount, r.refundCount);
    if (out.isNotEmpty && local.includesLocalPendingSales) {
      return ['unsynced rows present (expected difference)', ...out];
    }
    return out;
  }

  /// Logs every difference under `DashboardParity`.
  void log(List<String> lines) {
    for (final line in lines) {
      developer.log(line, name: 'DashboardParity');
    }
  }
}
