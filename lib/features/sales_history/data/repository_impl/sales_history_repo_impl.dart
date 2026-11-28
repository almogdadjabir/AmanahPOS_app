import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/features/sales_history/data/local/local_sales_history.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:fpdart/fpdart.dart';

class SalesHistoryRepoImpl extends SalesHistoryRepository {
  SalesHistoryRepoImpl({
    required RequestHandler requestHandler,
    required NetworkMonitor networkMonitor,
    required LocalSalesHistory localHistory,
    Future<String?> Function()? businessTimezone,
  }) : _requestHandler = requestHandler,
       _networkMonitor = networkMonitor,
       _localHistory = localHistory,
       _businessTimezone = businessTimezone;

  final RequestHandler _requestHandler;
  final NetworkMonitor _networkMonitor;

  /// The list reads the local `sales` tables only (pending, rejected and
  /// pulled sales alike), online or not.
  final LocalSalesHistory _localHistory;

  /// Business timezone for date filters (null: the BE default zone).
  final Future<String?> Function()? _businessTimezone;

  @override
  Future<Either<String?, SalesHistoryPage>> getSalesPage({
    required int page,
    int pageSize = 20,
    String? search,
    String? shopId,
    String? status,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool onlyUnsynced = false,
  }) async {
    try {
      return Right(
        await _localHistory.page(
          page: page,
          pageSize: pageSize,
          search: search,
          shopId: shopId,
          status: status,
          paymentMethod: paymentMethod,
          dateFrom: dateFrom,
          dateTo: dateTo,
          onlyUnsynced: onlyUnsynced,
          timezone: await _businessTimezone?.call(),
        ),
      );
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String?, SalesReport>> getSalesReport({
    required DateTime from,
    required DateTime to,
    String? shopId,
    String? timezone,
  }) async {
    try {
      final isOnline = await _networkMonitor.isOnline;
      if (!isOnline) {
        return const Left(null);
      }

      final uri = _buildReportUri(
        from: from,
        to: to,
        shopId: shopId,
        timezone: timezone,
      );

      final result = await _requestHandler.handleGetRequest(uri, (data) {
        final body = data as Map<String, dynamic>;
        final inner = (body['data'] as Map<String, dynamic>?) ?? body;
        return SalesReportDto.fromJson(inner);
      });

      return result.map((dto) => dto.toDomain());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String?, SaleHistoryItem>> getSaleById(String saleId) async {
    try {
      final sale = await _localHistory.byId(saleId);
      return sale == null ? const Left('Sale not found') : Right(sale);
    } catch (e) {
      return Left(e.toString());
    }
  }

  String _buildReportUri({
    required DateTime from,
    required DateTime to,
    String? shopId,
    String? timezone,
  }) {
    final buf = StringBuffer(
      'api/v1/sales/reports/?date_from=${BusinessDay.restDateParam(from)}&date_to=${BusinessDay.restDateParam(to)}',
    );
    // The reports endpoint uses 'shop_id'; the list endpoint uses 'shop'.
    if (shopId?.isNotEmpty == true) buf.write('&shop_id=$shopId');
    if (timezone?.isNotEmpty == true) {
      buf.write('&timezone=${Uri.encodeComponent(timezone!)}');
    }
    return buf.toString();
  }
}
