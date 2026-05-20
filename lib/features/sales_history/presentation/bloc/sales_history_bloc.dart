import 'dart:async';

import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sales_history_event.dart';
part 'sales_history_state.dart';

class SalesHistoryBloc extends Bloc<SalesHistoryEvent, SalesHistoryState> {
  final SalesHistoryUseCase _useCase;

  static const int      _pageSize        = 20;
  static const Duration _searchDebounce  = Duration(milliseconds: 450);

  Timer? _searchTimer;

  SalesHistoryBloc({required SalesHistoryUseCase useCase})
      : _useCase = useCase,
        super(SalesHistoryState.initial()) {
    on<SalesHistoryStarted>(_onStarted);
    on<SalesHistoryLoadMore>(_onLoadMore);
    on<SalesHistoryRefreshed>(_onRefreshed);
    on<SalesHistorySearchChanged>(_onSearchChanged);
    on<SalesHistoryItemReturnProcessed>(_onReturnProcessed);
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
      SalesHistoryStarted _,
      Emitter<SalesHistoryState> emit,
      ) async {
    // Guard: don't re-fetch while already loading or data already present.
    if (state.isLoading || state.items.isNotEmpty) return;
    emit(state.copyWith(status: SalesHistoryBlocStatus.loading));
    await _fetchPage(emit, page: 1, replace: true);
  }

  Future<void> _onLoadMore(
      SalesHistoryLoadMore _,
      Emitter<SalesHistoryState> emit,
      ) async {
    if (!state.hasMore || state.isLoading) return;
    emit(state.copyWith(status: SalesHistoryBlocStatus.loadingMore));
    await _fetchPage(emit, page: state.currentPage + 1, replace: false);
  }

  Future<void> _onRefreshed(
      SalesHistoryRefreshed _,
      Emitter<SalesHistoryState> emit,
      ) async {
    _searchTimer?.cancel();
    emit(state.copyWith(
      status:      SalesHistoryBlocStatus.loading,
      items:       [],
      currentPage: 0,
      hasMore:     true,
      clearError:  true,
    ));
    await _fetchPage(emit, page: 1, replace: true);
  }

  Future<void> _onSearchChanged(
      SalesHistorySearchChanged event,
      Emitter<SalesHistoryState> emit,
      ) async {
    _searchTimer?.cancel();


    emit(state.copyWith(
      searchQuery: event.query,
      items:       [],
      currentPage: 0,
      hasMore:     true,
      clearError:  true,
    ));

    final completer = Completer<void>();
    _searchTimer = Timer(_searchDebounce, completer.complete);
    await completer.future;

    if (isClosed || emit.isDone) return;

    emit(state.copyWith(status: SalesHistoryBlocStatus.loading));
    await _fetchPage(emit, page: 1, replace: true);
  }

  void _onReturnProcessed(
      SalesHistoryItemReturnProcessed event,
      Emitter<SalesHistoryState> emit,
      ) {
    final updated = state.items.map((item) {
      if (item.id != event.saleId) return item;
      return item.copyWith(
        status: event.isPartial
            ? SaleHistoryStatus.partialRefund
            : SaleHistoryStatus.refunded,
      );
    }).toList();

    emit(state.copyWith(items: updated));
  }

  Future<void> _fetchPage(
      Emitter<SalesHistoryState> emit, {
        required int  page,
        required bool replace,
      }) async {
    final query = state.searchQuery.trim();

    final result = await _useCase.getSalesPage(
      page:     page,
      pageSize: _pageSize,
      search:   query.isEmpty ? null : query,
    );

    if (emit.isDone) return;

    result.fold(
          (error) => emit(state.copyWith(
        status: replace
            ? SalesHistoryBlocStatus.failure
            : SalesHistoryBlocStatus.loaded,
        errorMessage: error ?? 'Failed to load sales',
      )),

          (pageData) {
        final raw = replace
            ? pageData.items
            : [...state.items, ...pageData.items];

        final seen   = <String>{};
        final deduped = [
          for (final item in raw)
            if (seen.add(item.clientSaleId)) item,
        ];

        emit(state.copyWith(
          items: deduped,
          status: SalesHistoryBlocStatus.loaded,
          currentPage: page,
          hasMore: pageData.hasMore,
          clearError:  true,
        ));
      },
    );
  }
}