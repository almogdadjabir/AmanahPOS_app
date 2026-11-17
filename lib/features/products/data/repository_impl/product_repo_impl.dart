import 'package:amana_pos/core/sync/catalog_result.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/features/products/domain/repositories/product_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Local-only: every write goes through [ProductService] (row + outbox in
/// one transaction). No REST client.
class ProductRepoImpl extends ProductRepository {
  ProductRepoImpl({required ProductService Function() service})
    : _service = service;

  /// Lazy so the sync core is only constructed on the first write.
  final ProductService Function() _service;

  @override
  Future<Either<String, String>> addProduct(
    AddProductRequestDto request, {
    String? initialQuantity,
    String? shopId,
    String? newCategoryName,
  }) => catalogResult(
    () => _service().create(
      request,
      initialQuantity: initialQuantity,
      shopId: shopId,
      newCategoryName: newCategoryName,
    ),
  );

  @override
  Future<Either<String, Unit>> editProduct(
    String productId,
    UpdateProductRequestDto request,
  ) => catalogResult(() async {
    await _service().update(productId, request);
    return unit;
  });

  @override
  Future<Either<String, Unit>> deleteProduct(String productId) =>
      catalogResult(() async {
        await _service().delete(productId);
        return unit;
      });
}
