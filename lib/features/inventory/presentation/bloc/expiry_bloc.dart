import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'expiry_event.dart';
part 'expiry_state.dart';

class ExpiryBloc extends Bloc<ExpiryEvent, ExpiryState> {
  final InventoryUseCase useCase;

  ExpiryBloc({required this.useCase}) : super(ExpiryState.initial()) {
    on<OnExpiryAlertsInitial>(_onInit);
  }

  Future<void> _onInit(
    OnExpiryAlertsInitial event,
    Emitter<ExpiryState> emit,
  ) async {
    if (state.status == ExpiryStatus.loading) return;

    emit(state.copyWith(status: ExpiryStatus.loading, clearError: true));

    final result = await useCase.getExpiryAlerts();

    result.fold(
      (error) => emit(state.copyWith(
        status: ExpiryStatus.failure,
        error: error ?? 'Failed to load expiry alerts',
      )),
      (response) {
        if (!emit.isDone) {
          emit(state.copyWith(
            // API returns two separate lists; .all combines them
            // with expired first so the screen shows critical items at top.
            status: ExpiryStatus.success,
            alerts: response.all,
            clearError: true,
          ));
        }
      },
    );
  }
}
