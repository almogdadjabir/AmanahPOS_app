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

}