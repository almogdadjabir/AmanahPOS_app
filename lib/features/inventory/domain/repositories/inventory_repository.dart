import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class InventoryRepository {

  Future<Either<String?, StockResponseDto>> getStock({
    required int page,
    int pageSize = 20,
  });
}
