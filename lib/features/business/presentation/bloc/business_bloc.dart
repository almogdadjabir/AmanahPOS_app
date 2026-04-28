import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'business_event.dart';
part 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  BusinessUseCase useCase;

  BusinessBloc({required this.useCase})
      : super(BusinessState.initial()) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<OnBusinessInitial>(_init);
  }

  Future<void> _init(OnBusinessInitial event,
      Emitter<BusinessState> emit) async {
    emit(state.copyWith(businessStatus: BusinessStatus.initial));
  }

}