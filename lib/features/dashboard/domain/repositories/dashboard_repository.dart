import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getDashboardSummary({
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int topSellersLimit = 5,
    bool forceRefresh = false,
  });
}