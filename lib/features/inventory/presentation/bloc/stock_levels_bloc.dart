import 'dart:async';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'stock_levels_event.dart';
part 'stock_levels_state.dart';

class StockLevelsBloc extends Bloc<StockLevelsEvent, StockLevelsState> {
  final InventoryUseCase useCase;

  StockLevelsBloc({required this.useCase}) : super(StockLevelsState.initial()) {
    on<OnStockLevelsStarted>(_onStarted);
    on<OnStockLevelsLoadMore>(_onLoadMore);
    on<OnStockLevelsFilterChanged>(_onFilterChanged);
    on<OnStockLevelsSearchChanged>(_onSearchChanged);
    on<OnStockLevelsReset>(_onReset);
  }

  Future<void> _onStarted(OnStockLevelsStarted event, Emitter<StockLevelsState> emit) async {
    emit(StockLevelsState.initial().copyWith(
      status: StockLevelsStatus.loading,
      lowStockOnly: event.lowStockOnly,
    ));
    try {
      final result = await useCase.getStock(page: 1, pageSize: 30);
      result.fold(
        (error) => emit(state.copyWith(
          status: StockLevelsStatus.failure,
          responseError: error,
        )),
        (dto) {
          var items = dto.results ?? <StockData>[];
          if (event.lowStockOnly) {
            items = items
                .where((s) => (s.isLowStock ?? false) || (s.isOutOfStock ?? false))
                .toList();
          }
          emit(state.copyWith(
            status: StockLevelsStatus.success,
            items: items,
            currentPage: 1,
            totalPages: dto.totalPages ?? 1,
            clearResponseError: true,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: StockLevelsStatus.failure, responseError: e.toString()));
    }
  }

  Future<void> _onLoadMore(OnStockLevelsLoadMore event, Emitter<StockLevelsState> emit) async {
    if (!state.hasMorePages) return;
    if (state.status == StockLevelsStatus.loadingMore) return;
    emit(state.copyWith(status: StockLevelsStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final result = await useCase.getStock(page: nextPage, pageSize: 30);
      result.fold(
        (error) => emit(state.copyWith(status: StockLevelsStatus.success)),
        (dto) => emit(state.copyWith(
          status: StockLevelsStatus.success,
          items: [...state.items, ...(dto.results ?? <StockData>[])],
          currentPage: nextPage,
          totalPages: dto.totalPages ?? state.totalPages,
        )),
      );
    } catch (_) {
      emit(state.copyWith(status: StockLevelsStatus.success));
    }
  }

  void _onFilterChanged(OnStockLevelsFilterChanged event, Emitter<StockLevelsState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onSearchChanged(OnStockLevelsSearchChanged event, Emitter<StockLevelsState> emit) {
    emit(state.copyWith(search: event.query));
  }

  void _onReset(OnStockLevelsReset event, Emitter<StockLevelsState> emit) {
    emit(StockLevelsState.initial());
  }
}
