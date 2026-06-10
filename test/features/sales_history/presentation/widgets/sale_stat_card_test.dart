import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('SaleStatCard renders label and value', (tester) async {
    await tester.pumpWidget(wrap(const SaleStatCard(
      label: 'Sales',
      value: '42',
      background: Color(0xFFCCFBF1),
      valueColor: Color(0xFF115E59),
      labelColor: Color(0xFF0F766E),
      icon: SolarIconsOutline.billList,
    )));

    expect(find.text('SALES'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('SaleStatCard wraps value in Directionality when forceValueLtr', (tester) async {
    await tester.pumpWidget(wrap(const SaleStatCard(
      label: 'Revenue',
      value: '500 SDG',
      background: Color(0xFFCCFBF1),
      valueColor: Color(0xFF115E59),
      labelColor: Color(0xFF0F766E),
      icon: SolarIconsOutline.walletMoney,
      forceValueLtr: true,
    )));

    expect(find.byType(Directionality), findsWidgets);
  });
}
