import 'dart:async';

import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/product_response_dto.dart';
import 'package:amana_pos/features/products/domain/repositories/product_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProductRepoImpl extends ProductRepository {
  final RequestHandler requestHandler;
  ProductRepoImpl(this.requestHandler);


  @override
  Future<Either<String?, CategoryProductsResponseDto>> getCategoryProducts({
    required String categoryId,
    required int page,
    required int pageSize,
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/products/categories/$categoryId/products/?page=$page&page_size=$pageSize',
          (data) => CategoryProductsResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, CategoryResponseDto>> getCategories() {
    return requestHandler.handleGetRequest(
      'api/v1/products/categories/',
          (data) => CategoryResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, ProductListResponseDto>> getProducts({
    required int page,
    int pageSize = 20,
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/products/?page=$page&page_size=$pageSize',
          (data) => ProductListResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, CategoryProductsResponseDto>> getProductsByCategory({
    required String categoryId,
    required int page,
    int pageSize = 20,
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/products/categories/$categoryId/products/?page=$page&page_size=$pageSize',
          (data) => CategoryProductsResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

}
