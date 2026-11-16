part of 'pending_sync_bloc.dart';

enum PendingSyncStatus { initial, loading, loaded, syncing, error }

/// One outbox row prepared for display.
class PendingSyncRow extends Equatable {
  final OutboxEntry entry;

  /// Locale-free label data: sale receipt / local receipt number, or product
  /// name for stock rows. Empty when none could be resolved (UI shows the id).
  final String label;

  /// Sale total (net amount) when resolvable from the local sale row.
  final String? total;

  /// Row belongs to a different `userId|tenantId` than the signed-in session.
  final bool otherScope;

  /// For `blocked` rows: the row they wait behind.
  final PendingSyncRow? waitsBehind;

  const PendingSyncRow({
    required this.entry,
    required this.label,
    this.total,
    required this.otherScope,
    this.waitsBehind,
  });

  @override
  List<Object?> get props => [
    entry.mutationId,
    entry.status,
    entry.errorCode,
    entry.errorMessage,
    label,
    total,
    otherScope,
    waitsBehind?.entry.mutationId,
  ];
}

class PendingSyncState extends Equatable {
  final PendingSyncStatus status;
  final List<PendingSyncRow> rows;
  final String? errorMessage;

  const PendingSyncState({
    this.status = PendingSyncStatus.initial,
    this.rows = const [],
    this.errorMessage,
  });

  bool get isLoading => status == PendingSyncStatus.loading;
  bool get isSyncing => status == PendingSyncStatus.syncing;

  PendingSyncState copyWith({
    PendingSyncStatus? status,
    List<PendingSyncRow>? rows,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PendingSyncState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, rows, errorMessage];
}
