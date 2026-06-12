import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

Widget wrap(Widget w) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: w),
    );

void main() {
  testWidgets('renders search field with hint text', (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(wrap(
      DesktopSalesHistoryTopBar(
        activeView: SalesView.transactions,
        onViewChanged: (_) {},
        searchController: ctrl,
        onRefresh: () {},
        returnsActive: false,
        onReturnsTap: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Search by receipt or customer'), findsOneWidget);
  });

  testWidgets('calls onViewChanged when Reports & Statistics tab tapped',
      (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    SalesView? received;

    await tester.pumpWidget(wrap(
      DesktopSalesHistoryTopBar(
        activeView: SalesView.transactions,
        onViewChanged: (v) => received = v,
        searchController: ctrl,
        onRefresh: () {},
        returnsActive: false,
        onReturnsTap: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Reports'));
    expect(received, equals(SalesView.reports));
  });

  testWidgets('calls onRefresh when refresh button tapped', (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    var called = false;

    await tester.pumpWidget(wrap(
      DesktopSalesHistoryTopBar(
        activeView: SalesView.transactions,
        onViewChanged: (_) {},
        searchController: ctrl,
        onRefresh: () => called = true,
        returnsActive: false,
        onReturnsTap: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(SolarIconsOutline.refresh));
    expect(called, isTrue);
  });
}
