part of 'product_bloc.dart';

enum ProductStatus { initial, loading, loadingMore, success, failure }
enum ProductSubmitStatus { idle, loading, success, failure }

class ProductState extends Equatable {
  final ProductStatus productStatus;
  final List<ProductData> products;
  final List<CategoryData> categories;
  final String? selectedCategoryId;
  final int currentPage;
  final int totalPages;
  final String? responseError;
  final bool isGrid;
  final ProductSubmitStatus submitStatus;
  final String? submitError;

  /// True when data came from SQLite/offline cache.
  final bool isFromCache;

  const ProductState({
    this.productStatus = ProductStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.currentPage = 1,
    this.totalPages = 1,
    this.responseError,
    this.isGrid = true,
    this.submitStatus = ProductSubmitStatus.idle,
    this.submitError,
    this.isFromCache = false,
  });

  factory ProductState.initial() => const ProductState();

  bool get hasMorePages => !isFromCache && currentPage < totalPages;

  ProductState copyWith({
    ProductStatus? productStatus,
    List<ProductData>? products,
    List<CategoryData>? categories,
    String? selectedCategoryId,
    bool clearCategory = false,
    int? currentPage,
    int? totalPages,
    String? responseError,
    bool clearResponseError = false,
    bool? isGrid,
    ProductSubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
    bool? isFromCache,
  }) {
    return ProductState(
      productStatus: productStatus ?? this.productStatus,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      responseError: clearResponseError ? null : responseError,
      isGrid: isGrid ?? this.isGrid,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError ? null : submitError,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
    productStatus,
    products,
    categories,
    selectedCategoryId,
    currentPage,
    totalPages,
    responseError,
    isGrid,
    submitStatus,
    submitError,
    isFromCache,
  ];
}