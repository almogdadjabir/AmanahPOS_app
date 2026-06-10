import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesHistoryBloc extends MockBloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {}

class FakeSalesHistoryEvent extends Fake implements SalesHistoryEvent {}

SaleHistoryItem makeItem({
  double total = 100.0,
  SaleHistoryStatus status = SaleHistoryStatus.completed,
  bool isOfflinePending = false,
}) =>
    SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'c1',
      receiptNumber: 'R1',
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: null,
      paymentMethod: 'cash',
      total: total,
      itemCount: 1,
      status: status,
      createdAt: DateTime(2026, 6, 10),
      isOfflinePending: isOfflinePending,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(FakeSalesHistoryEvent()));

  testWidgets('DesktopSalesStatsRow renders 4 KPI cards with correct values', (tester) async {
    final bloc = MockSalesHistoryBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial().copyWith(
      status: SalesHistoryBlocStatus.loaded,
      items: [
        makeItem(total: 200.0),
        makeItem(total: 300.0),
        makeItem(total: 100.0, status: SaleHistoryStatus.refunded),
      ],
    ));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SalesHistoryBloc>.value(
          value: bloc,
          child: DesktopSalesStatsRow(
            activeFilter: SaleFilter.all,
            applyFilter: (items) => items,
          ),
        ),
      ),
    ));

    // Sales count = 3
    expect(find.text('3'), findsOneWidget);
    // Revenue = 600
    expect(find.text('600 SDG'), findsOneWidget);
    // Avg = 200 (600 / 3)
    expect(find.text('200 SDG'), findsOneWidget);
    // Refund count = 1
    expect(find.textContaining('1 ·'), findsOneWidget);
  });
}
