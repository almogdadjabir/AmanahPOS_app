import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:fpdart/fpdart.dart';

abstract class ReturnsRepository {
  Future<Either<String?, SalesHistoryPage>> searchSales({
    required String query,
    int pageSize,
  });

  Future<Either<String?, RefundResponseDto>> processRefund({
    required String saleId,
    required RefundRequestDto request,
  });
}
