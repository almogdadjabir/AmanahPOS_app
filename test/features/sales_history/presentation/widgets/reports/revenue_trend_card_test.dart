import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SalesTrend _makeTrend() => SalesTrend(
  interval: 'day',
  points: [
    const SalesTrendPoint(label: '2026-06-01', grossAmount: 0, netAmount: 0, salesCount: 0),
    const SalesTrendPoint(label: '2026-06-02', grossAmount: 16140, netAmount: 16140, salesCount: 5),
  ],
);

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 600, height: 360, child: w)),
  );

  testWidgets('renders title and LineChart', (tester) async {
    await tester.pumpWidget(wrap(RevenueTrendCard(trend: _makeTrend())));
    await tester.pumpAndSettle();

    expect(find.text('Revenue & Sales Trend'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('shows empty message when trend has no points', (tester) async {
    await tester.pumpWidget(wrap(RevenueTrendCard(
      trend: const SalesTrend(interval: 'day', points: []),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('No sales in this period.'), findsOneWidget);
  });
}
