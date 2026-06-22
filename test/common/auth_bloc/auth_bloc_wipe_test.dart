import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}
class _MockBusinessUseCase extends Mock implements BusinessUseCase {}
class _MockOfflineCache extends Mock implements OfflineLocalCache {}
class _MockOfflineStatusBloc extends Mock implements OfflineStatusBloc {}

void main() {
  late _MockLoginUseCase login;
  late _MockBusinessUseCase business;
  late _MockOfflineCache offline;
  late _MockOfflineStatusBloc offlineStatus;

  setUp(() {
    login = _MockLoginUseCase();
    business = _MockBusinessUseCase();
    offline = _MockOfflineCache();
    offlineStatus = _MockOfflineStatusBloc();
    when(() => offline.clearAllOnLogout()).thenAnswer((_) async {});
    when(() => offline.getBusinesses()).thenAnswer((_) async => []);
  });

  AuthBloc make() => AuthBloc(
        useCase: login, businessUseCase: business,
        offlineLocalCache: offline, offlineStatusBloc: offlineStatus,
      );

  const u1 = User(id: 'u1', businessId: 'b1', role: 'owner');
  const u2 = User(id: 'u2', businessId: 'b1', role: 'cashier');
  const u3 = User(id: 'u3', businessId: 'b2', role: 'owner');

  blocTest<AuthBloc, AuthState>(
    'same business different user does NOT wipe',
    build: make,
    act: (b) async {
      b.add(OnLoadProfileEvent(user: u1));
      await Future.delayed(const Duration(milliseconds: 10));
      b.add(OnLoadProfileEvent(user: u2));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verifyNever(() => offline.clearAllOnLogout()),
  );

  blocTest<AuthBloc, AuthState>(
    'different business DOES wipe',
    build: make,
    act: (b) async {
      b.add(OnLoadProfileEvent(user: u1));
      await Future.delayed(const Duration(milliseconds: 10));
      b.add(OnLoadProfileEvent(user: u3));
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => offline.clearAllOnLogout()).called(1),
  );
}
