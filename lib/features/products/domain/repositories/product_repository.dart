import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:fpdart/fpdart.dart';

/// Product writes (Phase 3): local row + outbox through `ProductService`,
/// never REST. Reads come from SQLite (`OfflineLocalCache`); the sync feed
/// is the only source of server changes. Left = a user-facing message.
abstract class ProductRepository {
  /// Returns the new product id. [initialQuantity] + [shopId]: an opening
  /// `stock.add` in the same write. [newCategoryName]: when the dto has no
  /// category, that category is reused or created in the same write.
  Future<Either<String, String>> addProduct(
    AddProductRequestDto request, {
    String? initialQuantity,
    String? shopId,
    String? newCategoryName,
  });

  Future<Either<String, Unit>> editProduct(
    String productId,
    UpdateProductRequestDto request,
  );

  /// Soft delete (hidden at once) until the server confirms it.
  Future<Either<String, Unit>> deleteProduct(String productId);
}
