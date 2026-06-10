import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_table.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SaleHistoryItem makeItem({
  String receipt = 'RCP-001',
  String? customerName = 'Sara',
  double total = 250.0,
  SaleHistoryStatus status = SaleHistoryStatus.completed,
}) =>
    SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'c1',
      receiptNumber: receipt,
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: customerName,
      paymentMethod: 'cash',
      total: total,
      itemCount: 3,
      status: status,
      createdAt: DateTime(2026, 6, 10, 10, 0),
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  Widget wrap(Widget sliver) => MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(slivers: [sliver]),
        ),
      );

  testWidgets('DesktopSalesTable shows all 7 column headers', (tester) async {
    await tester.pumpWidget(wrap(
      DesktopSalesTable(items: const [], onTap: (_) {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('RECEIPT'), findsOneWidget);
    expect(find.text('CUSTOMER'), findsOneWidget);
    expect(find.text('ITEMS'), findsOneWidget);
    expect(find.text('PAYMENT'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
  });

  testWidgets('DesktopSalesTable row shows receipt, customer name, and calls onTap', (tester) async {
    SaleHistoryItem? tapped;
    final item = makeItem();

    await tester.pumpWidget(wrap(
      DesktopSalesTable(items: [item], onTap: (i) => tapped = i),
    ));
    await tester.pumpAndSettle();

    expect(find.text('RCP-001'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);

    await tester.tap(find.text('RCP-001'));
    expect(tapped, equals(item));
  });

  testWidgets('em-dash shown when customerName is null', (tester) async {
    await tester.pumpWidget(wrap(
      DesktopSalesTable(items: [makeItem(customerName: null)], onTap: (_) {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
  });
}
