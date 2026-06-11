import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:fpdart/fpdart.dart';

class SalesHistoryUseCase {
  final SalesHistoryRepository repository;
  SalesHistoryUseCase({required this.repository});

  Future<Either<String?, SalesHistoryPage>> getSalesPage({
    required int page,
    int pageSize = 20,
    String? search,
    String? shopId,
  }) =>
      repository.getSalesPage(
        page: page,
        pageSize: pageSize,
        search: search,
        shopId: shopId,
      );

  Future<Either<String?, SaleHistoryItem>> getSaleById(String saleId) =>
      repository.getSaleById(saleId);

  Future<Either<String?, SalesReport>> getSalesReport({
    required DateTime from,
    required DateTime to,
    String? shopId,
    String? timezone,
  }) => repository.getSalesReport(
    from: from,
    to: to,
    shopId: shopId,
    timezone: timezone,
  );
}
