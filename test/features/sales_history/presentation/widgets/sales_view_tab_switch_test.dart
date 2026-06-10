import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({required SalesView active, required ValueChanged<SalesView> onChanged}) =>
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SalesViewTabSwitch(active: active, onChanged: onChanged),
        ),
      );

  testWidgets('renders both tab labels', (tester) async {
    await tester.pumpWidget(wrap(active: SalesView.transactions, onChanged: (_) {}));
    expect(find.textContaining('Transactions'), findsOneWidget);
    expect(find.textContaining('Reports'), findsOneWidget);
  });

  testWidgets('tapping Reports tab fires callback with SalesView.reports', (tester) async {
    SalesView? fired;
    await tester.pumpWidget(wrap(
      active: SalesView.transactions,
      onChanged: (v) => fired = v,
    ));
    await tester.tap(find.textContaining('Reports'));
    expect(fired, equals(SalesView.reports));
  });
}
