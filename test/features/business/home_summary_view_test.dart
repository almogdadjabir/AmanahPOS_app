import 'package:amana_pos/features/business/presentation/widgets/workspace/single_business_workspace.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final empty = DashboardSummary.empty(date: '2026-11-16');
  final withSales = empty.copyWith(
    today: empty.today.copyWith(salesCount: 1, grossSalesAmount: 5),
  );

  HomeSummaryView of(DashboardSummaryStatus status, DashboardSummary? s) =>
      homeSummaryViewOf(DashboardSummaryState(status: status, summary: s));

  test('cold start before the first local value: no "no sales" flash', () {
    expect(
      of(DashboardSummaryStatus.initial, null),
      HomeSummaryView.awaitingFirstValue,
    );
  });

  test('legacy REST load without data shows the skeleton', () {
    expect(of(DashboardSummaryStatus.loading, null), HomeSummaryView.skeleton);
  });

  test('a real empty day (or a failure) shows the empty state', () {
    expect(of(DashboardSummaryStatus.success, empty), HomeSummaryView.empty);
    expect(of(DashboardSummaryStatus.failure, null), HomeSummaryView.empty);
  });

  test('data shows the cards', () {
    expect(of(DashboardSummaryStatus.success, withSales), HomeSummaryView.data);
    expect(
      of(DashboardSummaryStatus.refreshing, withSales),
      HomeSummaryView.data,
    );
  });
}
