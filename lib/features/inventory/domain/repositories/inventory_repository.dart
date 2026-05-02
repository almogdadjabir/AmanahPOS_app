import 'package:amana_pos/features/inventory/data/models/requests/add_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/adjust_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/transfer_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/add_stock_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class InventoryRepository {

  Future<Either<String?, StockResponseDto>> getStock({
    required int page,
    int pageSize = 20,
  });

  Future<Either<String?, AddStockResponseDto>> addStock(AddStockRequestDto request);
  Future<Either<String?, AddStockResponseDto>> adjustStock(AdjustStockRequestDto request);
  Future<Either<String?, bool>> transferStock(TransferStockRequestDto request);
}
