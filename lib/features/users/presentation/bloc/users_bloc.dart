import 'dart:async';

import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'users_event.dart';
part 'users_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UsersUseCase useCase;

  UserBloc({required this.useCase, this.changes}) : super(UserState.initial()) {
    on<OnUserInitial>(_onInitial);
    on<OnAddUser>(_onAddUser);
    on<OnUpdateUser>(_onUpdateUser);
    on<OnDeactivateUser>(_onDeactivateUser);
    on<OnReactivateUser>(_onReactivateUser);
    on<OnApplyUserConflict>(
      (e, emit) => _resolve(emit, () => useCase.applyMineAgain(e.mutationId)),
    );
    on<OnDismissUserConflict>(
      (e, emit) => _resolve(emit, () => useCase.dismissConflict(e.mutationId)),
    );
  }

  /// `DbChangeNotifier.changes`: the team list re-reads when a member row or
  /// the outbox changes (a push result, a pull, a local edit).
  final Stream<Set<String>>? changes;
  StreamSubscription<Set<String>>? _changesSub;
  Timer? _debounce;

  static const Set<String> watchedTables = {'synced_entities', 'outbox'};

  void _watch() {
    if (_changesSub != null || changes == null) return;
    _changesSub = changes!.listen((tables) {
      if (tables.intersection(watchedTables).isEmpty) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 16), () {
        if (!isClosed) add(const OnUserInitial(silent: true));
      });
    });
  }

  Future<void> _resolve(
    Emitter<UserState> emit,
    Future<Either<String?, bool>> Function() act,
  ) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final r = await act();
    r.fold(
      (e) => emit(
        state.copyWith(submitStatus: UserSubmitStatus.failure, submitError: e),
      ),
      (_) {
        emit(state.copyWith(submitStatus: UserSubmitStatus.success));
        add(const OnUserInitial(silent: true));
      },
    );
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _changesSub?.cancel();
    return super.close();
  }

  Future<void> _onInitial(OnUserInitial event, Emitter<UserState> emit) async {
    _watch();
    final keep = event.silent && state.userList.isNotEmpty;
    if (!keep) emit(state.copyWith(userStatus: UserStatus.loading));
    final result = await useCase.getUsers();
    result.fold(
      (error) => emit(
        keep
            ? state.copyWith(userStatus: UserStatus.success)
            : state.copyWith(
                userStatus: UserStatus.failure,
                responseError: error,
              ),
      ),
      (data) => emit(
        state.copyWith(
          userStatus: UserStatus.success,
          userList: data.data ?? [],
        ),
      ),
    );
  }

  Future<void> _onAddUser(OnAddUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));

    final result = await useCase.addUser(
      phone: event.phone,
      fullName: event.fullName,
      role: event.role,
      shopId: event.shopId,
    );

    final created = result.fold<UserData?>((_) => null, (u) => u);
    if (result.isLeft()) {
      emit(
        state.copyWith(
          submitStatus: UserSubmitStatus.failure,
          submitError: result.swap().getOrElse((_) => null),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submitStatus: UserSubmitStatus.success,
        userStatus: UserStatus.success,
        userList: [
          if (created != null && created.id != null) created,
          // A change-stream reload may already hold the new member.
          for (final u in state.userList)
            if (created?.id == null || u.id != created!.id) u,
        ],
      ),
    );
    add(const OnUserInitial(silent: true));
  }

  Future<void> _onUpdateUser(
    OnUpdateUser event,
    Emitter<UserState> emit,
  ) async {
    await _update(
      emit,
      userId: event.userId,
      fullName: event.fullName,
      role: event.role,
      isActive: event.isActive,
      shopId: event.shopId,
    );
  }

  Future<void> _onReactivateUser(
    OnReactivateUser event,
    Emitter<UserState> emit,
  ) => _update(emit, userId: event.userId, isActive: true);

  Future<void> _update(
    Emitter<UserState> emit, {
    required String userId,
    String? fullName,
    String? role,
    bool? isActive,
    String? shopId,
  }) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final result = await useCase.updateUser(
      userId: userId,
      fullName: fullName,
      role: role,
      isActive: isActive,
      shopId: shopId,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          submitStatus: UserSubmitStatus.failure,
          submitError: error,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            submitStatus: UserSubmitStatus.success,
            userList: _patchList(
              userId,
              (u) => u.patched(
                fullName: fullName,
                role: role,
                isActive: isActive,
                shopId: shopId,
              ),
            ),
          ),
        );
        add(const OnUserInitial(silent: true));
      },
    );
  }

  Future<void> _onDeactivateUser(
    OnDeactivateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(submitStatus: UserSubmitStatus.loading));
    final result = await useCase.deactivateUser(event.userId);
    result.fold(
      (error) => emit(
        state.copyWith(
          submitStatus: UserSubmitStatus.failure,
          submitError: error,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            submitStatus: UserSubmitStatus.success,
            userList: _patchList(
              event.userId,
              (u) => u.patched(isActive: false),
            ),
          ),
        );
        add(const OnUserInitial(silent: true));
      },
    );
  }

  List<UserData> _patchList(String id, UserData Function(UserData) patch) => [
    for (final u in state.userList) u.id == id ? patch(u) : u,
  ];
}
