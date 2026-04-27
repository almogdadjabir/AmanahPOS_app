part of 'dashboard_bloc.dart';

enum DashboardStatus {
  initial,
  loading,
  success,
  failure,
}

class DashboardState extends Equatable {
  final bool isLoading;
  final String? responseError;
  final DashboardStatus dashboardStatus;

  const DashboardState({
    this.isLoading = false,
    this.responseError,
    this.dashboardStatus = DashboardStatus.initial,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      responseError: null,
      dashboardStatus: DashboardStatus.initial,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    String? responseError,
    DashboardStatus? dashboardStatus,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      responseError: responseError,
      dashboardStatus: dashboardStatus ?? this.dashboardStatus,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    responseError,
    dashboardStatus,
  ];
}
