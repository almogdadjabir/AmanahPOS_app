import 'package:amana_pos/features/registration/domain/usecases/registration_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationUseCase useCase;

  RegistrationBloc({required this.useCase})
      : super(RegistrationState.initial()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<OnRegistrationInitial>(_init);
  }

  Future<void> _init(OnRegistrationInitial event,
      Emitter<RegistrationState> emit) async {
    emit(state.copyWith(registrationStatus: RegistrationStatus.initial));
  }

}