part of 'pending_sync_bloc.dart';

abstract class PendingSyncEvent extends Equatable {
  const PendingSyncEvent();
  @override
  List<Object?> get props => [];
}

class OnPendingSyncLoad extends PendingSyncEvent {
  const OnPendingSyncLoad();
}

class OnPendingSyncRetryAll extends PendingSyncEvent {
  const OnPendingSyncRetryAll();
}

/// Outbox path: retry one rejected row.
class OnPendingSyncRetryRow extends PendingSyncEvent {
  final String mutationId;
  const OnPendingSyncRetryRow(this.mutationId);
  @override
  List<Object?> get props => [mutationId];
}

/// Outbox path: discard one row (the UI has already confirmed for sales).
class OnPendingSyncDiscardRow extends PendingSyncEvent {
  final String mutationId;
  const OnPendingSyncDiscardRow(this.mutationId);
  @override
  List<Object?> get props => [mutationId];
}

/// Outbox path: discard every unsynced row of ANOTHER scope (never the
/// current one). The UI confirms first.
class OnPendingSyncDiscardScope extends PendingSyncEvent {
  final String scope;
  const OnPendingSyncDiscardScope(this.scope);
  @override
  List<Object?> get props => [scope];
}

/// Discard sheet "Send now": run the existing sync-now, then reload.
class OnPendingSyncSendNow extends PendingSyncEvent {
  const OnPendingSyncSendNow();
}

/// Catalog row: "Merge into existing" (the UI showed the counts of
/// [PendingSyncBloc.previewMerge] and the user confirmed).
class OnPendingSyncMerge extends PendingSyncEvent {
  final String mutationId;
  const OnPendingSyncMerge(this.mutationId);
  @override
  List<Object?> get props => [mutationId];
}

/// Catalog row: "Edit and retry", sent after the entity's edit form closed.
/// [editedAfterSeq]: the entity's last outbox seq before the form opened
/// (nothing is retried when the user saved no edit).
class OnPendingSyncEditRetry extends PendingSyncEvent {
  final String mutationId;
  final int? editedAfterSeq;
  const OnPendingSyncEditRetry(this.mutationId, {this.editedAfterSeq});
  @override
  List<Object?> get props => [mutationId, editedAfterSeq];
}

/// A parked (failed) image upload: back to the queue, sent right away.
class OnPendingSyncRetryUpload extends PendingSyncEvent {
  final String entity;
  final String entityId;
  const OnPendingSyncRetryUpload(this.entity, this.entityId);
  @override
  List<Object?> get props => [entity, entityId];
}
