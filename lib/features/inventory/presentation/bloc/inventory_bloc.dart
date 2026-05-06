import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
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
  final OfflineLocalCache offlineLocalCache;

  InventoryBloc({
    required this.useCase,
    required this.offlineLocalCache,
  }) : super(InventoryState.initial()) {
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
    if (state.status == InventoryStatus.loading) return;

    var emittedCachedData = false;

    // try {
      final cachedStock = await offlineLocalCache.getStock();

      if (cachedStock.isNotEmpty) {
        emittedCachedData = true;

        emit(
          state.copyWith(
            status: InventoryStatus.success,
            stockList: cachedStock,
            currentPage: 1,
            totalPages: 1,
            isFromCache: true,
            clearResponseError: true,
          ),
        );
      } else {
        final fallbackStock = await offlineLocalCache.getStockFallbackFromProducts();

        if (fallbackStock.isNotEmpty) {
          emittedCachedData = true;

          emit(
            state.copyWith(
              status: InventoryStatus.success,
              stockList: fallbackStock,
              currentPage: 1,
              totalPages: 1,
              isFromCache: true,
              clearResponseError: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: InventoryStatus.loading,
              stockList: [],
              currentPage: 1,
              totalPages: 1,
              isFromCache: false,
              clearResponseError: true,
            ),
          );
        }
      }

      final response = await useCase.getStock(page: 1);
      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        if (emittedCachedData) {
          emit(
            state.copyWith(
              status: InventoryStatus.success,
              responseError: error,
              isFromCache: true,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            status: InventoryStatus.failure,
            responseError: error,
            isFromCache: false,
          ),
        );
        return;
      }

      final freshStock = result?.results ?? [];

      await offlineLocalCache.saveStockToCache(freshStock);

      if (result != null && !emit.isDone) {
        emit(
          state.copyWith(
            status: InventoryStatus.success,
            stockList: freshStock,
            currentPage: result.currentPage ?? 1,
            totalPages: result.totalPages ?? 1,
            isFromCache: false,
            clearResponseError: true,
          ),
        );
      }
    // } catch (e) {
    //   if (emittedCachedData) {
    //     emit(
    //       state.copyWith(
    //         status: InventoryStatus.success,
    //         responseError: e.toString(),
    //         isFromCache: true,
    //       ),
    //     );
    //     return;
    //   }

      // if (!emit.isDone) {
      //   emit(
      //     state.copyWith(
      //       status: InventoryStatus.failure,
      //       responseError: e.toString(),
      //       isFromCache: false,
      //     ),
      //   );
      // }
    // }
  }

  Future<void> _loadMore(
      OnLoadMoreStock event,
      Emitter<InventoryState> emit,
      ) async {
    if (state.isFromCache) return;
    if (!state.hasMorePages) return;
    if (state.status == InventoryStatus.loadingMore) return;

    emit(state.copyWith(status: InventoryStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await useCase.getStock(page: nextPage);
      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            status: InventoryStatus.failure,
            responseError: error,
          ),
        );
        return;
      }

      if (result != null && !emit.isDone) {
        final freshStock = result.results ?? [];

        await offlineLocalCache.saveStockToCache(freshStock);

        emit(
          state.copyWith(
            status: InventoryStatus.success,
            stockList: [...state.stockList, ...freshStock],
            currentPage: result.currentPage ?? nextPage,
            totalPages: result.totalPages ?? state.totalPages,
            isFromCache: false,
            clearResponseError: true,
          ),
        );
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            status: InventoryStatus.failure,
            responseError: e.toString(),
          ),
        );
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
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final payload = AddStockRequestDto(
        productId: event.productId,
        shopId: event.shopId,
        quantity: event.quantity,
        movementType: event.movementType,
        reference: event.reference,
      );

      final response = await useCase.addStock(payload);
      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      final currentQty = await offlineLocalCache.getStockQuantity(
        productId: event.productId,
        shopId: event.shopId,
      );

      final addedQty = double.tryParse(event.quantity.toString()) ?? 0;
      final finalQty = currentQty + addedQty;

      await offlineLocalCache.updateStockQuantity(
        productId: event.productId,
        shopId: event.shopId,
        quantity: finalQty,
      );

      final updatedStockList = _upsertStockQuantity(
        stockList: state.stockList,
        productId: event.productId,
        shopId: event.shopId,
        quantity: finalQty,
      );

      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.success,
            status: InventoryStatus.success,
            stockList: updatedStockList,
            clearSubmitError: true,
          ),
        );
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _adjustStock(
      OnAdjustStock event,
      Emitter<InventoryState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

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
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      final finalQty = double.tryParse(event.newQuantity.toString()) ?? 0;

      await offlineLocalCache.updateStockQuantity(
        productId: event.productId,
        shopId: event.shopId,
        quantity: finalQty,
      );

      final updatedStockList = _upsertStockQuantity(
        stockList: state.stockList,
        productId: event.productId,
        shopId: event.shopId,
        quantity: finalQty,
      );

      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.success,
            status: InventoryStatus.success,
            stockList: updatedStockList,
            clearSubmitError: true,
          ),
        );
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _transferStock(
      OnTransferStock event,
      Emitter<InventoryState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

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
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      final transferQty = double.tryParse(event.quantity.toString()) ?? 0;

      final fromCurrentQty = await offlineLocalCache.getStockQuantity(
        productId: event.productId,
        shopId: event.fromShopId,
      );

      final toCurrentQty = await offlineLocalCache.getStockQuantity(
        productId: event.productId,
        shopId: event.toShopId,
      );

      final fromFinalQty = fromCurrentQty - transferQty;
      final toFinalQty = toCurrentQty + transferQty;

      await offlineLocalCache.transferStockLocally(
        productId: event.productId,
        fromShopId: event.fromShopId,
        toShopId: event.toShopId,
        quantity: transferQty,
      );

      var updatedStockList = _upsertStockQuantity(
        stockList: state.stockList,
        productId: event.productId,
        shopId: event.fromShopId,
        quantity: fromFinalQty < 0 ? 0 : fromFinalQty,
      );

      updatedStockList = _upsertStockQuantity(
        stockList: updatedStockList,
        productId: event.productId,
        shopId: event.toShopId,
        quantity: toFinalQty,
      );

      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.success,
            status: InventoryStatus.success,
            stockList: updatedStockList,
            clearSubmitError: true,
          ),
        );
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: e.toString(),
          ),
        );
      }
    }
  }

  List<StockData> _upsertStockQuantity({
    required List<StockData> stockList,
    required String productId,
    required String shopId,
    required double quantity,
  }) {
    var found = false;

    final updated = stockList.map((stock) {
      final matches = stock.product == productId && stock.shop == shopId;

      if (!matches) return stock;

      found = true;

      return stock.copyWith(
        quantity: quantity.toStringAsFixed(2),
        isOutOfStock: quantity <= 0,
      );
    }).toList();

    if (found) return updated;

    return [
      StockData(
        id: '$productId-$shopId',
        product: productId,
        shop: shopId,
        quantity: quantity.toStringAsFixed(2),
        isOutOfStock: quantity <= 0,
        isLowStock: false,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
      ...updated,
    ];
  }
}