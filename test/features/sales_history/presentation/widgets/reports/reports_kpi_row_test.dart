import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SalesReportSummary _makeSummary({double totalTaxCollected = 0}) => SalesReportSummary(
  grossSalesAmount: 16140.0,
  netSalesAmount: 16140.0,
  salesCount: 5,
  averageSaleAmount: 3228.0,
  refundAmount: 210.0,
  refundCount: 1,
  totalTaxCollected: totalTaxCollected,
);

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: w),
  );

  testWidgets('renders KPI row without tax card when totalTaxCollected is 0', (tester) async {
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: _makeSummary())));
    await tester.pumpAndSettle();
    // Revenue label — SaleStatCard uppercases labels in en locale
    expect(find.text('REVENUE'), findsOneWidget);
    // revenue value contains the amount
    expect(find.textContaining('16,140'), findsWidgets);
    // Tax card should not be rendered when totalTaxCollected is 0
    expect(find.text('TAX COLLECTED'), findsNothing);
  });

  testWidgets('renders sales count card', (tester) async {
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: _makeSummary())));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('renders refund card with count and amount when refundCount > 0', (tester) async {
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: _makeSummary())));
    await tester.pumpAndSettle();
    // Should show "1 · 210 SDG"
    expect(find.textContaining('1 ·'), findsOneWidget);
  });

  testWidgets('renders refund card with just amount when refundCount == 0', (tester) async {
    const noRefunds = SalesReportSummary(
      grossSalesAmount: 5000.0,
      netSalesAmount: 5000.0,
      salesCount: 2,
      averageSaleAmount: 2500.0,
      refundAmount: 0.0,
      refundCount: 0,
    );
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: noRefunds)));
    await tester.pumpAndSettle();
    // Should show "0 SDG" without a count prefix
    expect(find.text('0 SDG'), findsOneWidget);
    expect(find.textContaining('0 ·'), findsNothing);
  });

  testWidgets('renders tax collected card when totalTaxCollected > 0', (tester) async {
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: _makeSummary(totalTaxCollected: 500))));
    await tester.pumpAndSettle();
    // Tax card should be rendered with uppercased label in en locale
    expect(find.text('TAX COLLECTED'), findsOneWidget);
    // Tax card value should contain the formatted amount
    expect(find.textContaining('500'), findsWidgets);
  });
}
