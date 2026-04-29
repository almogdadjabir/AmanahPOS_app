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

  CategoryBloc({required this.useCase, required this.productUseCase}) : super(CategoryState.initial()) {
    on<OnCategoryInitial>(_init);
    on<OnAddCategory>(_addCategory);
    on<OnEditCategory>(_editCategory);
    on<OnToggleCategoryActive>(_toggleActive);
    on<OnLoadCategoryProducts>(_loadProducts);
    on<OnLoadMoreCategoryProducts>(_loadMoreProducts);
    on<OnDeleteCategory>(_deleteCategory);
  }

  Future<void> _init(
      OnCategoryInitial event,
      Emitter<CategoryState> emit,
      ) async {
    if (state.categoryStatus == CategoryStatus.loading ||
        state.categoryStatus == CategoryStatus.success) return;

    emit(state.copyWith(categoryStatus: CategoryStatus.loading));

    try {
      final response = await useCase.getCategories();
      response.fold(
            (error) => emit(state.copyWith(
          categoryStatus: CategoryStatus.failure,
          responseError: error,
        )),
            (result) => emit(state.copyWith(
          categoryStatus: CategoryStatus.success,
          categoryList: result.data ?? [],
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        categoryStatus: CategoryStatus.failure,
        responseError: e.toString(),
      ));
    }
  }

  Future<void> _addCategory(
      OnAddCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(state.copyWith(
        submitStatus: CategorySubmitStatus.loading, submitError: null));

    try {
      final payload = AddCategoryRequestDto(
        name: event.name,
        description: event.description,
      );
      final response = await useCase.addCategory(payload);

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: CategorySubmitStatus.failure,
          submitError: error,
        )),
            (newCategory) {
          // If it's a subcategory, append into parent's children
          if (event.parentId != null) {
            final updated = state.categoryList.map((c) {
              if (c.id != event.parentId) return c;
              return c.copyWith(
                  children: [...?c.children, newCategory.data!]);
            }).toList();
            emit(state.copyWith(
              submitStatus: CategorySubmitStatus.success,
              categoryList: updated,
            ));
          } else {
            emit(state.copyWith(
              submitStatus: CategorySubmitStatus.success,
              categoryList: [...state.categoryList, newCategory.data!],
            ));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: CategorySubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _editCategory(
      OnEditCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(state.copyWith(
        submitStatus: CategorySubmitStatus.loading, submitError: null));

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
            (error) => emit(state.copyWith(
          submitStatus: CategorySubmitStatus.failure,
          submitError: error,
        )),
            (_) => emit(state.copyWith(
          submitStatus: CategorySubmitStatus.success,
          // Patch in top-level and inside children
          categoryList: _patchCategory(
            state.categoryList,
            event.categoryId,
                (c) => c.copyWith(
                name: event.name, description: event.description),
          ),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: CategorySubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _toggleActive(
      OnToggleCategoryActive event,
      Emitter<CategoryState> emit,
      ) async {
    emit(state.copyWith(
        submitStatus: CategorySubmitStatus.loading, submitError: null));

    // try {
    //   final response = await useCase.toggleCategoryActive(
    //       event.categoryId, event.isActive);
    //
    //   response.fold(
    //         (error) => emit(state.copyWith(
    //       submitStatus: CategorySubmitStatus.failure,
    //       submitError: error,
    //     )),
    //         (_) => emit(state.copyWith(
    //       submitStatus: CategorySubmitStatus.success,
    //       categoryList: _patchCategory(
    //         state.categoryList,
    //         event.categoryId,
    //             (c) => c.copyWith(isActive: event.isActive),
    //       ),
    //     )),
    //   );
    // } catch (e) {
    //   emit(state.copyWith(
    //     submitStatus: CategorySubmitStatus.failure,
    //     submitError: e.toString(),
    //   ));
    // }
  }

  // ── Recursively patch a category by id anywhere in the tree ────────────────
  List<CategoryData> _patchCategory(
      List<CategoryData> list,
      String id,
      CategoryData Function(CategoryData) patch,
      ) {
    return list.map((c) {
      if (c.id == id) return patch(c);
      if (c.children != null && c.children!.isNotEmpty) {
        return c.copyWith(
            children: _patchCategory(c.children!, id, patch));
      }
      return c;
    }).toList();
  }

  Future<void> _loadProducts(
      OnLoadCategoryProducts event,
      Emitter<CategoryState> emit,
      ) async {
    // Reset list when loading page 1 fresh
    emit(state.copyWith(
      productsStatus: CategoryProductsStatus.loading,
      products: [],
      currentPage: 1,
      productsError: null,
    ));

    try {
      final response = await productUseCase.getCategoryProducts(
        categoryId: event.categoryId,
        page: 1,
        pageSize: 20,
      );

      response.fold(
            (error) => emit(state.copyWith(
          productsStatus: CategoryProductsStatus.failure,
          productsError: error,
        )),
            (result) => emit(state.copyWith(
          productsStatus: CategoryProductsStatus.success,
          products:    result.products ?? [],
          currentPage: result.currentPage ?? 1,
          totalPages:  result.totalPages ?? 1,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        productsStatus: CategoryProductsStatus.failure,
        productsError: e.toString(),
      ));
    }
  }

  Future<void> _loadMoreProducts(
      OnLoadMoreCategoryProducts event,
      Emitter<CategoryState> emit,
      ) async {
    if (!state.hasMorePages) return;
    if (state.productsStatus == CategoryProductsStatus.loadingMore) return;

    emit(state.copyWith(
        productsStatus: CategoryProductsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await productUseCase.getCategoryProducts(
        categoryId: event.categoryId,
        page: nextPage,
        pageSize: 20,
      );

      response.fold(
            (error) => emit(state.copyWith(
          productsStatus: CategoryProductsStatus.failure,
          productsError: error,
        )),
            (result) => emit(state.copyWith(
          productsStatus: CategoryProductsStatus.success,
          // Append to existing list
          products:    [...state.products, ...?result.products],
          currentPage: result.currentPage ?? nextPage,
          totalPages:  result.totalPages  ?? state.totalPages,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        productsStatus: CategoryProductsStatus.failure,
        productsError: e.toString(),
      ));
    }
  }



  Future<void> _deleteCategory(
      OnDeleteCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: CategorySubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.deleteCategory(event.categoryId);

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: CategorySubmitStatus.failure,
          submitError: error,
        )),
            (_) => emit(state.copyWith(
          submitStatus: CategorySubmitStatus.success,
          categoryList: state.categoryList
              .where((c) => c.id != event.categoryId)
              .toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: CategorySubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }
}