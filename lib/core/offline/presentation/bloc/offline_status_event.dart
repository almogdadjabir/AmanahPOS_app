part of 'offline_status_bloc.dart';

abstract class OfflineStatusEvent extends Equatable {
  const OfflineStatusEvent();

  @override
  List<Object?> get props => [];
}

class OnOfflineStatusStarted extends OfflineStatusEvent {
  const OnOfflineStatusStarted();
}

class OnOfflineStatusRefreshRequested extends OfflineStatusEvent {
  const OnOfflineStatusRefreshRequested();
}

class OnOfflineStatusSyncSalesRequested extends OfflineStatusEvent {
  const OnOfflineStatusSyncSalesRequested();
}

class OnOfflineConnectionChanged extends OfflineStatusEvent {
  final bool isOnline;

  const OnOfflineConnectionChanged({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

class OnOfflinePendingSalesCountChanged extends OfflineStatusEvent {
  final int count;

  const OnOfflinePendingSalesCountChanged({required this.count});

  @override
  List<Object?> get props => [count];
}

class OnOfflineStatusResetRequested extends OfflineStatusEvent {
  const OnOfflineStatusResetRequested();

  @override
  List<Object?> get props => [];
}