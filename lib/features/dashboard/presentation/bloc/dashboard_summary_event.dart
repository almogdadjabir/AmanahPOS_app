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

  const OnDashboardSummaryShopChanged({required this.shopId});

  @override
  List<Object?> get props => [shopId];
}

class OnDashboardSummaryReset extends DashboardSummaryEvent {
  const OnDashboardSummaryReset();
}

/// A value from the local (sync engine) summary stream for [key].
class _DashboardLocalSummaryReceived extends DashboardSummaryEvent {
  final DashboardSummary summary;
  final String key;
  final String? businessId;
  final String? shopId;
  final String? timezone;
  final int topSellersLimit;

  const _DashboardLocalSummaryReceived({
    required this.summary,
    required this.key,
    required this.businessId,
    required this.shopId,
    required this.timezone,
    required this.topSellersLimit,
  });

  @override
  List<Object?> get props => [summary, key];
}

class _DashboardLocalSummaryFailed extends DashboardSummaryEvent {
  final String message;
  final String key;

  const _DashboardLocalSummaryFailed({
    required this.message,
    required this.key,
  });

  @override
  List<Object?> get props => [message, key];
}
