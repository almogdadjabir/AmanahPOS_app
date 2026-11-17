import 'dart:async';

import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/catalog_refresh.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'product_event.dart';
part 'product_state.dart';

/// Products and categories of the catalog screens, the POS grid and the
/// stock pickers. Phase 3: reads SQLite only (the sync feed is the only
/// source of server changes) and re-reads whenever a local write or a pull
/// touches [watchedTables]; writes go through [ProductUseCase] ->
/// `ProductService` (row + outbox, works offline). No REST call.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductUseCase useCase;
  final CategoryUseCase categoryUseCase;
  final OfflineLocalCache offlineLocalCache;

  /// `DbChangeNotifier.changes`: the tables each local write / pull touched.
  final Stream<Set<String>>? changes;

  /// The app's sync-now (pull to refresh); null = local re-read only.
  final Future<void> Function()? syncNow;

  /// What the list shows: rows, their stock, categories, sync markers and
  /// staged images.
  static const Set<String> watchedTables = {
    'products',
    'categories',
    'stock',
    SyncTables.outbox,
    SyncTables.pendingUploads,
    'synced_assets',
  };

  /// Name of the category created for a product saved without one.
  static const String autoCategoryName = 'General';

  StreamSubscription<Set<String>>? _changesSub;
  Timer? _debounce;
  int _loadToken = 0;
  int _queryToken = 0;

  ProductBloc({
    required this.useCase,
    required this.categoryUseCase,
    required this.offlineLocalCache,
    this.changes,
    this.syncNow,
  }) : super(ProductState.initial()) {
    on<OnProductInitial>(_init);
    on<OnProductsSyncRequested>((_, _) => requestCatalogSync(syncNow));
    on<OnProductsChanged>(_changed);
    on<OnProductCategorySelected>(_onCategorySelected);
    on<OnProductQuery>(_query);
    on<OnProductsLoadAll>(_loadAll);
    on<OnCreateProductCategory>(_createCategory);
    on<OnLoadMoreProducts>(_loadMore);
    on<OnToggleProductLayout>(_toggleLayout);
    on<OnAddProduct>(_addProduct);
    on<OnAddProductWithAutoCategory>(_addProductWithAutoCategory);
    on<OnUpdateProduct>(_updateProduct);
    on<OnDeleteProduct>(_deleteProduct);
    on<OnProductsSoldLocally>(_productsSoldLocally);
    on<OnProductReset>(_reset);
  }

  /// Tables whose change can alter the listed rows themselves (stock
  /// writes `products.stock_level`; images resolve from `synced_assets`).
  /// The rest of [watchedTables] (outbox, staged uploads) only moves the
  /// sync markers (review M10).
  static const Set<String> rowTables = {
    'products',
    'categories',
    'stock',
    'synced_assets',
  };

  final Set<String> _pendingTables = {};

  void _watch() {
    if (_changesSub != null || changes == null) return;
    _changesSub = changes!.listen((tables) {
      final hit = tables.intersection(watchedTables);
      if (hit.isEmpty) return;
      _pendingTables.addAll(hit);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 16), () {
        final t = {..._pendingTables};
        _pendingTables.clear();
        if (!isClosed) add(OnProductsChanged(t));
      });
    });
  }

  /// Re-reads only the sync markers (an outbox / upload-only change).
  Future<void> _reloadMarks(Emitter<ProductState> emit) async {
    try {
      final marks = await offlineLocalCache.getCatalogSyncMarks('product');
      if (emit.isDone) return;
      emit(state.copyWith(syncMarks: marks));
    } catch (_) {
      // Markers are cosmetic; the next row change re-reads everything.
    }
  }

  /// Reads the list, categories and markers from SQLite and emits them.
  /// An older read finishing after a newer one is dropped (returns false).
  Future<bool> _reload(Emitter<ProductState> emit) async {
    final token = ++_loadToken;
    final products = await offlineLocalCache.getProducts(
      categoryId: state.selectedCategoryId,
      isActive: true,
    );
    final categories = await offlineLocalCache.getCategories();
    final marks = await offlineLocalCache.getCatalogSyncMarks('product');
    if (token != _loadToken || emit.isDone) return false;
    emit(
      state.copyWith(
        productStatus: ProductStatus.success,
        products: products,
        categories: categories,
        syncMarks: marks,
        currentPage: 1,
        totalPages: 1,
        isFromCache: false,
        clearResponseError: true,
      ),
    );
    return true;
  }

  /// [_reload] that never throws. A read overtaken by a newer one is
  /// retried (a few times), so a caller such as a submit only continues
  /// once the state holds data read after its own write.
  Future<void> _safeReload(Emitter<ProductState> emit) async {
    try {
      for (var i = 0; i < 4; i++) {
        if (await _reload(emit) || emit.isDone) return;
      }
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          productStatus: state.products.isEmpty
              ? ProductStatus.failure
              : ProductStatus.success,
          responseError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _init(OnProductInitial event, Emitter<ProductState> emit) async {
    _watch();
    if (state.productStatus == ProductStatus.initial) {
      emit(state.copyWith(productStatus: ProductStatus.loading));
    }
    await _safeReload(emit);
  }

  Future<void> _changed(
    OnProductsChanged event,
    Emitter<ProductState> emit,
  ) async {
    // Nothing on screen yet: the first OnProductInitial loads.
    if (state.productStatus == ProductStatus.initial) return;
    if (event.tables.isNotEmpty &&
        event.tables.intersection(rowTables).isEmpty) {
      await _reloadMarks(emit);
      return;
    }
    await _safeReload(emit);
  }

  Future<void> _onCategorySelected(
    OnProductCategorySelected event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearCategory: event.categoryId == null,
      ),
    );
    await _safeReload(emit);
  }

  /// SQLite holds the whole catalog: there is never a next page.
  Future<void> _loadMore(
    OnLoadMoreProducts event,
    Emitter<ProductState> emit,
  ) async {}

  /// Kept for the Low / Out filters: the list already holds every product.
  Future<void> _loadAll(
    OnProductsLoadAll event,
    Emitter<ProductState> emit,
  ) async {}

  Future<void> _query(OnProductQuery event, Emitter<ProductState> emit) async {
    final token = ++_queryToken;
    final search = event.search.trim();

    if (search.isEmpty && !event.inactiveOnly) {
      emit(
        state.copyWith(
          queryStatus: ProductQueryStatus.idle,
          queryResults: const [],
        ),
      );
      return;
    }

    emit(state.copyWith(queryStatus: ProductQueryStatus.loading));
    try {
      final results = await offlineLocalCache.getProducts(
        search: search.isEmpty ? null : search,
        isActive: !event.inactiveOnly,
      );
      if (token != _queryToken || emit.isDone) return;
      emit(
        state.copyWith(
          queryStatus: ProductQueryStatus.success,
          queryResults: results,
        ),
      );
    } catch (_) {
      if (token != _queryToken || emit.isDone) return;
      emit(state.copyWith(queryStatus: ProductQueryStatus.failure));
    }
  }

  Future<void> _createCategory(
    OnCreateProductCategory event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final result = await categoryUseCase.addCategory(name: event.name.trim());
      final id = result.getRight().toNullable();
      if (id == null) {
        event.completer.complete(null);
        return;
      }
      await _safeReload(emit);
      CategoryData? created;
      for (final c in state.categories) {
        if (c.id == id) created = c;
      }
      event.completer.complete(created);
    } catch (_) {
      if (!event.completer.isCompleted) event.completer.complete(null);
    }
  }

  void _toggleLayout(OnToggleProductLayout event, Emitter<ProductState> emit) {
    emit(state.copyWith(isGrid: !state.isGrid));
  }

  Future<void> _submit(
    Emitter<ProductState> emit,
    Future<String?> Function() write,
  ) async {
    emit(
      state.copyWith(
        submitStatus: ProductSubmitStatus.loading,
        clearSubmitError: true,
      ),
    );
    String? error;
    try {
      error = await write();
    } catch (e) {
      error = friendlyError(e);
    }
    if (emit.isDone) return;
    if (error != null) {
      emit(
        state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError: error,
        ),
      );
      return;
    }
    // The row (and its stock) shows at once, read back from SQLite.
    await _safeReload(emit);
    if (emit.isDone) return;
    emit(
      state.copyWith(
        submitStatus: ProductSubmitStatus.success,
        clearSubmitError: true,
      ),
    );
  }

  Future<void> _addProduct(OnAddProduct event, Emitter<ProductState> emit) =>
      _submit(emit, () async {
        final r = await useCase.addProduct(
          event.dto,
          initialQuantity: event.openingStock,
          shopId: event.openingShopId,
        );
        return r.getLeft().toNullable();
      });

  /// No category picked: the "General" category is reused or created in
  /// the SAME write as the product (and its opening stock).
  Future<void> _addProductWithAutoCategory(
    OnAddProductWithAutoCategory event,
    Emitter<ProductState> emit,
  ) => _submit(emit, () async {
    final d = event.dto;
    final r = await useCase.addProduct(
      AddProductRequestDto(
        name: d.name,
        price: d.price,
        costPrice: d.costPrice,
        category: '',
        unit: d.unit,
        trackInventory: d.trackInventory,
        minStockLevel: d.minStockLevel,
        description: d.description,
        sku: d.sku,
        barcode: d.barcode,
        expiryAlertDays: d.expiryAlertDays,
        imageUpload: d.imageUpload,
      ),
      initialQuantity: event.openingStock,
      shopId: event.openingShopId,
      newCategoryName: autoCategoryName,
    );
    return r.getLeft().toNullable();
  });

  Future<void> _updateProduct(
    OnUpdateProduct event,
    Emitter<ProductState> emit,
  ) => _submit(emit, () async {
    final r = await useCase.editProduct(event.productId, event.dto);
    return r.getLeft().toNullable();
  });

  Future<void> _deleteProduct(
    OnDeleteProduct event,
    Emitter<ProductState> emit,
  ) => _submit(emit, () async {
    final r = await useCase.deleteProduct(event.productId);
    return r.getLeft().toNullable();
  });

  void _productsSoldLocally(
    OnProductsSoldLocally event,
    Emitter<ProductState> emit,
  ) {
    if (event.soldQuantities.isEmpty) return;

    final updatedProducts = state.products
        .map((product) {
          final productId = product.id;
          if (productId == null) return product;

          final soldQty = event.soldQuantities[productId];
          if (soldQty == null || soldQty <= 0) return product;

          final currentStock = product.stockLevel ?? 0;
          final nextStock = currentStock - soldQty;

          return product.copyWith(stockLevel: nextStock < 0 ? 0 : nextStock);
        })
        .toList(growable: false);

    emit(state.copyWith(products: updatedProducts));
  }

  Future<void> _reset(OnProductReset event, Emitter<ProductState> emit) async {
    // Emit initial state first so the UI shows the loading skeleton
    // rather than the previous user's data for even a single frame.
    _loadToken++;
    emit(ProductState.initial());
    add(const OnProductInitial());
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _changesSub?.cancel();
    return super.close();
  }
}
