import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase {
  final DashboardRepository repository;

  const GetDashboardSummaryUseCase({
    required this.repository,
  });

  Future<DashboardSummary> call({
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int topSellersLimit = 5,
    bool forceRefresh = false,
  }) {
    return repository.getDashboardSummary(
      businessId: businessId,
      shopId: shopId,
      date: date,
      timezone: timezone,
      topSellersLimit: topSellersLimit,
      forceRefresh: forceRefresh,
    );
  }
}