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

  /// "Merge into existing" was refused (the row changed meanwhile).
  mergeRefused,

  /// "Edit and retry": no saved edit, nothing was sent again.
  editNotSaved,

  /// Discard refused: other changes wait on this create (I3 / R7).
  discardHasDependents,

  /// Discard refused: the create may already be on the server (M8).
  discardMayBeOnServer,
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

  /// Name of the existing row a `conflict_unique` create collided with
  /// (when it is local), for the merge dialog.
  final String? conflictLabel;

  /// For an open catalog create: how many changes wait on it
  /// ([CatalogConflictService.dependentsOfCreate]). Discard is not offered
  /// while any do (fix-wave I3, ruling R7).
  final int dependents;

  /// A dependency this row names no longer exists on this device (no create
  /// row, no local row): sending it records it without that link (a sale
  /// without its product). Retry asks first; "Retry all" skips it.
  final bool missingDependency;

  /// The local catalog row is marked `local_stale` (a discarded change
  /// could not be reverted); the next pull replaces it (T8/9 concern 5).
  final bool stale;

  const PendingSyncRow({
    required this.entry,
    required this.label,
    this.total,
    required this.otherScope,
    this.waitsBehind,
    this.conflictLabel,
    this.dependents = 0,
    this.missingDependency = false,
    this.stale = false,
  });

  /// A product / category / vendor row.
  bool get isCatalog =>
      CatalogConflictService.tableOf.containsKey(entry.entity);

  /// "Merge into existing" is offered (keys off `conflict_entity_id`).
  bool get canMerge => !otherScope && CatalogConflictService.canMerge(entry);

  /// "Discard" is offered: own row, and not a catalog create other changes
  /// wait on.
  bool get canDiscard =>
      !otherScope && !(isCatalog && entry.op == 'create' && dependents > 0);

  /// "Edit and retry" is offered: the server refused this catalog change
  /// itself (not a cascade of another failure) and the row is not a delete.
  bool get canEditRetry =>
      !otherScope &&
      isCatalog &&
      entry.status == OutboxStatus.rejected &&
      entry.op != 'delete' &&
      entry.errorCode != 'dependency_failed';

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
    entry.errorEntityId,
    conflictLabel,
    dependents,
    missingDependency,
    stale,
  ];
}

/// A parked (failed) image upload of the current scope.
class PendingUploadRow extends Equatable {
  final String entity;
  final String entityId;

  /// Product / category name (empty when the row is gone).
  final String label;
  final String? error;

  const PendingUploadRow({
    required this.entity,
    required this.entityId,
    required this.label,
    this.error,
  });

  @override
  List<Object?> get props => [entity, entityId, label, error];
}

class PendingSyncState extends Equatable {
  final PendingSyncStatus status;
  final List<PendingSyncRow> rows;

  /// Parked image uploads (retry-able).
  final List<PendingUploadRow> failedUploads;
  final String? errorMessage;

  /// Last discard / retry refusal or failure; [failureSeq] grows with every
  /// one so the same failure twice is shown twice.
  final PendingSyncFailure? failure;
  final int failureSeq;

  const PendingSyncState({
    this.status = PendingSyncStatus.initial,
    this.rows = const [],
    this.failedUploads = const [],
    this.errorMessage,
    this.failure,
    this.failureSeq = 0,
  });

  PendingSyncState withFailure(
    PendingSyncFailure failure,
    String? message, {
    List<PendingSyncRow>? rows,
    List<PendingUploadRow>? failedUploads,
  }) => PendingSyncState(
    status: rows == null ? status : PendingSyncStatus.loaded,
    rows: rows ?? this.rows,
    failedUploads: failedUploads ?? this.failedUploads,
    errorMessage: message,
    failure: failure,
    failureSeq: failureSeq + 1,
  );

  bool get isLoading => status == PendingSyncStatus.loading;
  bool get isSyncing => status == PendingSyncStatus.syncing;

  PendingSyncState copyWith({
    PendingSyncStatus? status,
    List<PendingSyncRow>? rows,
    List<PendingUploadRow>? failedUploads,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PendingSyncState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      failedUploads: failedUploads ?? this.failedUploads,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failure: clearError ? null : failure,
      failureSeq: failureSeq,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rows,
    failedUploads,
    errorMessage,
    failure,
    failureSeq,
  ];
}
