import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_status_views.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget sliver) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: CustomScrollView(slivers: [sliver])),
  );

  testWidgets('ReportsLoadingSkeleton renders without error', (tester) async {
    await tester.pumpWidget(wrap(const ReportsLoadingSkeleton()));
    await tester.pump(); // don't pumpAndSettle — no animations
    expect(find.byType(ReportsLoadingSkeleton), findsOneWidget);
  });

  testWidgets('ReportsEmptyView shows no-sales message', (tester) async {
    await tester.pumpWidget(wrap(const ReportsEmptyView()));
    await tester.pumpAndSettle();
    expect(find.text('No sales in this period.'), findsOneWidget);
  });

  testWidgets('ReportsErrorView shows error message and retry button', (tester) async {
    bool retried = false;
    await tester.pumpWidget(wrap(
      ReportsErrorView(
        message: 'Failed to load report.',
        onRetry: () => retried = true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load report.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, true);
  });
}
