import 'package:amana_pos/features/main_screen/data/navigation_config.dart';
import 'package:amana_pos/features/main_screen/data/navigation_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {

  NavigationBloc()
      : super(NavigationState()) {
    on<NavigationTabSelected>(_onNavigationTabSelected);
    on<SetMenuOpenEvent>(_onSetMenuOpen);
  }

  void _onNavigationTabSelected(
    NavigationTabSelected event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(selectedIndex: event.index));
  }


  void _onSetMenuOpen(SetMenuOpenEvent event, Emitter<NavigationState> emit) {
    emit(state.copyWith(menuOpen: event.open));
  }
}