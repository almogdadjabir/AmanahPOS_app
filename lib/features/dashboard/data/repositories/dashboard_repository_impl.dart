import 'package:amana_pos/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:amana_pos/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;

  const DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

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

    DashboardSummary baseSummary;

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

      baseSummary = remoteDto.toEntity(
        source: DashboardSummarySource.remote,
      );
    } catch (_) {
      final cachedDto = await localDataSource.getCachedSummary(
        businessId: businessId,
        shopId: shopId,
        date: dateKey,
      );

      if (cachedDto != null) {
        baseSummary = cachedDto.toEntity(
          source: DashboardSummarySource.cache,
        );
      } else {
        baseSummary = DashboardSummary.empty(
          date: dateKey,
          timezone: timezone ?? 'Africa/Khartoum',
          currency: 'SDG',
          businessId: businessId,
          shopId: shopId,
        );
      }
    }

    final pendingDelta = await localDataSource.getPendingSalesDelta(
      shopId: shopId,
      date: targetDate,
    );

    return baseSummary.mergePendingSales(pendingDelta);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}