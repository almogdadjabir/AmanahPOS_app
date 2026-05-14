part of 'dashboard_summary_bloc.dart';

enum DashboardSummaryStatus {
  initial,
  loading,
  refreshing,
  success,
  failure,
}

class DashboardSummaryState extends Equatable {
  final DashboardSummaryStatus status;
  final DashboardSummary? summary;
  final String? businessId;
  final String? shopId;
  final DateTime? date;
  final String? timezone;
  final int topSellersLimit;
  final String? errorMessage;

  const DashboardSummaryState({
    this.status = DashboardSummaryStatus.initial,
    this.summary,
    this.businessId,
    this.shopId,
    this.date,
    this.timezone,
    this.topSellersLimit = 5,
    this.errorMessage,
  });

  bool get isLoading => status == DashboardSummaryStatus.loading;

  bool get isRefreshing => status == DashboardSummaryStatus.refreshing;

  bool get hasData => summary != null;

  DashboardSummaryState copyWith({
    DashboardSummaryStatus? status,
    DashboardSummary? summary,
    String? businessId,
    String? shopId,
    DateTime? date,
    String? timezone,
    int? topSellersLimit,
    String? errorMessage,
  }) {
    return DashboardSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      businessId: businessId ?? this.businessId,
      shopId: shopId ?? this.shopId,
      date: date ?? this.date,
      timezone: timezone ?? this.timezone,
      topSellersLimit: topSellersLimit ?? this.topSellersLimit,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    businessId,
    shopId,
    date,
    timezone,
    topSellersLimit,
    errorMessage,
  ];
}