part of 'category_bloc.dart';

enum CategoryStatus { initial, loading, success, failure }
enum CategorySubmitStatus { idle, loading, success, failure }

class CategoryState extends Equatable {
  final CategoryStatus categoryStatus;
  final CategorySubmitStatus submitStatus;
  final List<CategoryData> categoryList;
  final String? responseError;
  final String? submitError;

  const CategoryState({
    this.categoryStatus = CategoryStatus.initial,
    this.submitStatus = CategorySubmitStatus.idle,
    this.categoryList = const [],
    this.responseError,
    this.submitError,
  });

  factory CategoryState.initial() => const CategoryState(
    categoryStatus: CategoryStatus.initial,
    submitStatus: CategorySubmitStatus.idle,
    categoryList: [],
  );

  CategoryState copyWith({
    CategoryStatus? categoryStatus,
    CategorySubmitStatus? submitStatus,
    List<CategoryData>? categoryList,
    String? responseError,
    String? submitError,
  }) {
    return CategoryState(
      categoryStatus: categoryStatus ?? this.categoryStatus,
      submitStatus:   submitStatus   ?? this.submitStatus,
      categoryList:   categoryList   ?? this.categoryList,
      responseError:  responseError,
      submitError:    submitError,
    );
  }

  @override
  List<Object?> get props => [
    categoryStatus, submitStatus,
    categoryList, responseError, submitError,
  ];
}