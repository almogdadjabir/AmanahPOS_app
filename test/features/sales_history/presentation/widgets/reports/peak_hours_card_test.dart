import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/peak_hours_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 200, child: w)),
  );

  testWidgets('renders BarChart with peak hours title', (tester) async {
    final hours = List.generate(24, (h) => PeakHourStat(
      hour: h,
      salesCount: h == 14 ? 5 : 0,
      amount: h == 14 ? 500.0 : 0.0,
    ));
    await tester.pumpWidget(wrap(PeakHoursCard(peakHours: hours)));
    await tester.pumpAndSettle();
    expect(find.text('Peak Hours'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
