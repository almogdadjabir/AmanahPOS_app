import 'dart:async';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/catalog_refresh.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

/// Categories screen and category detail. Phase 3: reads SQLite only and
/// re-reads whenever a local write or a pull touches [watchedTables];
/// writes go through [CategoryUseCase] -> `CategoryService` (row + outbox,
/// staged image, works offline). No REST call.
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryUseCase useCase;
  final OfflineLocalCache offlineLocalCache;

  /// `DbChangeNotifier.changes`.
  final Stream<Set<String>>? changes;

  /// The app's sync-now (pull to refresh); null = local re-read only.
  final Future<void> Function()? syncNow;

  static const Set<String> watchedTables = {
    'categories',
    'products',
    'stock',
    SyncTables.outbox,
    SyncTables.pendingUploads,
    'synced_assets',
  };

  StreamSubscription<Set<String>>? _changesSub;
  Timer? _debounce;
  int _loadToken = 0;
  int _productsToken = 0;

  /// The category whose products are on screen (detail), re-read on change.
  String? _productsCategoryId;

  CategoryBloc({
    required this.useCase,
    required this.offlineLocalCache,
    this.changes,
    this.syncNow,
  }) : super(CategoryState.initial()) {
    on<OnCategoryInitial>(_init);
    on<OnCategoriesSyncRequested>((_, _) => requestCatalogSync(syncNow));
    on<OnCategoriesChanged>(_changed);
    on<OnAddCategory>(_addCategory);
    on<OnEditCategory>(_editCategory);
    on<OnToggleCategoryActive>(_toggleActive);
    on<OnLoadCategoryProducts>(_loadProducts);
    on<OnLoadMoreCategoryProducts>(_loadMoreProducts);
    on<OnDeleteCategory>(_deleteCategory);
    on<OnCategoryReset>(_reset);
  }

  void _watch() {
    if (_changesSub != null || changes == null) return;
    _changesSub = changes!.listen((tables) {
      if (tables.intersection(watchedTables).isEmpty) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 16), () {
        if (!isClosed) add(const OnCategoriesChanged());
      });
    });
  }

  /// Categories + markers from SQLite; an overtaken read returns false.
  Future<bool> _reloadCategories(Emitter<CategoryState> emit) async {
    final token = ++_loadToken;
    final list = await offlineLocalCache.getCategories();
    final marks = await offlineLocalCache.getCatalogSyncMarks('category');
    if (token != _loadToken || emit.isDone) return false;
    emit(
      state.copyWith(
        categoryStatus: CategoryStatus.success,
        categoryList: list,
        syncMarks: marks,
        isFromCache: false,
        clearResponseError: true,
      ),
    );
    return true;
  }

  /// Active products of the open category + markers.
  Future<bool> _reloadProducts(Emitter<CategoryState> emit) async {
    final id = _productsCategoryId;
    if (id == null) return true;
    final token = ++_productsToken;
    final products = await offlineLocalCache.getProducts(
      categoryId: id,
      isActive: true,
    );
    final marks = await offlineLocalCache.getCatalogSyncMarks('product');
    if (token != _productsToken || emit.isDone) return false;
    emit(
      state.copyWith(
        productsStatus: CategoryProductsStatus.success,
        products: products,
        productSyncMarks: marks,
        currentPage: 1,
        totalPages: 1,
        productsFromCache: false,
        clearProductsError: true,
      ),
    );
    return true;
  }

  Future<void> _reload(Emitter<CategoryState> emit) async {
    try {
      for (var i = 0; i < 4; i++) {
        if (await _reloadCategories(emit) || emit.isDone) break;
      }
      for (var i = 0; i < 4; i++) {
        if (await _reloadProducts(emit) || emit.isDone) break;
      }
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          categoryStatus: state.categoryList.isEmpty
              ? CategoryStatus.failure
              : CategoryStatus.success,
          responseError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _init(
    OnCategoryInitial event,
    Emitter<CategoryState> emit,
  ) async {
    _watch();
    if (state.categoryStatus == CategoryStatus.initial) {
      emit(state.copyWith(categoryStatus: CategoryStatus.loading));
    }
    await _reload(emit);
  }

  Future<void> _changed(
    OnCategoriesChanged event,
    Emitter<CategoryState> emit,
  ) async {
    if (state.categoryStatus == CategoryStatus.initial &&
        _productsCategoryId == null) {
      return;
    }
    await _reload(emit);
  }

  Future<void> _submit(
    Emitter<CategoryState> emit,
    Future<String?> Function() write,
  ) async {
    emit(
      state.copyWith(
        submitStatus: CategorySubmitStatus.loading,
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
          submitStatus: CategorySubmitStatus.failure,
          submitError: error,
        ),
      );
      return;
    }
    await _reload(emit);
    if (emit.isDone) return;
    emit(
      state.copyWith(
        submitStatus: CategorySubmitStatus.success,
        clearSubmitError: true,
      ),
    );
  }

  Future<void> _addCategory(OnAddCategory event, Emitter<CategoryState> emit) =>
      _submit(emit, () async {
        _watch();
        final r = await useCase.addCategory(
          name: event.name,
          description: event.description,
          parent: event.parentId,
          image: event.image,
        );
        return r.getLeft().toNullable();
      });

  Future<void> _editCategory(
    OnEditCategory event,
    Emitter<CategoryState> emit,
  ) => _submit(emit, () async {
    _watch();
    final r = await useCase.editCategory(
      event.categoryId,
      EditCategoryRequestDto(
        name: event.name,
        // Form: an emptied description is '' (cleared), not "unchanged".
        description: event.description ?? '',
      ),
      image: event.image,
    );
    return r.getLeft().toNullable();
  });

  Future<void> _toggleActive(
    OnToggleCategoryActive event,
    Emitter<CategoryState> emit,
  ) async {
    // MVP: category active toggle disabled.
  }

  Future<void> _loadProducts(
    OnLoadCategoryProducts event,
    Emitter<CategoryState> emit,
  ) async {
    _watch();
    if (_productsCategoryId != event.categoryId) {
      _productsCategoryId = event.categoryId;
      emit(
        state.copyWith(
          productsStatus: CategoryProductsStatus.loading,
          products: const [],
          clearProductsError: true,
        ),
      );
    }
    try {
      for (var i = 0; i < 4; i++) {
        if (await _reloadProducts(emit) || emit.isDone) break;
      }
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          productsStatus: CategoryProductsStatus.failure,
          productsError: friendlyError(e),
        ),
      );
    }
  }

  /// SQLite holds every product of the category: there is no next page.
  Future<void> _loadMoreProducts(
    OnLoadMoreCategoryProducts event,
    Emitter<CategoryState> emit,
  ) async {}

  Future<void> _deleteCategory(
    OnDeleteCategory event,
    Emitter<CategoryState> emit,
  ) => _submit(emit, () async {
    _watch();
    final r = await useCase.deleteCategory(event.categoryId);
    return r.getLeft().toNullable();
  });

  Future<void> _reset(
    OnCategoryReset event,
    Emitter<CategoryState> emit,
  ) async {
    _loadToken++;
    _productsToken++;
    _productsCategoryId = null;
    emit(CategoryState.initial());
    add(const OnCategoryInitial());
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _changesSub?.cancel();
    return super.close();
  }
}
