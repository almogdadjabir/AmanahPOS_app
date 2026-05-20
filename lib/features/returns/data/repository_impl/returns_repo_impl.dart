import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/returns/domain/repositories/returns_repository.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_list_response_dto.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:fpdart/fpdart.dart';

class ReturnsRepoImpl extends ReturnsRepository {
  ReturnsRepoImpl({required RequestHandler requestHandler})
      : _requestHandler = requestHandler;

  final RequestHandler _requestHandler;

  @override
  Future<Either<String?, SalesHistoryPage>> searchSales({
    required String query,
    int pageSize = 20,
  }) async {
    final encoded = Uri.encodeComponent(query);
    final result = await _requestHandler.handleGetRequest(
      'api/v1/sales/?search=$encoded&page_size=$pageSize&status=completed',
      (data) => SalesListResponseDto.fromJson(data as Map<String, dynamic>),
    );
    return result.map((dto) => SalesHistoryPage(
          items: dto.results.map(SaleHistoryItem.fromDto).toList(),
          hasMore: dto.next != null,
        ));
  }

  @override
  Future<Either<String?, RefundResponseDto>> processRefund({
    required String saleId,
    required RefundRequestDto request,
  }) {
    return _requestHandler.handlePostRequest(
      'api/v1/sales/$saleId/refund/',
      (data) => RefundResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }
}
