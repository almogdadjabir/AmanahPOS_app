part of 'category_bloc.dart';

enum CategoryProductsStatus { initial, loading, loadingMore, success, failure }
enum CategoryStatus { initial, loading, success, failure }
enum CategorySubmitStatus { idle, loading, success, failure }

class CategoryState extends Equatable {
  final CategoryStatus categoryStatus;
  final CategorySubmitStatus submitStatus;
  final List<CategoryData> categoryList;
  final String? responseError;
  final String? submitError;

  final CategoryProductsStatus productsStatus;
  final List<ProductData> products;
  final int currentPage;
  final int totalPages;
  final String? productsError;

  const CategoryState({
    this.categoryStatus = CategoryStatus.initial,
    this.submitStatus = CategorySubmitStatus.idle,
    this.categoryList = const [],
    this.responseError,
    this.submitError,
    this.productsStatus = CategoryProductsStatus.initial,
    this.products = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.productsError,
  });

  bool get hasMorePages => currentPage < totalPages;

  factory CategoryState.initial() => const CategoryState();

  CategoryState copyWith({
    CategoryStatus? categoryStatus,
    CategorySubmitStatus? submitStatus,
    List<CategoryData>? categoryList,
    String? responseError,
    String? submitError,
    CategoryProductsStatus? productsStatus,
    List<ProductData>? products,
    int? currentPage,
    int? totalPages,
    String? productsError,
  }) {
    return CategoryState(
      categoryStatus: categoryStatus  ?? this.categoryStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      categoryList: categoryList ?? this.categoryList,
      responseError: responseError,
      submitError: submitError,
      productsStatus: productsStatus ?? this.productsStatus,
      products: products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      productsError: productsError,
    );
  }

  @override
  List<Object?> get props => [
    categoryStatus, submitStatus, categoryList,
    responseError, submitError, productsStatus,
    products, currentPage, totalPages, productsError,
  ];
}