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