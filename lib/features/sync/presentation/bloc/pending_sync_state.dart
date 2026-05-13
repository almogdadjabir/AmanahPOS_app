part of 'pending_sync_bloc.dart';

enum PendingSyncStatus { initial, loading, loaded, syncing, error }

class PendingSyncState extends Equatable {
  final PendingSyncStatus status;
  final List<OfflineSaleDto> sales;
  final String? errorMessage;

  const PendingSyncState({
    this.status = PendingSyncStatus.initial,
    this.sales = const [],
    this.errorMessage,
  });

  bool get isLoading => status == PendingSyncStatus.loading;
  bool get isSyncing => status == PendingSyncStatus.syncing;

  PendingSyncState copyWith({
    PendingSyncStatus? status,
    List<OfflineSaleDto>? sales,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PendingSyncState(
      status: status ?? this.status,
      sales: sales ?? this.sales,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, sales, errorMessage];
}
