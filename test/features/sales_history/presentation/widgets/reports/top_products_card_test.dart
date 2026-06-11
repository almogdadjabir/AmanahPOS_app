import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_products_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 220, child: w)),
  );

  testWidgets('renders product names and title', (tester) async {
    final products = [
      const SalesTopProduct(productId: 'p1', name: 'ببسي', quantitySold: 100, grossAmount: 500),
      const SalesTopProduct(productId: 'p2', name: 'ماء', quantitySold: 50, grossAmount: 250),
    ];
    await tester.pumpWidget(wrap(TopProductsCard(products: products)));
    await tester.pumpAndSettle();
    expect(find.text('Top Products'), findsOneWidget);
    expect(find.text('ببسي'), findsOneWidget);
    expect(find.text('ماء'), findsOneWidget);
  });

  testWidgets('shows empty message when no products', (tester) async {
    await tester.pumpWidget(wrap(TopProductsCard(products: const [])));
    await tester.pumpAndSettle();
    expect(find.text('No sales in this period.'), findsOneWidget);
  });
}
