import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';

class _MockUseCase extends Mock implements UsersUseCase {}

void main() {
  late _MockUseCase useCase;

  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.getUsers()).thenAnswer(
        (_) async => const Right(UserResponseDto(success: true, data: [])));
  });

  blocTest<UserBloc, UserState>(
    'OnAddUser forwards the pin to the use case',
    build: () {
      when(() => useCase.addUser(
            phone: any(named: 'phone'),
            fullName: any(named: 'fullName'),
            role: any(named: 'role'),
            pin: any(named: 'pin'),
          )).thenAnswer((_) async => const Right(UserData(id: 'u1')));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnAddUser(
        phone: '+249912345678', fullName: 'Cashier', role: 'cashier', pin: '1234')),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => useCase.addUser(
          phone: '+249912345678',
          fullName: 'Cashier',
          role: 'cashier',
          pin: '1234',
        )).called(1),
  );

  blocTest<UserBloc, UserState>(
    'OnSetCashierPin calls setCashierPin',
    build: () {
      when(() => useCase.setCashierPin(
            userId: any(named: 'userId'),
            pin: any(named: 'pin'),
          )).thenAnswer((_) async => const Right(true));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnSetCashierPin(userId: 'u1', pin: '5678')),
    wait: const Duration(milliseconds: 50),
    verify: (_) =>
        verify(() => useCase.setCashierPin(userId: 'u1', pin: '5678')).called(1),
  );

  blocTest<UserBloc, UserState>(
    'OnDisableCashierPin calls disableCashierPin',
    build: () {
      when(() => useCase.disableCashierPin(any()))
          .thenAnswer((_) async => const Right(true));
      return UserBloc(useCase: useCase);
    },
    act: (b) => b.add(const OnDisableCashierPin('u1')),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => useCase.disableCashierPin('u1')).called(1),
  );
}
