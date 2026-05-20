import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:fpdart/fpdart.dart';

abstract class SalesHistoryRepository {
  Future<Either<String?, SalesHistoryPage>> getSalesPage({
    required int page,
    int pageSize,
    String? search,
    String? shopId,
  });

  Future<Either<String?, SaleHistoryItem>> getSaleById(String saleId);
}