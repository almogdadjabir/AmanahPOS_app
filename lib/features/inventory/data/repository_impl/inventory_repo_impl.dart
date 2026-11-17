import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/sync/catalog_result.dart';
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
import 'package:amana_pos/features/inventory/data/models/responses/vendor_summary_dto.dart';
import 'package:amana_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:fpdart/fpdart.dart';

class InventoryRepoImpl extends InventoryRepository {
  final RequestHandler requestHandler;
  InventoryRepoImpl(
    this.requestHandler, {
    required StockService Function() stockService,
    VendorService Function()? vendorService,
    Future<bool> Function()? expiryAddSynced,
  }) : _stockService = stockService,
       _vendorService = vendorService,
       _expiryAddSynced = expiryAddSynced;

  /// True when the server accepts `expiry_date` on `stock.add` (capability
  /// `stock_add_expiry`). Null / false: a dated add uses the online REST add.
  final Future<bool> Function()? _expiryAddSynced;

  /// Lazy, like [_stockService]; the only vendor writer.
  final VendorService Function()? _vendorService;

  /// Lazy so the sync core is only constructed on first stock edit.
  /// Add / remove / adjust / inbound are written locally + outbox (never the
  /// network here). Transfer stays on REST (not in Phase 1).
  final StockService Function() _stockService;

  Future<Either<String?, T>> _local<T>(
    Future<T> Function(StockService) f,
  ) async {
    try {
      return Right(await f(_stockService()));
    } on StockValidationException catch (e) {
      return Left(e.message);
    } catch (_) {
      return const Left('Failed to save the stock change. Please try again.');
    }
  }

  AddStockResponseDto _stockResult(
    String productId,
    String shopId,
    String quantity,
  ) => AddStockResponseDto(
    success: true,
    data: StockData(product: productId, shop: shopId, quantity: quantity),
  );

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
  Future<Either<String?, AddStockResponseDto>> addStock(
    AddStockRequestDto request,
  ) async {
    final expiry = request.expiryDate?.trim();
    final dated = expiry != null && expiry.isNotEmpty;
    if (dated && !await _serverTakesDatedAdds()) {
      return _addWithExpiryOnline(request);
    }
    return _local(
      (s) async => _stockResult(
        request.productId,
        request.shopId,
        await s.add(
          productId: request.productId,
          shopId: request.shopId,
          delta: request.quantity,
          reason: request.reference,
          expiryDate: dated ? expiry : null,
        ),
      ),
    );
  }

  Future<bool> _serverTakesDatedAdds() async {
    try {
      return await (_expiryAddSynced?.call() ?? Future.value(false));
    } catch (_) {
      return false;
    }
  }

  Future<Either<String?, AddStockResponseDto>> _restAdd(
    AddStockRequestDto request,
  ) => requestHandler.handlePostRequest(
    'api/v1/inventory/stock/add/',
    (data) => AddStockResponseDto.fromJson(data as Map<String, dynamic>),
    data: request.toJson(),
  );

  /// Fallback for a server WITHOUT capability `stock_add_expiry` (its
  /// `stock.add` would drop the date and create no batch): a dated add uses
  /// the REST endpoint, which creates the ProductBatch. The caller (bloc)
  /// refuses it while offline. On
  /// success the local base is raised by exactly the added quantity; the
  /// next pull brings the absolute server quantity.
  Future<Either<String?, AddStockResponseDto>> _addWithExpiryOnline(
    AddStockRequestDto request,
  ) async {
    final result = await _restAdd(request);
    if (result.isLeft()) return result;
    try {
      await _stockService().applyOnlineAdd(
        productId: request.productId,
        shopId: request.shopId,
        quantity: request.quantity,
      );
    } catch (_) {
      // The server already has it; local stock catches up on the next pull.
    }
    return result;
  }

  @override
  Future<Either<String?, AddStockResponseDto>> removeStock({
    required String productId,
    required String shopId,
    required String quantity,
    String? reason,
  }) async {
    return _local(
      (s) async => _stockResult(
        productId,
        shopId,
        await s.remove(
          productId: productId,
          shopId: shopId,
          delta: quantity,
          reason: reason,
        ),
      ),
    );
  }

  @override
  Future<Either<String?, AddStockResponseDto>> adjustStock(
    AdjustStockRequestDto request,
  ) {
    final productId = request.productId ?? '';
    final shopId = request.shopId ?? '';
    return _local(
      (s) async => _stockResult(
        productId,
        shopId,
        await s.adjustTo(
          productId: productId,
          shopId: shopId,
          newQuantity: request.newQuantity ?? '',
          reason: request.notes,
        ),
      ),
    );
  }

  @override
  Future<Either<String?, bool>> transferStock(
    TransferStockRequestDto request,
  ) async {
    final result = await requestHandler.handlePostRequest(
      'api/v1/inventory/stock/transfer/',
      (data) => true,
      data: request.toJson(),
    );
    if (result.isLeft()) return result;
    // REST only (not a Phase 1 sync op): mirror it on the local base so the
    // displayed stock is right until the next pull brings the server values.
    try {
      await _stockService().applyOnlineTransfer(
        productId: request.productId ?? '',
        fromShopId: request.fromShop ?? '',
        toShopId: request.toShop ?? '',
        quantity: request.quantity ?? '',
      );
    } catch (_) {
      // The server already has it; local stock catches up on the next pull.
    }
    return result;
  }

  @override
  Future<Either<String?, InboundResponseDto>> createInboundTransaction(
    CreateInboundRequestDto request,
  ) {
    return _local(
      (s) async => InboundResponseDto(
        success: true,
        data: await s.receiveInbound(request),
      ),
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
  Future<Either<String?, PremiumSummaryData>> getPremiumSummary({
    String? shopId,
  }) {
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
    if (vendorId != null && vendorId.isNotEmpty) {
      params.add('vendor_id=$vendorId');
    }
    return requestHandler.handleGetRequest(
      'api/v1/inventory/inbound/?${params.join('&')}',
      (data) => InboundListResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  // Vendors (Phase 3): local row + outbox through VendorService, never
  // REST; the list is read from SQLite (OfflineLocalCache.getVendors).

  VendorService _vendors() {
    final f = _vendorService;
    if (f == null) throw StateError('InventoryRepoImpl has no VendorService');
    return f();
  }

  @override
  Future<Either<String?, String>> createVendor(
    CreateVendorRequestDto request,
  ) => catalogResult(() => _vendors().create(request));

  @override
  Future<Either<String?, Unit>> updateVendor(
    String id,
    UpdateVendorRequestDto request,
  ) => catalogResult(() async {
    await _vendors().update(id, request);
    return unit;
  });

  @override
  Future<Either<String?, Unit>> deleteVendor(String id) =>
      catalogResult(() async {
        await _vendors().delete(id);
        return unit;
      });

  @override
  Future<Either<String?, VendorSummaryData>> getVendorSummary({
    String? shopId,
    String? dateFrom,
    String? dateTo,
  }) {
    final params = <String>[];
    if (shopId != null && shopId.isNotEmpty) params.add('shop_id=$shopId');
    if (dateFrom != null && dateFrom.isNotEmpty) {
      params.add('date_from=$dateFrom');
    }
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
