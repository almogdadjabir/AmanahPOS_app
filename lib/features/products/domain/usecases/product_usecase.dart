import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/domain/repositories/product_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProductUseCase {
  final ProductRepository repository;

  ProductUseCase({required this.repository});

  Future<Either<String, String>> addProduct(
    AddProductRequestDto request, {
    String? initialQuantity,
    String? shopId,
    String? newCategoryName,
  }) => repository.addProduct(
    request,
    initialQuantity: initialQuantity,
    shopId: shopId,
    newCategoryName: newCategoryName,
  );

  Future<Either<String, Unit>> editProduct(
    String productId,
    UpdateProductRequestDto request,
  ) => repository.editProduct(productId, request);

  Future<Either<String, Unit>> deleteProduct(String productId) =>
      repository.deleteProduct(productId);
}
