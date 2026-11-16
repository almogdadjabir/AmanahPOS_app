import 'dart:async';

import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements SalesHistoryUseCase {}

SaleHistoryItem _sale(String ref) => SaleHistoryItem(
  id: ref,
  clientSaleId: ref,
  receiptNumber: ref,
  shopId: null,
  shopName: null,
  customerId: null,
  customerName: null,
  paymentMethod: 'cash',
  total: 1,
  itemCount: 1,
  status: SaleHistoryStatus.completed,
  createdAt: DateTime(2026, 11, 15),
  isOfflinePending: false,
  offlineErrorMessage: null,
  items: const [],
);

void main() {
  late _MockUseCase useCase;
  late SalesHistoryBloc bloc;

  Future<Either<String?, SalesHistoryPage>> Function(Invocation) page(
    List<SaleHistoryItem> items, {
    int? total,
  }) =>
      (_) async => Right(
        SalesHistoryPage(items: items, hasMore: false, totalCount: total),
      );

  void stub(
    Future<Either<String?, SalesHistoryPage>> Function(Invocation) answer,
  ) {
    when(
      () => useCase.getSalesPage(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        shopId: any(named: 'shopId'),
        status: any(named: 'status'),
        paymentMethod: any(named: 'paymentMethod'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        onlyUnsynced: any(named: 'onlyUnsynced'),
      ),
    ).thenAnswer(answer);
  }

  setUp(() {
    useCase = _MockUseCase();
    bloc = SalesHistoryBloc(useCase: useCase);
  });

  tearDown(() => bloc.close());

  test(
    'status, payment and date filters go to the server, with the count',
    () async {
      stub(page([_sale('A1')], total: 128));
      bloc.add(
        const SalesHistoryFiltersChanged(
          SalesHistoryFilters(
            date: SalesDatePreset.today,
            payment: 'cash',
            status: 'partial_refund',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final c = verify(
        () => useCase.getSalesPage(
          page: 1,
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
          shopId: any(named: 'shopId'),
          status: captureAny(named: 'status'),
          paymentMethod: captureAny(named: 'paymentMethod'),
          dateFrom: captureAny(named: 'dateFrom'),
          dateTo: captureAny(named: 'dateTo'),
          onlyUnsynced: captureAny(named: 'onlyUnsynced'),
        ),
      ).captured;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Captured in the order the named args are written (alphabetical).
      expect(c, [false, 'partial_refund', 'cash', today, today]);
      expect(bloc.state.totalCount, 128);
      expect(bloc.state.items.single.receiptNumber, 'A1');
      expect(bloc.state.filters.isActive, isTrue);
    },
  );

  test('the selected shop (when provided) is passed with every page', () async {
    await bloc.close();
    var shop = 'shop-1';
    bloc = SalesHistoryBloc(useCase: useCase, shopId: () => shop);
    stub(page(const []));
    bloc.add(const SalesHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    shop = 'shop-2';
    bloc.add(const SalesHistoryRefreshed());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final shops = verify(
      () => useCase.getSalesPage(
        page: 1,
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        shopId: captureAny(named: 'shopId'),
        status: any(named: 'status'),
        paymentMethod: any(named: 'paymentMethod'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        onlyUnsynced: any(named: 'onlyUnsynced'),
      ),
    ).captured;
    expect(shops, ['shop-1', 'shop-2']);
  });

  test('the Not synced filter asks for unsynced sales only', () async {
    stub(page(const []));
    bloc.add(
      const SalesHistoryFiltersChanged(SalesHistoryFilters(onlyUnsynced: true)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(
      () => useCase.getSalesPage(
        page: 1,
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        shopId: any(named: 'shopId'),
        status: any(named: 'status'),
        paymentMethod: any(named: 'paymentMethod'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        onlyUnsynced: true,
      ),
    ).called(1);
  });

  test('a slow response for old filters is dropped', () async {
    final slow = Completer<Either<String?, SalesHistoryPage>>();
    var call = 0;
    stub((_) {
      call++;
      if (call == 1) return slow.future;
      return Future.value(
        Right(
          SalesHistoryPage(
            items: [_sale('NEW')],
            hasMore: false,
            totalCount: 1,
          ),
        ),
      );
    });

    bloc.add(
      const SalesHistoryFiltersChanged(SalesHistoryFilters(payment: 'cash')),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(
      const SalesHistoryFiltersChanged(SalesHistoryFilters(payment: 'bankak')),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // The first (cash) request answers last, with different rows.
    slow.complete(
      Right(
        SalesHistoryPage(items: [_sale('OLD')], hasMore: false, totalCount: 9),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.filters.payment, 'bankak');
    expect(bloc.state.items.map((e) => e.receiptNumber), ['NEW']);
    expect(bloc.state.totalCount, 1);
  });

  test('SalesHistoryItemReplaced swaps the sale in the list', () async {
    stub(page([_sale('A1'), _sale('A2')]));
    bloc.add(const SalesHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(
      SalesHistoryItemReplaced(
        _sale('A2').copyWith(status: SaleHistoryStatus.partialRefund),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.items[1].status, SaleHistoryStatus.partialRefund);
    expect(bloc.state.items[0].status, SaleHistoryStatus.completed);
  });
}
