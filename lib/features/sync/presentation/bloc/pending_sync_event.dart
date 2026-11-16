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
