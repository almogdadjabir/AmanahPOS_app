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

  /// Today's summary from the local sales tables, re-emitted on every local
  /// change (first value straight from SQLite, no network). Null when the
  /// dashboard still reads the REST endpoint (sync engine off).
  Stream<DashboardSummary>? watchDashboardSummary({
    String? businessId,
    String? shopId,
    String? timezone,
    int topSellersLimit = 5,
  });
}
