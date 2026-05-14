part of 'dashboard_summary_bloc.dart';

abstract class DashboardSummaryEvent extends Equatable {
  const DashboardSummaryEvent();

  @override
  List<Object?> get props => [];
}

class OnDashboardSummaryStarted extends DashboardSummaryEvent {
  final String? businessId;
  final String? shopId;
  final DateTime? date;
  final String? timezone;
  final int topSellersLimit;
  final bool forceRefresh;

  const OnDashboardSummaryStarted({
    this.businessId,
    this.shopId,
    this.date,
    this.timezone,
    this.topSellersLimit = 5,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    businessId,
    shopId,
    date,
    timezone,
    topSellersLimit,
    forceRefresh,
  ];
}

class OnDashboardSummaryRefreshRequested extends DashboardSummaryEvent {
  final String? businessId;
  final String? shopId;
  final DateTime? date;
  final String? timezone;
  final int? topSellersLimit;

  const OnDashboardSummaryRefreshRequested({
    this.businessId,
    this.shopId,
    this.date,
    this.timezone,
    this.topSellersLimit,
  });

  @override
  List<Object?> get props => [
    businessId,
    shopId,
    date,
    timezone,
    topSellersLimit,
  ];
}

class OnDashboardSummaryShopChanged extends DashboardSummaryEvent {
  final String? shopId;

  const OnDashboardSummaryShopChanged({
    required this.shopId,
  });

  @override
  List<Object?> get props => [shopId];
}

class OnDashboardSummaryReset extends DashboardSummaryEvent {
  const OnDashboardSummaryReset();
}