import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'users_event.dart';
part 'users_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UsersUseCase useCase;

  UserBloc({required this.useCase}) : super(UserState.initial()) {
    on<OnUserInitial>(_onInitial);
    on<OnAddUser>(_onAddUser);
    on<OnEditUser>(_onEditUser);
    on<OnDeactivateUser>(_onDeactivateUser);
    on<OnAssignUserShop>(_onAssignUserShop);
  }

  Future<void> _onInitial(
      OnUserInitial event, Emitter<UserState> emit) async {
    emit(state.copyWith(userStatus: UserStatus.loading));
    final result = await useCase.getUsers();
    result.fold(
          (error) => emit(state.copyWith(
          userStatus: UserStatus.failure, responseError: error)),
          (data)  => emit(state.copyWith(
          userStatus: UserStatus.success, userList: data.data ?? [])),
    );
  }

  Future<void> _onAddUser(
      OnAddUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));

    // Step 1: create the user
    final result = await useCase.addUser(
      phone:    event.phone,
      fullName: event.fullName,
      role:     event.role,
    );

    await result.fold(
          (error) async {
        emit(state.copyWith(
            submitStatus: UserSubmitStatus.failure, submitError: error));
      },
          (createdUser) async {
        // Step 2: assign shop if provided and user has a valid ID
        if (event.shopId != null &&
            event.shopId!.isNotEmpty &&
            createdUser.id != null) {
          final assignResult = await useCase.assignShop(
            userId: createdUser.id!,
            shopId: event.shopId,
          );
          // If assign-shop fails, still treat the creation as successful
          // but could log the error for debugging
          assignResult.fold(
                (error) => null, // non-fatal — user was created
                (_)     => null,
          );
        }

        emit(state.copyWith(submitStatus: UserSubmitStatus.success));
        add(OnUserInitial()); // refresh list
      },
    );
  }

  Future<void> _onEditUser(
      OnEditUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final result = await useCase.editUser(
      userId:   event.userId,
      fullName: event.fullName,
      role:     event.role,
    );
    result.fold(
          (error) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure, submitError: error)),
          (_) {
        emit(state.copyWith(submitStatus: UserSubmitStatus.success));
        add(OnUserInitial());
      },
    );
  }

  Future<void> _onDeactivateUser(
      OnDeactivateUser event, Emitter<UserState> emit) async {
    final result = await useCase.deactivateUser(event.userId);
    result.fold(
          (error) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure, submitError: error)),
          (_) => add(OnUserInitial()),
    );
  }

  Future<void> _onAssignUserShop(
      OnAssignUserShop event, Emitter<UserState> emit) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final result = await useCase.assignShop(
      userId: event.userId,
      shopId: event.shopId,
    );
    result.fold(
          (error) => emit(state.copyWith(
          submitStatus: UserSubmitStatus.failure, submitError: error)),
          (_) {
        emit(state.copyWith(submitStatus: UserSubmitStatus.success));
        add(OnUserInitial());
      },
    );
  }
}
