import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_list_response_dto.dart';
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
  }) async {
    try {
      final isOnline = await _networkMonitor.isOnline;

      // Offline items are only prepended on page 1 (most-recent position).
      final offlineItems = page == 1 ? await _getOfflineItems() : <SaleHistoryItem>[];

      if (!isOnline) {
        return Right(SalesHistoryPage(
          items: page == 1 ? offlineItems : [],
          hasMore: false,
        ));
      }

      final uri = _buildUri(page: page, pageSize: pageSize, search: search, shopId: shopId);

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
          );
        }

        return SalesHistoryPage(items: onlineItems, hasMore: dto.next != null);
      });
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
  }) {
    final buf = StringBuffer('api/v1/sales/?page=$page&page_size=$pageSize');
    if (search?.isNotEmpty == true) buf.write('&search=${Uri.encodeComponent(search!)}');
    if (shopId?.isNotEmpty == true) buf.write('&shop=$shopId');
    return buf.toString();
  }

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