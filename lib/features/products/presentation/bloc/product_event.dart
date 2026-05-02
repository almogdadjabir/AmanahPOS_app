part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
}

class OnProductInitial extends ProductEvent {
  const OnProductInitial();
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
  const OnAddProduct({required this.dto});
  @override List<Object?> get props => [dto];
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