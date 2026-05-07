import 'dart:async';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/category/data/models/requests/add_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryUseCase useCase;
  final ProductUseCase productUseCase;
  final OfflineLocalCache offlineLocalCache;

  CategoryBloc({
    required this.useCase,
    required this.productUseCase,
    required this.offlineLocalCache,
  }) : super(CategoryState.initial()) {
    on<OnCategoryInitial>(_init);
    on<OnAddCategory>(_addCategory);
    on<OnEditCategory>(_editCategory);
    on<OnToggleCategoryActive>(_toggleActive);
    on<OnLoadCategoryProducts>(_loadProducts);
    on<OnLoadMoreCategoryProducts>(_loadMoreProducts);
    on<OnDeleteCategory>(_deleteCategory);
    on<OnCategoryReset>(_reset);
  }

  Future<void> _init(
      OnCategoryInitial event,
      Emitter<CategoryState> emit,
      ) async {
    // Block concurrent loads.
    if (state.categoryStatus == CategoryStatus.loading) return;

    // Block redundant auto-inits when fresh live data is already in memory.
    if (!event.force &&
        state.categoryStatus == CategoryStatus.success &&
        !state.isFromCache) {
      return;
    }

    var emittedCachedData = false;

    try {
      final cachedCategories = await offlineLocalCache.getCategories();

      if (cachedCategories.isNotEmpty) {
        emittedCachedData = true;
        emit(state.copyWith(
          categoryStatus: CategoryStatus.success,
          categoryList: cachedCategories,
          isFromCache: true,
          clearResponseError: true,
        ));
      } else {
        emit(state.copyWith(
          categoryStatus: CategoryStatus.loading,
          categoryList: [],
          isFromCache: false,
          clearResponseError: true,
        ));
      }

      final response = await useCase.getCategories();

      response.fold(
            (error) {
          if (emittedCachedData) {
            emit(state.copyWith(
              categoryStatus: CategoryStatus.success,
              responseError: error,
              isFromCache: true,
            ));
            return;
          }
          emit(state.copyWith(
            categoryStatus: CategoryStatus.failure,
            responseError: error,
            isFromCache: false,
          ));
        },
            (result) {
          emit(state.copyWith(
            categoryStatus: CategoryStatus.success,
            categoryList: result.data ?? [],
            isFromCache: false,
            clearResponseError: true,
          ));
        },
      );
    } catch (e) {
      if (emittedCachedData) {
        emit(state.copyWith(
          categoryStatus: CategoryStatus.success,
          responseError: e.toString(),
          isFromCache: true,
        ));
        return;
      }
      emit(state.copyWith(
        categoryStatus: CategoryStatus.failure,
        responseError: e.toString(),
        isFromCache: false,
      ));
    }
  }

  Future<void> _addCategory(
      OnAddCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: CategorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final payload = AddCategoryRequestDto(
        name: event.name,
        description: event.description,
      );

      final response = await useCase.addCategory(payload);

      response.fold(
            (error) => emit(
          state.copyWith(
            submitStatus: CategorySubmitStatus.failure,
            submitError: error,
          ),
        ),
            (newCategory) {
          if (newCategory.data == null) return;

          if (event.parentId != null) {
            final updated = state.categoryList.map((category) {
              if (category.id != event.parentId) return category;

              return category.copyWith(
                children: [...?category.children, newCategory.data!],
              );
            }).toList();

            emit(
              state.copyWith(
                submitStatus: CategorySubmitStatus.success,
                categoryList: updated,
              ),
            );
          } else {
            emit(
              state.copyWith(
                submitStatus: CategorySubmitStatus.success,
                categoryList: [...state.categoryList, newCategory.data!],
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CategorySubmitStatus.failure,
          submitError: e.toString(),
        ),
      );
    }
  }

  Future<void> _editCategory(
      OnEditCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: CategorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final payload = EditCategoryRequestDto(
        name: event.name,
        description: event.description,
      );

      final response = await useCase.editCategory(
        event.categoryId,
        payload,
      );

      response.fold(
            (error) => emit(
          state.copyWith(
            submitStatus: CategorySubmitStatus.failure,
            submitError: error,
          ),
        ),
            (_) => emit(
          state.copyWith(
            submitStatus: CategorySubmitStatus.success,
            categoryList: _patchCategory(
              state.categoryList,
              event.categoryId,
                  (category) => category.copyWith(
                name: event.name,
                description: event.description,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CategorySubmitStatus.failure,
          submitError: e.toString(),
        ),
      );
    }
  }

  Future<void> _toggleActive(
      OnToggleCategoryActive event,
      Emitter<CategoryState> emit,
      ) async {
    // MVP: category active toggle disabled.
  }

  List<CategoryData> _patchCategory(
      List<CategoryData> list,
      String id,
      CategoryData Function(CategoryData) patch,
      ) {
    return list.map((category) {
      if (category.id == id) return patch(category);

      if (category.children != null && category.children!.isNotEmpty) {
        return category.copyWith(
          children: _patchCategory(category.children!, id, patch),
        );
      }

      return category;
    }).toList();
  }

  Future<void> _loadProducts(
      OnLoadCategoryProducts event,
      Emitter<CategoryState> emit,
      ) async {
    var emittedCachedData = false;

    try {
      final cachedProducts = await offlineLocalCache.getProducts(
        categoryId: event.categoryId,
      );

      if (cachedProducts.isNotEmpty) {
        emittedCachedData = true;

        emit(
          state.copyWith(
            productsStatus: CategoryProductsStatus.success,
            products: cachedProducts,
            currentPage: 1,
            totalPages: 1,
            productsFromCache: true,
            clearProductsError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            productsStatus: CategoryProductsStatus.loading,
            products: [],
            currentPage: 1,
            totalPages: 1,
            productsFromCache: false,
            clearProductsError: true,
          ),
        );
      }

      final response = await productUseCase.getCategoryProducts(
        categoryId: event.categoryId,
        page: 1,
        pageSize: 20,
      );

      response.fold(
            (error) {
          if (emittedCachedData) {
            emit(
              state.copyWith(
                productsStatus: CategoryProductsStatus.success,
                productsError: error,
                productsFromCache: true,
              ),
            );
            return;
          }

          emit(
            state.copyWith(
              productsStatus: CategoryProductsStatus.failure,
              productsError: error,
              productsFromCache: false,
            ),
          );
        },
            (result) {
          emit(
            state.copyWith(
              productsStatus: CategoryProductsStatus.success,
              products: result.products ?? [],
              currentPage: result.currentPage ?? 1,
              totalPages: result.totalPages ?? 1,
              productsFromCache: false,
              clearProductsError: true,
            ),
          );
        },
      );
    } catch (e) {
      if (emittedCachedData) {
        emit(
          state.copyWith(
            productsStatus: CategoryProductsStatus.success,
            productsError: e.toString(),
            productsFromCache: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          productsStatus: CategoryProductsStatus.failure,
          productsError: e.toString(),
          productsFromCache: false,
        ),
      );
    }
  }

  Future<void> _loadMoreProducts(
      OnLoadMoreCategoryProducts event,
      Emitter<CategoryState> emit,
      ) async {
    if (state.productsFromCache) return;
    if (!state.hasMorePages) return;
    if (state.productsStatus == CategoryProductsStatus.loadingMore) return;

    emit(
      state.copyWith(
        productsStatus: CategoryProductsStatus.loadingMore,
      ),
    );

    try {
      final nextPage = state.currentPage + 1;

      final response = await productUseCase.getCategoryProducts(
        categoryId: event.categoryId,
        page: nextPage,
        pageSize: 20,
      );

      response.fold(
            (error) => emit(
          state.copyWith(
            productsStatus: CategoryProductsStatus.failure,
            productsError: error,
          ),
        ),
            (result) => emit(
          state.copyWith(
            productsStatus: CategoryProductsStatus.success,
            products: [...state.products, ...?result.products],
            currentPage: result.currentPage ?? nextPage,
            totalPages: result.totalPages ?? state.totalPages,
            productsFromCache: false,
            clearProductsError: true,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          productsStatus: CategoryProductsStatus.failure,
          productsError: e.toString(),
        ),
      );
    }
  }

  Future<void> _deleteCategory(
      OnDeleteCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: CategorySubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final response = await useCase.deleteCategory(event.categoryId);

      response.fold(
            (error) => emit(
          state.copyWith(
            submitStatus: CategorySubmitStatus.failure,
            submitError: error,
          ),
        ),
            (_) => emit(
          state.copyWith(
            submitStatus: CategorySubmitStatus.success,
            categoryList: state.categoryList
                .where((category) => category.id != event.categoryId)
                .toList(),
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CategorySubmitStatus.failure,
          submitError: e.toString(),
        ),
      );
    }
  }

Future<void> _reset(
  OnCategoryReset event,
  Emitter<CategoryState> emit,
) async {
  emit(CategoryState.initial());
  add(const OnCategoryInitial());
}
}