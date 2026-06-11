import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart';
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

  testWidgets('renders PieChart and title with payment methods', (tester) async {
    final methods = [
      const PaymentMethodBreakdown(method: 'cash', amount: 1000, count: 3),
      const PaymentMethodBreakdown(method: 'card', amount: 500, count: 2),
    ];
    await tester.pumpWidget(wrap(PaymentBreakdownCard(paymentMethods: methods)));
    await tester.pumpAndSettle();

    expect(find.text('Payment Methods'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
  });

  testWidgets('shows empty message when no payment methods', (tester) async {
    await tester.pumpWidget(wrap(PaymentBreakdownCard(paymentMethods: const [])));
    await tester.pumpAndSettle();

    expect(find.byType(PieChart), findsNothing);
    expect(find.text('No sales in this period.'), findsOneWidget);
  });
}
