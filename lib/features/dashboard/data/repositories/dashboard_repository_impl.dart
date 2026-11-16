import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:amana_pos/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:amana_pos/features/dashboard/data/local/local_dashboard_queries.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;

  /// The local sales tables are the source of truth for today's summary;
  /// the REST dashboard is not called for it. The remote data source stays
  /// for [getDashboardSummary] (future debug checksum comparison).
  final LocalDashboardQueries localQueries;

  /// The signed-in user's id when they are a cashier (the endpoint computes
  /// the shift block for cashiers only), else null.
  final String? Function()? shiftCashierId;

  const DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localQueries,
    this.shiftCashierId,
  });

  @override
  Stream<DashboardSummary>? watchDashboardSummary({
    String? businessId,
    String? shopId,
    String? timezone,
    int topSellersLimit = 5,
  }) {
    return _watchLocal(
      localQueries,
      businessId: businessId,
      shopId: shopId,
      timezone: timezone,
      topSellersLimit: topSellersLimit,
    );
  }

  Stream<DashboardSummary> _watchLocal(
    LocalDashboardQueries queries, {
    required String? businessId,
    required String? shopId,
    required String? timezone,
    required int topSellersLimit,
  }) async* {
    // The app has no business timezone/currency of its own: use the last
    // values the server reported for this business, else the BE defaults.
    final meta = await localDataSource.lastKnownMeta(businessId: businessId);
    yield* queries.watchToday(
      shopId: shopId,
      timezone: timezone ?? meta.timezone ?? BusinessDay.defaultZone,
      currency: meta.currency ?? 'SDG',
      businessId: businessId,
      shiftCashierId: shiftCashierId?.call(),
      topSellersLimit: topSellersLimit,
    );
  }

  @override
  Future<DashboardSummary> getDashboardSummary({
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int topSellersLimit = 5,
    bool forceRefresh = false,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateKey = _formatDate(targetDate);

    try {
      final remoteDto = await remoteDataSource.getDashboardSummary(
        businessId: businessId,
        shopId: shopId,
        date: targetDate,
        timezone: timezone,
        topSellersLimit: topSellersLimit,
      );

      await localDataSource.saveSummary(
        dto: remoteDto,
        businessId: businessId,
        shopId: shopId,
        date: dateKey,
      );

      return remoteDto.toEntity(source: DashboardSummarySource.remote);
    } catch (_) {
      final cachedDto = await localDataSource.getCachedSummary(
        businessId: businessId,
        shopId: shopId,
        date: dateKey,
      );

      if (cachedDto != null) {
        return cachedDto.toEntity(source: DashboardSummarySource.cache);
      } else {
        return DashboardSummary.empty(
          date: dateKey,
          timezone: timezone ?? 'Africa/Khartoum',
          currency: 'SDG',
          businessId: businessId,
          shopId: shopId,
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
