import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

void main() {
  group('ReportsPlaceholderView', () {
    Widget wrap(Widget sliver) => MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(slivers: [sliver]),
      ),
    );

    testWidgets('renders reportsComingSoon text', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ReportsPlaceholderView()));

      expect(find.text('Reports & Statistics are coming soon.'), findsOneWidget);
    });

    testWidgets('renders chart icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ReportsPlaceholderView()));

      expect(find.byIcon(SolarIconsOutline.chartSquare), findsOneWidget);
    });
  });
}
