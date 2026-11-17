part of 'product_bloc.dart';

enum ProductStatus { initial, loading, loadingMore, success, failure }

enum ProductSubmitStatus { idle, loading, success, failure }

enum ProductQueryStatus { idle, loading, success, failure }

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

  /// Legacy flag (REST era). Always false: SQLite is the only source.
  final bool isFromCache;

  /// "Waiting to sync" / "Sync failed" markers of the product rows.
  final CatalogSyncMarks syncMarks;

  /// Search / inactive-only query, kept apart from [products].
  final ProductQueryStatus queryStatus;
  final List<ProductData> queryResults;

  /// True while [OnProductsLoadAll] is still fetching pages.
  final bool loadingAll;

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
    this.queryStatus = ProductQueryStatus.idle,
    this.queryResults = const [],
    this.loadingAll = false,
    this.syncMarks = CatalogSyncMarks.none,
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
    ProductQueryStatus? queryStatus,
    List<ProductData>? queryResults,
    bool? loadingAll,
    CatalogSyncMarks? syncMarks,
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
      queryStatus: queryStatus ?? this.queryStatus,
      queryResults: queryResults ?? this.queryResults,
      loadingAll: loadingAll ?? this.loadingAll,
      syncMarks: syncMarks ?? this.syncMarks,
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
    queryStatus,
    queryResults,
    loadingAll,
    syncMarks,
  ];
}
