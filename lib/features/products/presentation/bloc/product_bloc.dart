import 'dart:async';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/product_response_dto.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductUseCase useCase;
  final OfflineLocalCache offlineLocalCache;

  ProductBloc({
    required this.useCase,
    required this.offlineLocalCache,
  }) : super(ProductState.initial()) {
    on<OnProductInitial>(_init);
    on<OnProductCategorySelected>(_onCategorySelected);
    on<OnLoadMoreProducts>(_loadMore);
    on<OnToggleProductLayout>(_toggleLayout);
    on<OnAddProduct>(_addProduct);
    on<OnUpdateProduct>(_updateProduct);
    on<OnDeleteProduct>(_deleteProduct);
    on<OnProductsSoldLocally>(_productsSoldLocally);
  }

  Future<void> _init(
      OnProductInitial event,
      Emitter<ProductState> emit,
      ) async {
    if (state.productStatus == ProductStatus.loading) return;

    var emittedCachedData = false;

    try {
      final cachedProducts = await offlineLocalCache.getProducts();
      final cachedCategories = await offlineLocalCache.getCategories();

      if (cachedProducts.isNotEmpty || cachedCategories.isNotEmpty) {
        emittedCachedData = true;

        emit(
          state.copyWith(
            productStatus: ProductStatus.success,
            products: cachedProducts,
            categories: cachedCategories,
            currentPage: 1,
            totalPages: 1,
            isFromCache: true,
            clearResponseError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            productStatus: ProductStatus.loading,
            currentPage: 1,
            totalPages: 1,
            products: [],
            categories: [],
            isFromCache: false,
            clearResponseError: true,
          ),
        );
      }

      final responses = await Future.wait([
        useCase.getProducts(page: 1),
        useCase.getCategories(),
      ]);

      final productsResponse =
      responses[0] as Either<String?, ProductListResponseDto>;
      final categoriesResponse =
      responses[1] as Either<String?, CategoryResponseDto>;

      final productsError = productsResponse.getLeft().toNullable();
      final categoriesError = categoriesResponse.getLeft().toNullable();

      if (productsError != null || categoriesError != null) {
        if (emittedCachedData) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.success,
              responseError: productsError ?? categoriesError,
              isFromCache: true,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            productStatus: ProductStatus.failure,
            responseError: productsError ?? categoriesError,
            isFromCache: false,
          ),
        );
        return;
      }

      final productsResult = productsResponse.getRight().toNullable();
      final categoriesResult = categoriesResponse.getRight().toNullable();

      final freshProducts = productsResult?.results ?? [];
      final freshCategories = categoriesResult?.data ?? [];

      await offlineLocalCache.saveProductsToCache(freshProducts);
      await offlineLocalCache.saveCategoriesToCache(freshCategories);

      final normalizedProducts = await offlineLocalCache.getProducts();
      final normalizedCategories = await offlineLocalCache.getCategories();

      if (!emit.isDone) {
        emit(
          state.copyWith(
            productStatus: ProductStatus.success,
            products: normalizedProducts,
            categories: normalizedCategories,
            currentPage: productsResult?.currentPage ?? 1,
            totalPages: productsResult?.totalPages ?? 1,
            isFromCache: false,
            clearResponseError: true,
          ),
        );
      }
    } catch (e) {
      if (emittedCachedData) {
        emit(
          state.copyWith(
            productStatus: ProductStatus.success,
            responseError: e.toString(),
            isFromCache: true,
          ),
        );
        return;
      }

      if (!emit.isDone) {
        emit(
          state.copyWith(
            productStatus: ProductStatus.failure,
            responseError: e.toString(),
            isFromCache: false,
          ),
        );
      }
    }
  }

  Future<void> _onCategorySelected(
      OnProductCategorySelected event,
      Emitter<ProductState> emit,
      ) async {
    final categoryId = event.categoryId;
    var emittedCachedData = false;

    try {
      final cachedProducts = await offlineLocalCache.getProducts(
        categoryId: categoryId,
      );

      if (cachedProducts.isNotEmpty) {
        emittedCachedData = true;

        emit(
          state.copyWith(
            productStatus: ProductStatus.success,
            products: cachedProducts,
            currentPage: 1,
            totalPages: 1,
            selectedCategoryId: categoryId,
            clearCategory: categoryId == null,
            isFromCache: true,
            clearResponseError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            productStatus: ProductStatus.loading,
            products: [],
            currentPage: 1,
            totalPages: 1,
            selectedCategoryId: categoryId,
            clearCategory: categoryId == null,
            isFromCache: false,
            clearResponseError: true,
          ),
        );
      }

      final response = categoryId == null
          ? await useCase.getProducts(page: 1)
          : await useCase.getProductsByCategory(
        categoryId: categoryId,
        page: 1,
      );

      final error = response.getLeft().toNullable();

      if (error != null) {
        if (emittedCachedData) {
          if (!emit.isDone) {
            emit(
              state.copyWith(
                productStatus: ProductStatus.success,
                responseError: error,
                isFromCache: true,
              ),
            );
          }
          return;
        }

        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.failure,
              responseError: error,
              isFromCache: false,
            ),
          );
        }
        return;
      }

      final result = response.getRight().toNullable();
      if (result == null) return;

      if (categoryId == null) {
        final r = result as ProductListResponseDto;
        final freshProducts = r.results ?? [];

        await offlineLocalCache.saveProductsToCache(freshProducts);

        final normalizedProducts = await offlineLocalCache.getProducts();

        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.success,
              products: normalizedProducts,
              currentPage: r.currentPage ?? 1,
              totalPages: r.totalPages ?? 1,
              isFromCache: false,
              clearResponseError: true,
            ),
          );
        }
      } else {
        final r = result as CategoryProductsResponseDto;
        final freshProducts = r.products ?? [];

        await offlineLocalCache.saveProductsToCache(freshProducts);

        final normalizedProducts = await offlineLocalCache.getProducts(
          categoryId: categoryId,
        );

        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.success,
              products: normalizedProducts,
              currentPage: r.currentPage ?? 1,
              totalPages: r.totalPages ?? 1,
              isFromCache: false,
              clearResponseError: true,
            ),
          );
        }
      }
    } catch (e) {
      if (emittedCachedData) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.success,
              responseError: e.toString(),
              isFromCache: true,
            ),
          );
        }
        return;
      }

      if (!emit.isDone) {
        emit(
          state.copyWith(
            productStatus: ProductStatus.failure,
            responseError: e.toString(),
            isFromCache: false,
          ),
        );
      }
    }
  }

  Future<void> _loadMore(
      OnLoadMoreProducts event,
      Emitter<ProductState> emit,
      ) async {
    if (state.isFromCache) return;
    if (!state.hasMorePages) return;
    if (state.productStatus == ProductStatus.loadingMore) return;

    emit(state.copyWith(productStatus: ProductStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;

      final response = state.selectedCategoryId == null
          ? await useCase.getProducts(page: nextPage)
          : await useCase.getProductsByCategory(
        categoryId: state.selectedCategoryId!,
        page: nextPage,
      );

      final error = response.getLeft().toNullable();

      if (error != null) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.failure,
              responseError: error,
            ),
          );
        }
        return;
      }

      final result = response.getRight().toNullable();
      if (result == null) return;

      if (state.selectedCategoryId == null) {
        final r = result as ProductListResponseDto;
        final freshProducts = r.results ?? [];

        await offlineLocalCache.saveProductsToCache(freshProducts);

        final normalizedProducts = await offlineLocalCache.getProducts();

        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.success,
              products: normalizedProducts,
              currentPage: r.currentPage ?? nextPage,
              totalPages: r.totalPages ?? state.totalPages,
              isFromCache: false,
              clearResponseError: true,
            ),
          );
        }
      } else {
        final r = result as CategoryProductsResponseDto;
        final freshProducts = r.products ?? [];

        await offlineLocalCache.saveProductsToCache(freshProducts);

        final normalizedProducts = await offlineLocalCache.getProducts(
          categoryId: state.selectedCategoryId,
        );

        if (!emit.isDone) {
          emit(
            state.copyWith(
              productStatus: ProductStatus.success,
              products: normalizedProducts,
              currentPage: r.currentPage ?? nextPage,
              totalPages: r.totalPages ?? state.totalPages,
              isFromCache: false,
              clearResponseError: true,
            ),
          );
        }
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            productStatus: ProductStatus.failure,
            responseError: e.toString(),
          ),
        );
      }
    }
  }

  void _toggleLayout(
      OnToggleProductLayout event,
      Emitter<ProductState> emit,
      ) {
    emit(state.copyWith(isGrid: !state.isGrid));
  }

  Future<void> _addProduct(
      OnAddProduct event,
      Emitter<ProductState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: ProductSubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final response = await useCase.addProduct(event.dto);

      final error = response.getLeft().toNullable();
      final product = response.getRight().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      if (product?.data != null && !emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.success,
            products: [product!.data!, ...state.products],
          ),
        );
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.failure,
            submitError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _updateProduct(
      OnUpdateProduct event,
      Emitter<ProductState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: ProductSubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final response = await useCase.editProduct(
        event.productId,
        event.dto,
      );

      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.success,
            clearSubmitError: true,
          ),
        );

        add(const OnProductInitial());
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.failure,
            submitError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(
      OnDeleteProduct event,
      Emitter<ProductState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: ProductSubmitStatus.loading,
        clearSubmitError: true,
      ),
    );

    try {
      final response = await useCase.deactivateProduct(event.productId);

      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      final updatedProducts = state.products
          .where((product) => product.id != event.productId)
          .toList();

      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.success,
            clearSubmitError: true,
            products: updatedProducts,
          ),
        );

        add(const OnProductInitial());
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            submitStatus: ProductSubmitStatus.failure,
            submitError: e.toString(),
          ),
        );
      }
    }
  }

  void _productsSoldLocally(
      OnProductsSoldLocally event,
      Emitter<ProductState> emit,
      ) {
    if (event.soldQuantities.isEmpty) return;

    final updatedProducts = state.products.map((product) {
      final productId = product.id;
      if (productId == null) return product;

      final soldQty = event.soldQuantities[productId];
      if (soldQty == null || soldQty <= 0) return product;

      final currentStock = product.stockLevel ?? 0;
      final nextStock = currentStock - soldQty;

      return product.copyWith(
        stockLevel: nextStock < 0 ? 0 : nextStock,
      );
    }).toList(growable: false);

    emit(state.copyWith(products: updatedProducts));
  }
}