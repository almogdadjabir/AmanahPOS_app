import 'package:amana_pos/features/inventory/data/models/requests/add_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/adjust_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/transfer_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/users/data/models/movement_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryUseCase useCase;

  InventoryBloc({required this.useCase}) : super(InventoryState.initial()) {
    on<OnInventoryInitial>(_init);
    on<OnLoadMoreStock>(_loadMore);
    on<OnInventoryFilterChanged>(_onFilterChanged);
    on<OnAddStock>(_addStock);
    on<OnAdjustStock>(_adjustStock);
    on<OnTransferStock>(_transferStock);
  }

  Future<void> _init(
      OnInventoryInitial event,
      Emitter<InventoryState> emit,
      ) async {
    if (state.status == InventoryStatus.loading ||
        state.status == InventoryStatus.success) return;

    emit(state.copyWith(status: InventoryStatus.loading));

    try {
      final response = await useCase.getStock(page: 1);
      final error  = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(
          status: InventoryStatus.failure,
          responseError: error,
        ));
        return;
      }

      if (result != null && !emit.isDone) {
        emit(state.copyWith(
          status:      InventoryStatus.success,
          stockList:   result.results ?? [],
          currentPage: result.currentPage ?? 1,
          totalPages:  result.totalPages  ?? 1,
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          status: InventoryStatus.failure,
          responseError: e.toString(),
        ));
      }
    }
  }

  Future<void> _loadMore(
      OnLoadMoreStock event,
      Emitter<InventoryState> emit,
      ) async {
    if (!state.hasMorePages) return;
    if (state.status == InventoryStatus.loadingMore) return;

    emit(state.copyWith(status: InventoryStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await useCase.getStock(page: nextPage);
      final error  = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(
          status: InventoryStatus.failure,
          responseError: error,
        ));
        return;
      }

      if (result != null && !emit.isDone) {
        emit(state.copyWith(
          status:      InventoryStatus.success,
          stockList:   [...state.stockList, ...?result.results],
          currentPage: result.currentPage ?? nextPage,
          totalPages:  result.totalPages  ?? state.totalPages,
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(status: InventoryStatus.failure));
      }
    }
  }

  void _onFilterChanged(
      OnInventoryFilterChanged event,
      Emitter<InventoryState> emit,
      ) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _addStock(
      OnAddStock event,
      Emitter<InventoryState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: InventorySubmitStatus.loading,
      submitError: null,
    ));
    try {
      final payload = AddStockRequestDto(
        productId:    event.productId,
        shopId:       event.shopId,
        quantity:     event.quantity,
        movementType: event.movementType,   // ← was missing
        reference:    event.reference,
      );

      final response = await useCase.addStock(payload);
      final error = response.getLeft().toNullable();
      if (error != null) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: error,
        ));
        return;
      }
      if (!emit.isDone) {
        // Refresh list to reflect new quantities
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.success,
          // Reset so screen refetches fresh
          status: InventoryStatus.initial,
          stockList: [],
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: e.toString(),
        ));
      }
    }
  }

  Future<void> _adjustStock(
      OnAdjustStock event,
      Emitter<InventoryState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: InventorySubmitStatus.loading,
      submitError: null,
    ));
    try {
      final payload = AdjustStockRequestDto(
        productId: event.productId,
        shopId: event.shopId,
        newQuantity: event.newQuantity,
        notes: event.notes,
      );

      final response = await useCase.adjustStock(payload);
      final error = response.getLeft().toNullable();
      if (error != null) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: error,
        ));
        return;
      }
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.success,
          status: InventoryStatus.initial,
          stockList: [],
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: e.toString(),
        ));
      }
    }
  }

  Future<void> _transferStock(
      OnTransferStock event,
      Emitter<InventoryState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: InventorySubmitStatus.loading,
      submitError: null,
    ));
    try {
      final payload = TransferStockRequestDto(
        productId: event.productId,
        fromShop: event.fromShopId,
        toShop: event.toShopId,
        quantity: event.quantity,
      );
      final response = await useCase.transferStock(payload);
      final error = response.getLeft().toNullable();
      if (error != null) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: error,
        ));
        return;
      }
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.success,
          status: InventoryStatus.initial,
          stockList: [],
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: e.toString(),
        ));
      }
    }
  }
}