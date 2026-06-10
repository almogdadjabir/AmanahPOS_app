import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_table.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesHistoryBloc
    extends MockBloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {}

class FakeSalesHistoryEvent extends Fake implements SalesHistoryEvent {}

SaleHistoryItem _makeItem() => SaleHistoryItem(
      id: 'test-id',
      clientSaleId: 'client-1',
      receiptNumber: 'R001',
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: 'Test Customer',
      paymentMethod: 'cash',
      total: 150.0,
      itemCount: 2,
      status: SaleHistoryStatus.completed,
      createdAt: DateTime(2026, 6, 10),
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: [],
    );

Widget _wrap(Widget child, MockSalesHistoryBloc bloc) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<SalesHistoryBloc>.value(
        value: bloc,
        child: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(FakeSalesHistoryEvent()));

  group('DesktopSalesHistoryView', () {
    late MockSalesHistoryBloc bloc;

    setUp(() {
      bloc = MockSalesHistoryBloc();
    });

    tearDown(() => bloc.close());

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      when(() => bloc.state).thenReturn(
        SalesHistoryState.initial().copyWith(
          status: SalesHistoryBlocStatus.loading,
          items: [],
        ),
      );

      await tester.pumpWidget(_wrap(const DesktopSalesHistoryView(), bloc));
      // Use pump() instead of pumpAndSettle() — CircularProgressIndicator
      // never stops animating so pumpAndSettle would time out.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows DesktopSalesTable when items are loaded', (tester) async {
      when(() => bloc.state).thenReturn(
        SalesHistoryState.initial().copyWith(
          status: SalesHistoryBlocStatus.loaded,
          items: [_makeItem()],
        ),
      );

      await tester.pumpWidget(_wrap(const DesktopSalesHistoryView(), bloc));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopSalesTable), findsOneWidget);
    });

    testWidgets('shows ReportsPlaceholderView when Reports tab is active',
        (tester) async {
      when(() => bloc.state).thenReturn(SalesHistoryState.initial());

      await tester.pumpWidget(_wrap(const DesktopSalesHistoryView(), bloc));
      await tester.pump();

      // Tap the Reports tab to switch view
      await tester.tap(find.textContaining('Reports'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportsPlaceholderView), findsOneWidget);
    });
  });
}
