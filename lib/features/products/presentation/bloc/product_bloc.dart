import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/product_response_dto.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductUseCase useCase;

  ProductBloc({required this.useCase}) : super(ProductState.initial()) {
    on<OnProductInitial>(_init);
    on<OnProductCategorySelected>(_onCategorySelected);
    on<OnLoadMoreProducts>(_loadMore);
    on<OnToggleProductLayout>(_toggleLayout);
    on<OnAddProduct>(_addProduct);
    on<OnUpdateProduct>(_updateProduct);
    on<OnDeleteProduct>(_deleteProduct);
  }

  Future<void> _init(
      OnProductInitial event,
      Emitter<ProductState> emit,
      ) async {
    if (state.productStatus == ProductStatus.loading ||
        state.productStatus == ProductStatus.success) {
      return;
    }

    emit(state.copyWith(productStatus: ProductStatus.loading));

    try {
      final results = await Future.wait([
        useCase.getCategories(),
        useCase.getProducts(page: 1),
      ]);

      final categoriesResult = results[0] as dynamic;
      final productsResult   = results[1] as dynamic;

      List<CategoryData> categories = [];
      List<ProductData>  products   = [];
      int totalPages = 1;

      categoriesResult.fold(
            (error) {},
            (result) => categories = (result as CategoryResponseDto).data ?? [],
      );

      productsResult.fold(
            (error) => emit(state.copyWith(
          productStatus: ProductStatus.failure,
          responseError: error,
        )),
            (result) {
          final r = result as ProductListResponseDto;
          products   = r.results   ?? [];
          totalPages = r.totalPages ?? 1;
        },
      );

      emit(state.copyWith(
        productStatus: ProductStatus.success,
        categories:    categories,
        products:      products,
        currentPage:   1,
        totalPages:    totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        productStatus: ProductStatus.failure,
        responseError: e.toString(),
      ));
    }
  }

  // ── Category filter selected ───────────────────────────────────────────────
  Future<void> _onCategorySelected(
      OnProductCategorySelected event,
      Emitter<ProductState> emit,
      ) async {
    emit(state.copyWith(
      productStatus:  ProductStatus.loading,
      products:       [],
      currentPage:    1,
      selectedCategoryId: event.categoryId,
      clearCategory:  event.categoryId == null,
    ));

    try {
      final response = event.categoryId == null
          ? await useCase.getProducts(page: 1)
          : await useCase.getProductsByCategory(
          categoryId: event.categoryId!, page: 1);

      response.fold(
            (error) => emit(state.copyWith(
          productStatus: ProductStatus.failure,
          responseError: error,
        )),
            (result) {
          if (event.categoryId == null) {
            final r = result as ProductListResponseDto;
            emit(state.copyWith(
              productStatus: ProductStatus.success,
              products:      r.results   ?? [],
              currentPage:   r.currentPage ?? 1,
              totalPages:    r.totalPages  ?? 1,
            ));
          } else {
            final r = result as CategoryProductsResponseDto;
            emit(state.copyWith(
              productStatus: ProductStatus.success,
              products:      r.products  ?? [],
              currentPage:   r.currentPage ?? 1,
              totalPages:    r.totalPages  ?? 1,
            ));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(
        productStatus: ProductStatus.failure,
        responseError: e.toString(),
      ));
    }
  }

  // ── Load more ─────────────────────────────────────────────────────────────
  Future<void> _loadMore(
      OnLoadMoreProducts event,
      Emitter<ProductState> emit,
      ) async {
    if (!state.hasMorePages) return;
    if (state.productStatus == ProductStatus.loadingMore) return;

    emit(state.copyWith(productStatus: ProductStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = state.selectedCategoryId == null
          ? await useCase.getProducts(page: nextPage)
          : await useCase.getProductsByCategory(
          categoryId: state.selectedCategoryId!, page: nextPage);

      response.fold(
            (error) => emit(state.copyWith(
          productStatus: ProductStatus.failure,
          responseError: error,
        )),
            (result) {
          if (state.selectedCategoryId == null) {
            final r = result as ProductListResponseDto;
            emit(state.copyWith(
              productStatus: ProductStatus.success,
              products: [...state.products, ...?r.results],
              currentPage: r.currentPage ?? nextPage,
              totalPages: r.totalPages  ?? state.totalPages,
            ));
          } else {
            final r = result as CategoryProductsResponseDto;
            emit(state.copyWith(
              productStatus: ProductStatus.success,
              products: [...state.products, ...?r.products],
              currentPage: r.currentPage ?? nextPage,
              totalPages: r.totalPages  ?? state.totalPages,
            ));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(
        productStatus: ProductStatus.failure,
        responseError: e.toString(),
      ));
    }
  }

  void _toggleLayout(OnToggleProductLayout event, Emitter<ProductState> emit) {
    emit(state.copyWith(isGrid: !state.isGrid));
  }

  Future<void> _addProduct(
      OnAddProduct event,
      Emitter<ProductState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: ProductSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.addProduct(event.dto);

      final error   = response.getLeft().toNullable();
      final product = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError:  error,
        ));
        return;
      }

      if (product != null && !emit.isDone) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.success,
          products: [product.data!, ...state.products],
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError:  e.toString(),
        ));
      }
    }
  }

  Future<void> _updateProduct(
      OnUpdateProduct event,
      Emitter<ProductState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: ProductSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.editProduct(
        event.productId,
        event.dto,
      );

      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError: error,
        ));
        return;
      }

      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.success,
          submitError: null,
          productStatus: ProductStatus.initial,
          products: [],
        ));

        add(const OnProductInitial());
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError: e.toString(),
        ));
      }
    }
  }

  Future<void> _deleteProduct(
      OnDeleteProduct event,
      Emitter<ProductState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: ProductSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.deactivateProduct(event.productId,);

      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError: error,
        ));
        return;
      }

      final updatedProducts = state.products
          .where((product) => product.id != event.productId)
          .toList();

      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.success,
          submitError: null,
          products: updatedProducts,
        ));

        add(const OnProductInitial());
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(
          submitStatus: ProductSubmitStatus.failure,
          submitError: e.toString(),
        ));
      }
    }
  }
}