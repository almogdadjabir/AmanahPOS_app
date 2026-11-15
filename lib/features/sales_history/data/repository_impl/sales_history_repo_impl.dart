import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_list_response_dto.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:fpdart/fpdart.dart';

class SalesHistoryRepoImpl extends SalesHistoryRepository {
  SalesHistoryRepoImpl({
    required RequestHandler requestHandler,
    required OfflineDb offlineDb,
    required NetworkMonitor networkMonitor,
  })  : _requestHandler = requestHandler,
        _offlineDb = offlineDb,
        _networkMonitor = networkMonitor;

  final RequestHandler  _requestHandler;
  final OfflineDb _offlineDb;
  final NetworkMonitor  _networkMonitor;

  @override
  Future<Either<String?, SalesHistoryPage>> getSalesPage({
    required int page,
    int pageSize = 20,
    String?  search,
    String?  shopId,
    String? status,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool onlyUnsynced = false,
  }) async {
    try {
      final isOnline = await _networkMonitor.isOnline;

      // Offline items are only prepended on page 1 (most-recent position).
      // Sales that are not on the server yet can only match filters that
      // do not depend on server state, so apply them locally.
      var offlineItems = page == 1 ? await _getOfflineItems() : <SaleHistoryItem>[];
      offlineItems = offlineItems
          .where((o) => _offlineMatches(
                o,
                search: search,
                status: status,
                paymentMethod: paymentMethod,
                dateFrom: dateFrom,
                dateTo: dateTo,
              ))
          .toList();

      if (onlyUnsynced || !isOnline) {
        return Right(SalesHistoryPage(
          items: page == 1 ? offlineItems : [],
          hasMore: false,
          totalCount: page == 1 ? offlineItems.length : 0,
        ));
      }

      final uri = _buildUri(
        page: page,
        pageSize: pageSize,
        search: search,
        shopId: shopId,
        status: status,
        paymentMethod: paymentMethod,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      final result = await _requestHandler.handleGetRequest(
        uri,
            (data) => SalesListResponseDto.fromJson(data as Map<String, dynamic>),
      );

      return result.map((dto) {
        final onlineItems = dto.results.map(SaleHistoryItem.fromDto).toList();

        if (page == 1) {
          final syncedIds = onlineItems.map((i) => i.clientSaleId).toSet();
          final uniqueOffline = offlineItems.where((o) => !syncedIds.contains(o.clientSaleId));
          return SalesHistoryPage(
            items: [...uniqueOffline, ...onlineItems],
            hasMore: dto.next != null,
            totalCount: dto.count + uniqueOffline.length,
          );
        }

        return SalesHistoryPage(
          items: onlineItems,
          hasMore: dto.next != null,
          totalCount: dto.count,
        );
      });
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

      final result = await _requestHandler.handleGetRequest(
        uri,
        (data) {
          final body = data as Map<String, dynamic>;
          final inner = (body['data'] as Map<String, dynamic>?) ?? body;
          return SalesReportDto.fromJson(inner);
        },
      );

      return result.map((dto) => dto.toDomain());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String?, SaleHistoryItem>> getSaleById(String saleId) async {
    try {
      final result = await _requestHandler.handleGetRequest(
        'api/v1/sales/$saleId/',
            (data) => SaleDto.fromJson(data as Map<String, dynamic>),
      );
      return result.map(SaleHistoryItem.fromDto);
    } catch (e) {
      return Left(e.toString());
    }
  }


  String _buildUri({
    required int page,
    required int pageSize,
    String? search,
    String? shopId,
    String? status,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    final buf = StringBuffer('api/v1/sales/?page=$page&page_size=$pageSize');
    if (search?.isNotEmpty == true) buf.write('&search=${Uri.encodeComponent(search!)}');
    if (shopId?.isNotEmpty == true) buf.write('&shop=$shopId');
    if (status?.isNotEmpty == true) buf.write('&status=$status');
    if (paymentMethod?.isNotEmpty == true) buf.write('&payment_method=$paymentMethod');
    if (dateFrom != null) buf.write('&date_from=${_formatDate(dateFrom)}');
    if (dateTo != null) buf.write('&date_to=${_formatDate(dateTo)}');
    return buf.toString();
  }

  bool _offlineMatches(
    SaleHistoryItem o, {
    String? search,
    String? status,
    String? paymentMethod,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    // A sale that is not on the server cannot be completed/refunded yet.
    if (status?.isNotEmpty == true) return false;
    if (paymentMethod?.isNotEmpty == true && o.paymentMethod != paymentMethod) {
      return false;
    }
    final q = search?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty && !o.displayRef.toLowerCase().contains(q)) return false;
    final day = DateTime(o.createdAt.toLocal().year, o.createdAt.toLocal().month,
        o.createdAt.toLocal().day);
    if (dateFrom != null &&
        day.isBefore(DateTime(dateFrom.year, dateFrom.month, dateFrom.day))) {
      return false;
    }
    if (dateTo != null &&
        day.isAfter(DateTime(dateTo.year, dateTo.month, dateTo.day))) {
      return false;
    }
    return true;
  }

  String _buildReportUri({
    required DateTime from,
    required DateTime to,
    String? shopId,
    String? timezone,
  }) {
    final buf = StringBuffer(
      'api/v1/sales/reports/?date_from=${_formatDate(from)}&date_to=${_formatDate(to)}',
    );
    // The reports endpoint uses 'shop_id'; the list endpoint uses 'shop'.
    if (shopId?.isNotEmpty == true) buf.write('&shop_id=$shopId');
    if (timezone?.isNotEmpty == true) buf.write('&timezone=${Uri.encodeComponent(timezone!)}');
    return buf.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<SaleHistoryItem>> _getOfflineItems() async {
    try {
      final db = await _offlineDb.database;
      final saleRows = await db.query(
        'pending_sales',
        where: "status != 'synced'",
        orderBy: 'created_at DESC',
        limit: 50,
      );

      final items = <SaleHistoryItem>[];
      for (final row in saleRows) {
        final clientSaleId = row['client_sale_id']?.toString() ?? '';
        final itemRows = await db.query(
          'pending_sale_items',
          where: 'client_sale_id = ?',
          whereArgs: [clientSaleId],
        );
        items.add(SaleHistoryItem.fromOfflineRow(row, itemRows));
      }
      return items;
    } catch (_) {
      return [];
    }
  }
}