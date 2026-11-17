part of 'pending_sync_bloc.dart';

enum PendingSyncStatus { initial, loading, loaded, syncing, error }

/// Why the last discard / retry did not happen (the screen shows it).
enum PendingSyncFailure {
  /// A sync run claimed the row (it may be on the wire): not discarded.
  discardSending,

  /// The server already confirmed the row: not discarded.
  discardAlreadySynced,

  /// Another account's row (use discard-other-account): not discarded.
  discardOtherScope,

  /// The local write failed ([PendingSyncState.errorMessage] has details).
  actionFailed,
}

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

  /// Last discard / retry refusal or failure; [failureSeq] grows with every
  /// one so the same failure twice is shown twice.
  final PendingSyncFailure? failure;
  final int failureSeq;

  const PendingSyncState({
    this.status = PendingSyncStatus.initial,
    this.rows = const [],
    this.errorMessage,
    this.failure,
    this.failureSeq = 0,
  });

  PendingSyncState withFailure(
    PendingSyncFailure failure,
    String? message, {
    List<PendingSyncRow>? rows,
  }) => PendingSyncState(
    status: rows == null ? status : PendingSyncStatus.loaded,
    rows: rows ?? this.rows,
    errorMessage: message,
    failure: failure,
    failureSeq: failureSeq + 1,
  );

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
      failure: clearError ? null : failure,
      failureSeq: failureSeq,
    );
  }

  @override
  List<Object?> get props => [status, rows, errorMessage, failure, failureSeq];
}
