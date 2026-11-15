part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
}

class OnProductInitial extends ProductEvent {
  final bool force;
  const OnProductInitial({this.force = false});
  @override List<Object?> get props => [];
}

class OnProductCategorySelected extends ProductEvent {
  // null = All
  final String? categoryId;
  const OnProductCategorySelected({this.categoryId});
  @override List<Object?> get props => [categoryId];
}

/// Search and/or inactive-only query. Results land in
/// [ProductState.queryResults] and never touch the main product list.
/// An empty [search] with [inactiveOnly] false clears the query.
class OnProductQuery extends ProductEvent {
  final String search;
  final bool inactiveOnly;
  const OnProductQuery({this.search = '', this.inactiveOnly = false});
  @override List<Object?> get props => [search, inactiveOnly];
}

/// Loads every remaining page so client-side filters (Low / Out of stock)
/// see the whole catalog.
class OnProductsLoadAll extends ProductEvent {
  const OnProductsLoadAll();
  @override List<Object?> get props => [];
}

/// Creates a category from inside the product form. The new category is
/// appended to [ProductState.categories] and handed back through
/// [completer] (null on failure).
class OnCreateProductCategory extends ProductEvent {
  final String name;
  final Completer<CategoryData?> completer;
  const OnCreateProductCategory({required this.name, required this.completer});
  @override List<Object?> get props => [name, completer];
}

class OnLoadMoreProducts extends ProductEvent {
  const OnLoadMoreProducts();
  @override List<Object?> get props => [];
}

class OnToggleProductLayout extends ProductEvent {
  const OnToggleProductLayout();
  @override List<Object?> get props => [];
}

class OnAddProduct extends ProductEvent {
  final AddProductRequestDto dto;

  /// Raw opening-stock quantity string. Null/empty = no opening stock.
  final String? openingStock;

  /// Shop the opening stock is recorded against. Required when
  /// [openingStock] is set; ignored otherwise.
  final String? openingShopId;

  const OnAddProduct({
    required this.dto,
    this.openingStock,
    this.openingShopId,
  });

  @override
  List<Object?> get props => [dto, openingStock, openingShopId];
}

class OnAddProductWithAutoCategory extends ProductEvent {
  final AddProductRequestDto dto;

  /// Raw opening-stock quantity string. Null/empty = no opening stock.
  final String? openingStock;

  /// Shop the opening stock is recorded against. Required when
  /// [openingStock] is set; ignored otherwise.
  final String? openingShopId;

  const OnAddProductWithAutoCategory({
    required this.dto,
    this.openingStock,
    this.openingShopId,
  });

  @override
  List<Object?> get props => [dto, openingStock, openingShopId];
}

class OnUpdateProduct extends ProductEvent {
  final String productId;
  final UpdateProductRequestDto dto;

  const OnUpdateProduct({
    required this.productId,
    required this.dto,
  });

  @override
  List<Object?> get props => [productId, dto];
}

class OnDeleteProduct extends ProductEvent {
  final String productId;

  const OnDeleteProduct({
    required this.productId,
  });

  @override
  List<Object?> get props => [productId];
}

class OnProductsSoldLocally extends ProductEvent {
  final Map<String, int> soldQuantities;

  const OnProductsSoldLocally({
    required this.soldQuantities,
  });

  @override
  List<Object?> get props => [soldQuantities];
}

class OnProductReset extends ProductEvent {
  const OnProductReset();

  @override
  List<Object?> get props => throw UnimplementedError();
}