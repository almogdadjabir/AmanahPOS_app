part of 'expiry_bloc.dart';

abstract class ExpiryEvent extends Equatable {
  const ExpiryEvent();
  @override List<Object?> get props => [];
}

/// Initial load or pull-to-refresh.
class OnExpiryAlertsInitial extends ExpiryEvent {
  const OnExpiryAlertsInitial();
}
