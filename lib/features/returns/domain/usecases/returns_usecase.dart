import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/returns/domain/repositories/returns_repository.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:fpdart/fpdart.dart';

class ReturnsUseCase {
  final ReturnsRepository repository;
  ReturnsUseCase({required this.repository});

  Future<Either<String?, SalesHistoryPage>> searchSales({
    required String query,
    int pageSize = 20,
  }) =>
      repository.searchSales(query: query, pageSize: pageSize);

  Future<Either<String?, RefundResponseDto>> processRefund({
    required String saleId,
    required RefundRequestDto request,
  }) =>
      repository.processRefund(saleId: saleId, request: request);
}
