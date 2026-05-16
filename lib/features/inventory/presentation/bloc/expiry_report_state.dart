part of 'expiry_report_bloc.dart';

enum ExpiryReportStatus { initial, loading, loadingMore, success, failure }
enum ExpiryReportFilter { expiringSoon, expired, all }

class ExpiryReportState extends Equatable {
  final ExpiryReportStatus status;
  final List<ExpiryReportItem> items;
  final ExpiryReportFilter filter;
  final int currentPage;
  final int totalPages;
  final String? responseError;

  const ExpiryReportState({
    this.status = ExpiryReportStatus.initial,
    this.items = const [],
    this.filter = ExpiryReportFilter.expiringSoon,
    this.currentPage = 1,
    this.totalPages = 1,
    this.responseError,
  });

  factory ExpiryReportState.initial() => const ExpiryReportState();

  bool get hasMorePages => currentPage < totalPages;

  ExpiryReportState copyWith({
    ExpiryReportStatus? status,
    List<ExpiryReportItem>? items,
    ExpiryReportFilter? filter,
    int? currentPage,
    int? totalPages,
    String? responseError,
    bool clearResponseError = false,
  }) {
    return ExpiryReportState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      responseError: clearResponseError ? null : responseError ?? this.responseError,
    );
  }

  @override
  List<Object?> get props => [status, items, filter, currentPage, totalPages, responseError];
}
