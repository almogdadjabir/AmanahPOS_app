import 'package:amana_pos/features/dashboard/domain/usecases/dashboard_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardUseCase useCase;

  DashboardBloc({required this.useCase})
      : super(DashboardState.initial()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<OnDashboardInitial>(_init);
  }

  Future<void> _init(OnDashboardInitial event,
      Emitter<DashboardState> emit) async {
    emit(state.copyWith(dashboardStatus: DashboardStatus.initial));
  }

}