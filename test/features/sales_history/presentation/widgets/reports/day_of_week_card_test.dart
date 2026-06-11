import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/day_of_week_card.dart';
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

  testWidgets('renders BarChart with day-of-week title', (tester) async {
    final days = List.generate(7, (d) => DayOfWeekStat(
      weekday: d + 1,
      salesCount: d == 1 ? 3 : 0,
      amount: d == 1 ? 300.0 : 0.0,
    ));
    await tester.pumpWidget(wrap(DayOfWeekCard(dayOfWeek: days)));
    await tester.pumpAndSettle();
    expect(find.text('Day of Week'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
