
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class InventoryRepoImpl extends InventoryRepository {
  final RequestHandler requestHandler;
  InventoryRepoImpl(this.requestHandler);

  @override
  Future<Either<String?, StockResponseDto>> getStock({
    required int page,
    int pageSize = 20,
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/inventory/stock/?page=$page&page_size=$pageSize',
          (data) => StockResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

}
