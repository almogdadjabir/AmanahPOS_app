import 'package:amana_pos/features/dashboard/data/models/mock_data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardState.initial()) {
    _initializeEvents();
  }

  void _initializeEvents() {
    on<SetCategoryEvent>(_onSetCategory);
    on<SetSearchQueryEvent>(_onSetSearchQuery);
    on<SetCartExpandedEvent>(_onSetCartExpanded);
    on<SetMenuOpenEvent>(_onSetMenuOpen);
  }

  // ── Handlers ───────────────────────────────────────────────────────

  void _onSetCategory(SetCategoryEvent event, Emitter<DashboardState> emit) {
    emit(state.copyWith(activeCategory: event.categoryId));
  }

  void _onSetSearchQuery(SetSearchQueryEvent event, Emitter<DashboardState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onSetCartExpanded(SetCartExpandedEvent event, Emitter<DashboardState> emit) {
    emit(state.copyWith(cartExpanded: event.expanded));
  }

  void _onSetMenuOpen(SetMenuOpenEvent event, Emitter<DashboardState> emit) {
    emit(state.copyWith(menuOpen: event.open));
  }
}