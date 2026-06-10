import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stats_row.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesHistoryBloc
    extends MockBloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {}

class _FakeSalesHistoryEvent extends Fake implements SalesHistoryEvent {}

SaleHistoryItem _item({double total = 100.0, SaleHistoryStatus status = SaleHistoryStatus.completed}) =>
    SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'csid-1',
      receiptNumber: 'RCP-001',
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: 'Ahmed',
      paymentMethod: 'cash',
      total: total,
      itemCount: 2,
      status: status,
      createdAt: DateTime(2026, 6, 10, 14, 30),
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeSalesHistoryEvent()));

  testWidgets('SaleStatsRow shows count and revenue for SaleFilter.all', (tester) async {
    final bloc = _MockSalesHistoryBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial().copyWith(
      status: SalesHistoryBlocStatus.loaded,
      items: [_item(total: 100.0), _item(total: 200.0)],
    ));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SalesHistoryBloc>.value(
          value: bloc,
          child: SaleStatsRow(
            activeFilter: SaleFilter.all,
            applyFilter: (items) => items,
          ),
        ),
      ),
    ));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('300 SDG'), findsOneWidget);
  });
}
