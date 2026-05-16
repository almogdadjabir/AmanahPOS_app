import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/inventory/data/models/requests/add_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/adjust_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/transfer_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/add_stock_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/expiry_report_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/premium_summary_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_summary_dto.dart';
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

  @override
  Future<Either<String?, AddStockResponseDto>> addStock(AddStockRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/inventory/stock/add/',
      (data) => AddStockResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, AddStockResponseDto>> adjustStock(AdjustStockRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/inventory/stock/adjust/',
      (data) => AddStockResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, bool>> transferStock(TransferStockRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/inventory/stock/transfer/',
      (data) => true,
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, InboundResponseDto>> createInboundTransaction(
    CreateInboundRequestDto request,
  ) {
    return requestHandler.handlePostRequest(
      'api/v1/inventory/inbound/',
      (data) => InboundResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, ExpiryAlertResponseDto>> getExpiryAlerts({
    int page = 1,
    int pageSize = 50,
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/inventory/expiry-alerts/?page=$page&page_size=$pageSize',
      (data) => ExpiryAlertResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, PremiumSummaryData>> getPremiumSummary({String? shopId}) {
    final query = shopId != null ? '?shop_id=$shopId' : '';
    return requestHandler.handleGetRequest(
      'api/v1/inventory/premium-summary/$query',
      (data) => PremiumSummaryData.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, InboundListResponseDto>> getInboundList({
    String? shopId,
    String? vendorId,
    int page = 1,
    int pageSize = 20,
  }) {
    final params = <String>['page=$page', 'page_size=$pageSize'];
    if (shopId != null && shopId.isNotEmpty) params.add('shop_id=$shopId');
    if (vendorId != null && vendorId.isNotEmpty) params.add('vendor_id=$vendorId');
    return requestHandler.handleGetRequest(
      'api/v1/inventory/inbound/?${params.join('&')}',
      (data) => InboundListResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, VendorListResponseDto>> getVendors({
    bool activeOnly = true,
    int pageSize = 200,
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/inventory/vendors/?is_active=$activeOnly&page_size=$pageSize',
      (data) => VendorListResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, VendorData>> getVendorById(String id) {
    return requestHandler.handleGetRequest(
      'api/v1/inventory/vendors/$id/',
      (data) => VendorData.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, VendorData>> createVendor(CreateVendorRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/inventory/vendors/',
      (data) => VendorData.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, VendorData>> updateVendor(String id, UpdateVendorRequestDto request) {
    return requestHandler.handlePatchRequest(
      'api/v1/inventory/vendors/$id/',
      (data) => VendorData.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, bool>> deleteVendor(String id) {
    return requestHandler.handleDeleteRequest(
      'api/v1/inventory/vendors/$id/',
      (data) => true,
    );
  }

  @override
  Future<Either<String?, VendorSummaryData>> getVendorSummary({
    String? shopId,
    String? dateFrom,
    String? dateTo,
  }) {
    final params = <String>[];
    if (shopId != null && shopId.isNotEmpty) params.add('shop_id=$shopId');
    if (dateFrom != null && dateFrom.isNotEmpty) params.add('date_from=$dateFrom');
    if (dateTo != null && dateTo.isNotEmpty) params.add('date_to=$dateTo');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return requestHandler.handleGetRequest(
      'api/v1/inventory/inbound/vendor-summary/$query',
      (data) => VendorSummaryData.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, ExpiryReportResponseDto>> getExpiryReport({
    String status = 'expiring_soon',
    String? shopId,
    int page = 1,
  }) {
    final params = <String>['status=$status', 'page=$page'];
    if (shopId != null && shopId.isNotEmpty) params.add('shop_id=$shopId');
    return requestHandler.handleGetRequest(
      'api/v1/inventory/reports/expiry/?${params.join('&')}',
      (data) => ExpiryReportResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }
}
