import 'dart:async';

import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements UsersUseCase {}

const _omar = UserData(
  id: 'u1',
  phone: '+249917001122',
  fullName: 'Omar',
  role: 'cashier',
  isActive: true,
  isVerified: true,
);

void main() {
  late _MockUseCase useCase;

  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.getUsers()).thenAnswer(
      (_) async => const Right(UserResponseDto(success: true, data: [_omar])),
    );
  });

  test('UserData.fromJson reads last_login_at and no longer lastLoginAt', () {
    final u = UserData.fromJson({
      'id': 'u1',
      'phone': '+249917001122',
      'full_name': 'Omar',
      'role': 'cashier',
      'is_verified': true,
      'is_active': true,
      'default_shop_id': 's1',
      'last_login_at': '2026-11-14T08:42:00Z',
      'created_at': '2026-01-05T10:00:00Z',
      'lastLoginAt': 'wrong-key',
    });
    expect(u.lastLoginAt, '2026-11-14T08:42:00Z');
    expect(u.defaultShopId, 's1');
    expect(u.fullName, 'Omar');
  });

  blocTest<UserBloc, UserState>(
    'OnAddUser sends the shop in the create call, with no second request',
    build: () {
      when(
        () => useCase.addUser(
          phone: any(named: 'phone'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          shopId: any(named: 'shopId'),
        ),
      ).thenAnswer((_) async => const Right(UserData(id: 'u2')));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(
      const OnAddUser(
        phone: '+249912345678',
        fullName: 'Sara',
        role: 'manager',
        shopId: 's1',
      ),
    ),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<UserState>().having(
        (s) => s.submitStatus,
        'submit',
        UserSubmitStatus.loading,
      ),
      isA<UserState>().having(
        (s) => s.submitStatus,
        'submit',
        UserSubmitStatus.success,
      ),
      isA<UserState>().having((s) => s.userList.length, 'list', 1),
    ],
    verify: (_) {
      verify(
        () => useCase.addUser(
          phone: '+249912345678',
          fullName: 'Sara',
          role: 'manager',
          shopId: 's1',
        ),
      ).called(1);
      verify(() => useCase.getUsers()).called(1);
    },
  );

  blocTest<UserBloc, UserState>(
    'OnUpdateUser changes the role locally and calls updateUser',
    build: () {
      when(
        () => useCase.updateUser(
          userId: any(named: 'userId'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          isActive: any(named: 'isActive'),
          shopId: any(named: 'shopId'),
        ),
      ).thenAnswer((_) async => const Right(true));
      when(() => useCase.getUsers()).thenAnswer(
        (_) async => const Right(
          UserResponseDto(
            success: true,
            data: [UserData(id: 'u1', fullName: 'Omar', role: 'manager')],
          ),
        ),
      );
      return UserBloc(useCase: useCase);
    },
    seed: () =>
        const UserState(userStatus: UserStatus.success, userList: [_omar]),
    act: (b) => b.add(const OnUpdateUser(userId: 'u1', role: 'manager')),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      verify(
        () => useCase.updateUser(
          userId: 'u1',
          fullName: null,
          role: 'manager',
          isActive: null,
          shopId: null,
        ),
      ).called(1);
      expect(b.state.submitStatus, UserSubmitStatus.success);
      expect(b.state.userList.first.role, 'manager');
    },
  );

  blocTest<UserBloc, UserState>(
    'OnDeactivateUser marks inactive, OnReactivateUser patches is_active true',
    build: () {
      when(
        () => useCase.deactivateUser(any()),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => useCase.updateUser(
          userId: any(named: 'userId'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          isActive: any(named: 'isActive'),
          shopId: any(named: 'shopId'),
        ),
      ).thenAnswer((_) async => const Right(true));
      when(() => useCase.getUsers()).thenAnswer(
        (_) async => const Right(
          UserResponseDto(
            success: true,
            data: [UserData(id: 'u1', fullName: 'Omar', isActive: false)],
          ),
        ),
      );
      return UserBloc(useCase: useCase);
    },
    seed: () =>
        const UserState(userStatus: UserStatus.success, userList: [_omar]),
    act: (b) async {
      b.add(const OnDeactivateUser('u1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(b.state.userList.first.isActive, false);
      b.add(const OnReactivateUser('u1'));
    },
    wait: const Duration(milliseconds: 80),
    verify: (b) {
      verify(() => useCase.deactivateUser('u1')).called(1);
      verify(
        () => useCase.updateUser(
          userId: 'u1',
          fullName: null,
          role: null,
          isActive: true,
          shopId: null,
        ),
      ).called(1);
    },
  );

  blocTest<UserBloc, UserState>(
    'a failed update exposes the error',
    build: () {
      when(
        () => useCase.updateUser(
          userId: any(named: 'userId'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          isActive: any(named: 'isActive'),
          shopId: any(named: 'shopId'),
        ),
      ).thenAnswer((_) async => const Left('nope'));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnUpdateUser(userId: 'u1', isActive: false)),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.submitStatus, UserSubmitStatus.failure);
      expect(b.state.submitError, 'nope');
    },
  );

  blocTest<UserBloc, UserState>(
    'OnApplyUserConflict / OnDismissUserConflict call the use case and reload',
    build: () {
      when(
        () => useCase.applyMineAgain(any()),
      ).thenAnswer((_) async => const Right(true));
      when(
        () => useCase.dismissConflict(any()),
      ).thenAnswer((_) async => const Right(true));
      return UserBloc(useCase: useCase);
    },
    act: (b) async {
      b.add(const OnApplyUserConflict('m1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      b.add(const OnDismissUserConflict('m2'));
    },
    wait: const Duration(milliseconds: 80),
    verify: (b) {
      verify(() => useCase.applyMineAgain('m1')).called(1);
      verify(() => useCase.dismissConflict('m2')).called(1);
      verify(() => useCase.getUsers()).called(2);
    },
  );

  test('a team/outbox table change re-reads the list silently', () async {
    final ctrl = StreamController<Set<String>>();
    final b = UserBloc(useCase: useCase, changes: ctrl.stream);
    b.add(const OnUserInitial());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    ctrl.add({'products'});
    await Future<void>.delayed(const Duration(milliseconds: 40));
    verify(() => useCase.getUsers()).called(1);
    ctrl.add({'synced_entities'});
    await Future<void>.delayed(const Duration(milliseconds: 60));
    verify(() => useCase.getUsers()).called(1);
    await b.close();
    await ctrl.close();
  });

  blocTest<UserBloc, UserState>(
    'OnAddUser does not list the member twice when a reload already did',
    build: () {
      when(
        () => useCase.addUser(
          phone: any(named: 'phone'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          shopId: any(named: 'shopId'),
        ),
      ).thenAnswer((_) async => const Right(UserData(id: 'u1')));
      return UserBloc(useCase: useCase);
    },
    seed: () =>
        const UserState(userStatus: UserStatus.success, userList: [_omar]),
    act: (b) =>
        b.add(const OnAddUser(phone: '+1', fullName: 'Omar', role: 'cashier')),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.userList.where((u) => u.id == 'u1'), hasLength(1));
    },
  );
}
