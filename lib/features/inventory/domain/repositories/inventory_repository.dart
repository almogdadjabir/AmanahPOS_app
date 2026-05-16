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
import 'package:fpdart/fpdart.dart';

abstract class InventoryRepository {
  Future<Either<String?, StockResponseDto>> getStock({
    required int page,
    int pageSize = 20,
  });

  Future<Either<String?, AddStockResponseDto>> addStock(AddStockRequestDto request);
  Future<Either<String?, AddStockResponseDto>> adjustStock(AdjustStockRequestDto request);
  Future<Either<String?, bool>> transferStock(TransferStockRequestDto request);
  Future<Either<String?, InboundResponseDto>> createInboundTransaction(CreateInboundRequestDto request);

  Future<Either<String?, ExpiryAlertResponseDto>> getExpiryAlerts({
    int page = 1,
    int pageSize = 50,
  });

  Future<Either<String?, PremiumSummaryData>> getPremiumSummary({String? shopId});

  Future<Either<String?, InboundListResponseDto>> getInboundList({
    String? shopId,
    String? vendorId,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<String?, VendorListResponseDto>> getVendors({
    bool activeOnly = true,
    int pageSize = 200,
  });

  Future<Either<String?, VendorData>> getVendorById(String id);
  Future<Either<String?, VendorData>> createVendor(CreateVendorRequestDto request);
  Future<Either<String?, VendorData>> updateVendor(String id, UpdateVendorRequestDto request);
  Future<Either<String?, bool>> deleteVendor(String id);

  Future<Either<String?, VendorSummaryData>> getVendorSummary({
    String? shopId,
    String? dateFrom,
    String? dateTo,
  });

  Future<Either<String?, ExpiryReportResponseDto>> getExpiryReport({
    String status = 'expiring_soon',
    String? shopId,
    int page = 1,
  });
}
