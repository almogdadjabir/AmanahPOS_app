import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_sync_response_dto.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/data/model/requests/create_sale_request_dto.dart';

class PosRemoteDataSource {
  PosRemoteDataSource(this._requestHandler);

  final RequestHandler _requestHandler;

  Future<PosSubmitResult> createSale(CreateSaleRequestDto dto) async {
    final response = await _requestHandler.handlePostRequest<Map<String, dynamic>>(
      'api/v1/sales/',
          (data) => Map<String, dynamic>.from(data as Map),
      data: dto.toJson(),
    );

    return response.match(
          (error) => throw Exception(error ?? 'Failed to create sale'),
          (data) {
        final saleId = data['id']?.toString();
        return PosSubmitResult.synced(saleId);
      },
    );
  }

  Future<List<OfflineSaleSyncResult>> syncSales(
      List<Map<String, dynamic>> sales,
      ) async {
    final response =
    await _requestHandler.handlePostRequest<OfflineSaleSyncResponseDto>(
      'api/v1/sales/offline-sync/',
      OfflineSaleSyncResponseDto.fromJson,
      data: {
        'sales': sales,
      },
    );

    return response.match(
          (error) => throw Exception(error ?? 'Failed to sync offline sales'),
          (data) => data.results,
    );
  }
}