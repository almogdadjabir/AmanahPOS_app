part of 'inbound_bloc.dart';

abstract class InboundEvent extends Equatable {
  const InboundEvent();
}

class OnInboundStarted extends InboundEvent {
  const OnInboundStarted();
  @override List<Object?> get props => [];
}

class OnInboundLoadMore extends InboundEvent {
  const OnInboundLoadMore();
  @override List<Object?> get props => [];
}

class OnInboundFormSubmit extends InboundEvent {
  final CreateInboundRequestDto request;
  const OnInboundFormSubmit(this.request);
  @override List<Object?> get props => [request];
}

class OnInboundAcknowledge extends InboundEvent {
  const OnInboundAcknowledge();
  @override List<Object?> get props => [];
}

class OnInboundReset extends InboundEvent {
  const OnInboundReset();
  @override List<Object?> get props => [];
}
