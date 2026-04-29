import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/add_product_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/product_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class ProductRepository {
  Future<Either<String?, CategoryProductsResponseDto>> getCategoryProducts({
    required String categoryId,
    required int page,
    required int pageSize,
  });

  Future<Either<String?, CategoryResponseDto>> getCategories();

  Future<Either<String?, ProductListResponseDto>> getProducts({
    required int page,
    int pageSize = 20,
  });

  Future<Either<String?, CategoryProductsResponseDto>> getProductsByCategory({
    required String categoryId,
    required int page,
    int pageSize = 20,
  });
  Future<Either<String?, AddProductResponseDto>> addProduct(AddProductRequestDto request);
}
