import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_categories_card.dart';
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

  testWidgets('renders category names and title', (tester) async {
    final cats = [
      const SalesTopCategory(categoryId: 'c1', name: 'مشروبات', quantitySold: 200, grossAmount: 750),
    ];
    await tester.pumpWidget(wrap(TopCategoriesCard(categories: cats)));
    await tester.pumpAndSettle();
    expect(find.text('Top Categories'), findsOneWidget);
    expect(find.text('مشروبات'), findsOneWidget);
  });
}
