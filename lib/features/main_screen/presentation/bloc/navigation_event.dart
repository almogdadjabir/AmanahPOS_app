part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationTabSelected extends NavigationEvent {
  final int index;

  const NavigationTabSelected(this.index);

  @override
  List<Object> get props => [index];
}


class SetMenuOpenEvent extends NavigationEvent {
  final bool? open;
  const SetMenuOpenEvent({this.open});
}