import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/product_response_dto.dart';
import 'package:amana_pos/features/products/domain/repositories/product_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProductUseCase {
  final ProductRepository repository;

  ProductUseCase({required this.repository});

  Future<Either<String?, CategoryProductsResponseDto>> getCategoryProducts({
    required String categoryId,
    required int page,
    required int pageSize,
  }) => repository.getCategoryProducts(categoryId: categoryId, page: page, pageSize: pageSize);

  Future<Either<String?, CategoryResponseDto>> getCategories() => repository.getCategories();

  Future<Either<String?, ProductListResponseDto>> getProducts({
    required int page,
    int pageSize = 20,
  }) => repository.getProducts(page: page, pageSize: pageSize);

  Future<Either<String?, CategoryProductsResponseDto>> getProductsByCategory({
    required String categoryId,
    required int page,
    int pageSize = 20,
  }) => repository.getProductsByCategory(categoryId: categoryId, page: page, pageSize: pageSize);

}