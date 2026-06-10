import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(WidgetBuilder builder) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: builder),
      );

  testWidgets('SaleFilterX.salesCountLabel returns correct key per filter', (tester) async {
    late AppLocalizations tr;
    await tester.pumpWidget(_wrap((ctx) {
      tr = AppLocalizations.of(ctx)!;
      return const SizedBox();
    }));

    expect(SaleFilter.all.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.allLoadedSales));
    expect(SaleFilter.today.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.todaysSalesCount));
    expect(SaleFilter.completed.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.completedSalesCount));
    expect(SaleFilter.refunded.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.returnedSalesCount));
    expect(SaleFilter.pending.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.pendingSalesCount));
  });

  testWidgets('SaleFilterX.revenueLabel returns correct key per filter', (tester) async {
    late AppLocalizations tr;
    await tester.pumpWidget(_wrap((ctx) {
      tr = AppLocalizations.of(ctx)!;
      return const SizedBox();
    }));

    expect(SaleFilter.all.revenueLabel(tester.element(find.byType(SizedBox))),
        equals(tr.allLoadedRevenue));
    expect(SaleFilter.today.revenueLabel(tester.element(find.byType(SizedBox))),
        equals(tr.todaysRevenue));
  });
}
