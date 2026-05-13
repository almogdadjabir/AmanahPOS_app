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

class OnPendingSyncDeleteSale extends PendingSyncEvent {
  final String clientSaleId;
  const OnPendingSyncDeleteSale(this.clientSaleId);
  @override
  List<Object?> get props => [clientSaleId];
}
