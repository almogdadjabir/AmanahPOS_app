import 'package:amana_pos/features/dashboard/data/local/dashboard_parity.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardSummary _s({
  double gross = 100,
  int count = 2,
  bool pending = false,
}) => DashboardSummary(
  serverTime: null,
  timezone: 'UTC',
  currency: 'SDG',
  scope: const DashboardScope(),
  today: TodaySalesSummary(
    date: '2026-11-17',
    grossSalesAmount: gross,
    netSalesAmount: gross,
    salesCount: count,
    averageSaleAmount: 0,
    refundAmount: 0,
    refundCount: 0,
    cashAmount: gross,
    bankakAmount: 0,
    otherAmount: 0,
    paymentBreakdown: const [],
    refundCashAmount: 0,
    refundBankakAmount: 0,
    customAmount: 0,
    customCount: 0,
  ),
  shift: null,
  sparkline: const SparklineSummary(interval: 'hour', points: []),
  topSellers: const [],
  sync: const DashboardSyncInfo(
    includesPendingOfflineSales: false,
    lastCalculatedAt: null,
  ),
  includesLocalPendingSales: pending,
);

void main() {
  const p = DashboardParity();

  test('identical summaries -> no lines', () {
    expect(p.diff(local: _s(), remote: _s()), isEmpty);
  });

  test('1 cent off -> one line naming grossSalesAmount (and cash)', () {
    final lines = p.diff(local: _s(gross: 100.01), remote: _s());
    expect(lines.any((l) => l.startsWith('grossSalesAmount')), isTrue);
  });

  test('unsynced rows tag the difference', () {
    final lines = p.diff(local: _s(count: 3, pending: true), remote: _s());
    expect(lines.first, contains('unsynced rows present'));
    expect(lines.any((l) => l.startsWith('salesCount')), isTrue);
  });
}
