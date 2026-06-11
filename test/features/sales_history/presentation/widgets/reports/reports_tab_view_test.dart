import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_status_views.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_tab_view.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesReportBloc extends MockBloc<SalesReportEvent, SalesReportState>
    implements SalesReportBloc {}

SalesReport _fakeReport() => SalesReport(
  rangeFrom: '2026-06-10',
  rangeTo: '2026-06-10',
  currency: 'SDG',
  summary: const SalesReportSummary(
    grossSalesAmount: 500,
    netSalesAmount: 500,
    salesCount: 2,
    averageSaleAmount: 250,
    refundAmount: 0,
    refundCount: 0,
  ),
  trend: const SalesTrend(interval: 'hour', points: []),
  paymentMethods: const [],
  topProducts: const [],
  topCategories: const [],
  peakHours: List.generate(24, (h) => PeakHourStat(hour: h, salesCount: 0, amount: 0)),
  dayOfWeek: List.generate(7, (d) => DayOfWeekStat(weekday: d + 1, salesCount: 0, amount: 0)),
);

void main() {
  late MockSalesReportBloc bloc;

  setUpAll(() => registerFallbackValue(const SalesReportRangeChanged(preset: ReportPreset.today)));

  setUp(() => bloc = MockSalesReportBloc());
  tearDown(() => bloc.close());

  Widget wrap(Widget sliver) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<SalesReportBloc>.value(
        value: bloc,
        child: CustomScrollView(slivers: [sliver]),
      ),
    ),
  );

  testWidgets('shows ReportsLoadingSkeleton when loading', (tester) async {
    when(() => bloc.state).thenReturn(
      const SalesReportState(status: SalesReportBlocStatus.loading),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pump();
    expect(find.byType(ReportsLoadingSkeleton), findsOneWidget);
  });

  testWidgets('shows ReportsErrorView when failure', (tester) async {
    when(() => bloc.state).thenReturn(
      const SalesReportState(
        status: SalesReportBlocStatus.failure,
        errorMessage: 'Network error',
      ),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsErrorView), findsOneWidget);
  });

  testWidgets('shows ReportsEmptyView when report is empty', (tester) async {
    final emptyReport = SalesReport(
      rangeFrom: '2026-06-10',
      rangeTo: '2026-06-10',
      currency: 'SDG',
      summary: const SalesReportSummary(
        grossSalesAmount: 0, netSalesAmount: 0, salesCount: 0,
        averageSaleAmount: 0, refundAmount: 0, refundCount: 0,
      ),
      trend: const SalesTrend(interval: 'hour', points: []),
      paymentMethods: const [],
      topProducts: const [],
      topCategories: const [],
      peakHours: const [],
      dayOfWeek: const [],
    );
    when(() => bloc.state).thenReturn(
      SalesReportState(status: SalesReportBlocStatus.loaded, report: emptyReport),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsEmptyView), findsOneWidget);
  });

  testWidgets('shows DateRangeBar when loaded with data', (tester) async {
    when(() => bloc.state).thenReturn(
      SalesReportState(status: SalesReportBlocStatus.loaded, report: _fakeReport()),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget); // DateRangeBar
  });
}
