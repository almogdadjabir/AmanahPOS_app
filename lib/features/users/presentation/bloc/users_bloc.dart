import 'package:amana_pos/features/users/data/models/requests/add_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/requests/edit_user_request_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'users_state.dart';
part 'users_event.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UsersUseCase useCase;

  UserBloc({required this.useCase}) : super(UserState.initial()) {
    on<OnUserInitial>(_init);
    on<OnAddUser>(_addUser);
    on<OnEditUser>(_editUser);
    on<OnDeactivateUser>(_deactivateUser);
  }

  Future<void> _init(
      OnUserInitial event,
      Emitter<UserState> emit,
      ) async {
    if (state.userStatus == UserStatus.loading ||
        state.userStatus == UserStatus.success) {
      return;
    }

    emit(state.copyWith(userStatus: UserStatus.loading));

    try {
      final response = await useCase.getUsers();

      response.fold(
            (error) => emit(state.copyWith(
          userStatus: UserStatus.failure,
          responseError: error,
        )),
            (result) => emit(state.copyWith(
          userStatus: UserStatus.success,
          userList: result.data ?? [],
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        userStatus: UserStatus.failure,
        responseError: e.toString(),
      ));
    }
  }

  Future<void> _editUser(OnEditUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(
        submitStatus: UserSubmitStatus.loading, submitError: null));

    try {
      final payload = EditUserRequestDto(fullName: event.fullName, role: event.role);
      final response =
      await useCase.editUser(event.userId, payload);

      response.fold(
            (error) => emit(state.copyWith(
            submitStatus: UserSubmitStatus.failure, submitError: error)),
            (_) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.success,
          userList: state.userList.map((u) {
            return u.id != event.userId
                ? u
                : u.copyWith(fullName: event.fullName, role: event.role);
          }).toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure,
          submitError: e.toString()));
    }
  }

  Future<void> _deactivateUser(
      OnDeactivateUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(
        submitStatus: UserSubmitStatus.loading, submitError: null));

    try {
      final response = await useCase.deactivateUser(event.userId);

      response.fold(
            (error) => emit(state.copyWith(
            submitStatus: UserSubmitStatus.failure, submitError: error)),
            (_) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.success,
          userList: state.userList.map((u) {
            return u.id != event.userId ? u : u.copyWith(isActive: false);
          }).toList(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure,
          submitError: e.toString()));
    }
  }

  Future<void> _addUser(OnAddUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(
        submitStatus: UserSubmitStatus.loading, submitError: null));

    final payload = AddUserRequestDto(fullName: event.fullName, role: event.role, phone: event.phone);


    try {
      final response = await useCase.addUser(payload);

      response.fold(
            (error) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure,
          submitError: error,
        )),
            (newUser) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.success,
          userList: [...state.userList, newUser.data!],
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: UserSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }
}