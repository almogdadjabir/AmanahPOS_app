part of 'expiry_bloc.dart';

enum ExpiryStatus { initial, loading, success, failure }

class ExpiryState extends Equatable {
  final ExpiryStatus          status;
  final List<ExpiryAlertData> alerts;
  final String?               error;

  const ExpiryState({
    this.status = ExpiryStatus.initial,
    this.alerts = const [],
    this.error,
  });

  factory ExpiryState.initial() => const ExpiryState();

  List<ExpiryAlertData> get expired =>
      alerts.where((a) => a.isExpiredSafe).toList();

  List<ExpiryAlertData> get expiringSoon =>
      alerts.where((a) => a.isExpiringSoon).toList();

  ExpiryState copyWith({
    ExpiryStatus?          status,
    List<ExpiryAlertData>? alerts,
    String?                error,
    bool                   clearError = false,
  }) {
    return ExpiryState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      error:  clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, alerts, error];
}
