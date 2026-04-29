part of 'product_bloc.dart';

enum ProductStatus { initial, loading, loadingMore, success, failure }

class ProductState extends Equatable {
  final ProductStatus productStatus;
  final List<ProductData> products;
  final List<CategoryData> categories;
  final String? selectedCategoryId;
  final int currentPage;
  final int totalPages;
  final String? responseError;
  final bool isGrid;

  const ProductState({
    this.productStatus = ProductStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.currentPage = 1,
    this.totalPages = 1,
    this.responseError,
    this.isGrid = true,
  });

  factory ProductState.initial() => const ProductState();

  bool get hasMorePages => currentPage < totalPages;

  ProductState copyWith({
    ProductStatus? productStatus,
    List<ProductData>? products,
    List<CategoryData>? categories,
    String? selectedCategoryId,
    bool clearCategory = false,
    int? currentPage,
    int? totalPages,
    String? responseError,
    bool? isGrid,
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
      responseError: responseError,
      isGrid: isGrid ?? this.isGrid,
    );
  }

  @override
  List<Object?> get props => [
    productStatus, products, categories,
    selectedCategoryId, currentPage, totalPages,
    responseError, isGrid,
  ];
}