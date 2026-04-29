import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryUseCase useCase;

  CategoryBloc({required this.useCase}) : super(CategoryState.initial()) {
    on<OnCategoryInitial>(_init);
    on<OnAddCategory>(_addCategory);
    on<OnEditCategory>(_editCategory);
    on<OnToggleCategoryActive>(_toggleActive);
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

    // try {
    //   final response = await useCase.addCategory(
    //     name:        event.name,
    //     description: event.description,
    //     parentId:    event.parentId,
    //   );
    //
    //   response.fold(
    //         (error) => emit(state.copyWith(
    //       submitStatus: CategorySubmitStatus.failure,
    //       submitError: error,
    //     )),
    //         (newCategory) {
    //       // If it's a subcategory, append into parent's children
    //       if (event.parentId != null) {
    //         final updated = state.categoryList.map((c) {
    //           if (c.id != event.parentId) return c;
    //           return c.copyWith(
    //               children: [...?c.children, newCategory]);
    //         }).toList();
    //         emit(state.copyWith(
    //           submitStatus: CategorySubmitStatus.success,
    //           categoryList: updated,
    //         ));
    //       } else {
    //         emit(state.copyWith(
    //           submitStatus: CategorySubmitStatus.success,
    //           categoryList: [...state.categoryList, newCategory],
    //         ));
    //       }
    //     },
    //   );
    // } catch (e) {
    //   emit(state.copyWith(
    //     submitStatus: CategorySubmitStatus.failure,
    //     submitError: e.toString(),
    //   ));
    // }
  }

  Future<void> _editCategory(
      OnEditCategory event,
      Emitter<CategoryState> emit,
      ) async {
    emit(state.copyWith(
        submitStatus: CategorySubmitStatus.loading, submitError: null));

    // try {
    //   final response = await useCase.editCategory(
    //     event.categoryId,
    //     name:        event.name,
    //     description: event.description,
    //   );
    //
    //   response.fold(
    //         (error) => emit(state.copyWith(
    //       submitStatus: CategorySubmitStatus.failure,
    //       submitError: error,
    //     )),
    //         (_) => emit(state.copyWith(
    //       submitStatus: CategorySubmitStatus.success,
    //       // Patch in top-level and inside children
    //       categoryList: _patchCategory(
    //         state.categoryList,
    //         event.categoryId,
    //             (c) => c.copyWith(
    //             name: event.name, description: event.description),
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
}