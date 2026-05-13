import 'package:amana_pos/features/inventory/data/models/requests/add_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/adjust_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/transfer_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/add_stock_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class InventoryUseCase {
  final InventoryRepository repository;

  InventoryUseCase({required this.repository});


  Future<Either<String?, StockResponseDto>> getStock({
    required int page,
    int pageSize = 20,
  }) => repository.getStock(page: page, pageSize: pageSize);

  Future<Either<String?, AddStockResponseDto>> addStock(AddStockRequestDto request)
  => repository.addStock(request);

  Future<Either<String?, AddStockResponseDto>> adjustStock(AdjustStockRequestDto request)
  => repository.adjustStock(request);

  Future<Either<String?, bool>> transferStock(TransferStockRequestDto request)
  => repository.transferStock(request);

  Future<Either<String?, ExpiryAlertResponseDto>> getExpiryAlerts({
    int page = 1,
    int pageSize = 50,
  }) => repository.getExpiryAlerts(page: page, pageSize: pageSize);
}