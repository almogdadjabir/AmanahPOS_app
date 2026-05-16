part of 'expiry_report_bloc.dart';

abstract class ExpiryReportEvent extends Equatable {
  const ExpiryReportEvent();
}

class OnExpiryReportStarted extends ExpiryReportEvent {
  const OnExpiryReportStarted();
  @override List<Object?> get props => [];
}

class OnExpiryReportLoadMore extends ExpiryReportEvent {
  const OnExpiryReportLoadMore();
  @override List<Object?> get props => [];
}

class OnExpiryReportFilterChanged extends ExpiryReportEvent {
  final ExpiryReportFilter filter;
  const OnExpiryReportFilterChanged(this.filter);
  @override List<Object?> get props => [filter];
}

class OnExpiryReportReset extends ExpiryReportEvent {
  const OnExpiryReportReset();
  @override List<Object?> get props => [];
}
