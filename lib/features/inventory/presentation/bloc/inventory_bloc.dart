import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/features/inventory/data/models/requests/add_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/adjust_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/transfer_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/users/data/models/movement_type.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryUseCase useCase;
  final OfflineLocalCache offlineLocalCache;
  final Future<bool> Function() isOnline;

  /// Server accepts `expiry_date` on `stock.add` (capability
  /// `stock_add_expiry`): a dated add then works offline too.
  final Future<bool> Function() expiryAddSynced;

  static Future<bool> _never() async => false;

  // Add / remove / adjust / inbound are written locally by `StockService`
  // (through the repository), which already updated local stock; transfer
  // (REST) mirrors itself on the local base in the repository too. The bloc
  // only reads back the exact local quantity.

  InventoryBloc({
    required this.useCase,
    required this.offlineLocalCache,
    required this.isOnline,
    this.expiryAddSynced = _never,
  }) : super(InventoryState.initial()) {
    on<OnInventoryInitial>(_init);
    on<OnLoadMoreStock>(_loadMore);
    on<OnInventoryFilterChanged>(_onFilterChanged);
    on<OnAddStock>(_addStock);
    on<OnAdjustStock>(_adjustStock);
    on<OnRemoveStock>(_removeStock);
    on<OnTransferStock>(_transferStock);
    on<OnCreateInboundTransaction>(_createInboundTransaction);
    on<OnAcknowledgeInventorySubmit>(_acknowledgeSubmit);
    on<OnInventoryReset>(_onReset);
  }

  void _onReset(OnInventoryReset event, Emitter<InventoryState> emit) {
    emit(InventoryState.initial());
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
      final fallbackStock = await offlineLocalCache
          .getStockFallbackFromProducts();

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

    final response = await getIt<AppProgressCubit>().run(
      () => useCase.getStock(page: 1),
    );
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
    //         responseError: friendlyError(e),
    //         isFromCache: true,
    //       ),
    //     );
    //     return;
    //   }

    // if (!emit.isDone) {
    //   emit(
    //     state.copyWith(
    //       status: InventoryStatus.failure,
    //       responseError: friendlyError(e),
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
          state.copyWith(status: InventoryStatus.failure, responseError: error),
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
            responseError: friendlyError(e),
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

  Future<void> _addStock(OnAddStock event, Emitter<InventoryState> emit) async {
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    final expiry = event.expiryDate?.trim();
    if (expiry != null &&
        expiry.isNotEmpty &&
        !await isOnline() &&
        !await expiryAddSynced()) {
      // Without capability `stock_add_expiry` a dated add needs the REST
      // add (it creates the batch); nothing is written offline.
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            expiryNeedsConnection: true,
          ),
        );
      }
      return;
    }

    try {
      final payload = AddStockRequestDto(
        productId: event.productId,
        shopId: event.shopId,
        quantity: event.quantity,
        movementType: event.movementType,
        reference: event.reference,
        expiryDate: event.expiryDate,
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

      await _emitLocalStockSuccess(emit, event.productId, event.shopId);
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: friendlyError(e),
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

      await _emitLocalStockSuccess(emit, event.productId, event.shopId);
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: friendlyError(e),
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

      final fromQty = await offlineLocalCache.getStockQuantity(
        productId: event.productId,
        shopId: event.fromShopId,
      );
      final toQty = await offlineLocalCache.getStockQuantity(
        productId: event.productId,
        shopId: event.toShopId,
      );
      var updatedStockList = _upsertStockQuantity(
        stockList: state.stockList,
        productId: event.productId,
        shopId: event.fromShopId,
        quantity: fromQty,
      );
      updatedStockList = _upsertStockQuantity(
        stockList: updatedStockList,
        productId: event.productId,
        shopId: event.toShopId,
        quantity: toQty,
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
            submitError: friendlyError(e),
          ),
        );
      }
    }
  }

  void _acknowledgeSubmit(
    OnAcknowledgeInventorySubmit event,
    Emitter<InventoryState> emit,
  ) {
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.idle,
        clearSubmitError: true,
        inboundQueuedOffline: false,
      ),
    );
  }

  Future<void> _createInboundTransaction(
    OnCreateInboundTransaction event,
    Emitter<InventoryState> emit,
  ) async {
    if (state.submitStatus == InventorySubmitStatus.loading) return;

    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.loading,
        clearSubmitError: true,
        inboundQueuedOffline: false,
      ),
    );

    try {
      final response = await useCase.createInboundTransaction(event.request);
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

      emit(
        state.copyWith(
          submitStatus: InventorySubmitStatus.success,
          status: InventoryStatus.success,
          stockList: await _updatedStockListAfterInbound(event.request),
          clearSubmitError: true,
          inboundQueuedOffline: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: InventorySubmitStatus.failure,
          submitError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _removeStock(
    OnRemoveStock event,
    Emitter<InventoryState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );
    try {
      final response = await useCase.removeStock(
        productId: event.productId,
        shopId: event.shopId,
        quantity: event.quantity,
        reason: event.reason,
      );
      final error = response.getLeft().toNullable();
      if (error != null) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              submitStatus: InventorySubmitStatus.failure,
              submitError: error,
            ),
          );
        }
        return;
      }
      await _emitLocalStockSuccess(emit, event.productId, event.shopId);
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: InventorySubmitStatus.failure,
            submitError: friendlyError(e),
          ),
        );
      }
    }
  }

  /// Stock was already written by StockService; show the exact local
  /// quantity.
  Future<void> _emitLocalStockSuccess(
    Emitter<InventoryState> emit,
    String productId,
    String shopId,
  ) async {
    final qty = await offlineLocalCache.getStockQuantity(
      productId: productId,
      shopId: shopId,
    );
    if (emit.isDone) return;
    emit(
      state.copyWith(
        submitStatus: InventorySubmitStatus.success,
        status: InventoryStatus.success,
        stockList: _upsertStockQuantity(
          stockList: state.stockList,
          productId: productId,
          shopId: shopId,
          quantity: qty,
        ),
        clearSubmitError: true,
      ),
    );
  }

  Future<List<StockData>> _updatedStockListAfterInbound(
    CreateInboundRequestDto request,
  ) async {
    var updated = state.stockList;

    for (final item in request.items) {
      final finalQty = await offlineLocalCache.getStockQuantity(
        productId: item.productId,
        shopId: request.shopId,
      );

      updated = _upsertStockQuantity(
        stockList: updated,
        productId: item.productId,
        shopId: request.shopId,
        quantity: finalQty,
      );
    }

    return updated;
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
