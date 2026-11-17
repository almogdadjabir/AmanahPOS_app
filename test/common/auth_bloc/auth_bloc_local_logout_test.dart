import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockBusinessUseCase extends Mock implements BusinessUseCase {}

class _MockOfflineCache extends Mock implements OfflineLocalCache {}

class _MockOfflineStatusBloc extends Mock implements OfflineStatusBloc {}

class _MockCacheStorage extends Mock implements CacheStorage {}

class _MockPinVault extends Mock implements PinVaultService {}

class _MockBiometric extends Mock implements BiometricUnlockService {}

class _MockCoordinator extends Mock implements SyncCoordinator {}

/// F2: the blocking first-setup screen's "Sign out" works offline when
/// nothing is unsynced (local-only sign-out), and is refused otherwise.
void main() {
  late _MockLoginUseCase login;
  late _MockOfflineCache offline;
  late _MockOfflineStatusBloc status;
  late _MockCacheStorage storage;
  late _MockCoordinator coordinator;

  setUpAll(() => registerFallbackValue(const OnOfflineStatusResetRequested()));

  setUp(() async {
    await getIt.reset();
    login = _MockLoginUseCase();
    offline = _MockOfflineCache();
    status = _MockOfflineStatusBloc();
    storage = _MockCacheStorage();
    coordinator = _MockCoordinator();
    when(() => login.cacheStorage).thenReturn(storage);
    when(() => storage.save(any(), any())).thenAnswer((_) async => true);
    when(() => storage.clearOnLogout()).thenAnswer((_) async {});
    when(() => offline.clearAllOnLogout()).thenAnswer((_) async {});
    when(() => status.isDeviceOnline).thenAnswer((_) async => false);
    when(() => coordinator.pauseForWipe()).thenAnswer((_) async {});
    when(() => coordinator.resumeAfterFailedWipe()).thenReturn(null);
    final pin = _MockPinVault();
    when(pin.clearVault).thenAnswer((_) async {});
    final bio = _MockBiometric();
    when(bio.disable).thenAnswer((_) async {});
    getIt
      ..registerSingleton<PinVaultService>(pin)
      ..registerSingleton<BiometricUnlockService>(bio)
      ..registerSingletonAsync<SyncCoordinator>(() async => coordinator);
    await getIt.allReady();
  });
  tearDown(() => getIt.reset());

  AuthBloc make() => AuthBloc(
    useCase: login,
    businessUseCase: _MockBusinessUseCase(),
    offlineLocalCache: offline,
    offlineStatusBloc: status,
  );

  Future<AuthState> settle(AuthBloc b, AuthEvent e) async {
    b.add(e);
    return b.stream.firstWhere((s) => s.authStatus != AuthStatus.loading);
  }

  test('offline + empty outbox: local-only sign-out pauses sync, then wipes '
      'and signs out', () async {
    when(
      () => status.blockingPendingOfflineSalesCount,
    ).thenAnswer((_) async => 0);
    final b = make();
    final s = await settle(b, const OnLogoutEvent(localOnly: true));

    expect(s.authStatus, isNot(AuthStatus.failure));
    expect(s.responseError, isNull);
    verifyInOrder([
      () => coordinator.pauseForWipe(),
      () => offline.clearAllOnLogout(),
    ]);
    verify(() => storage.save(any(), null)).called(greaterThan(0));
    verify(() => status.add(const OnOfflineStatusResetRequested())).called(1);
    await b.close();
  });

  // Review M5: the message is localized and says "unsynced changes" (rows
  // may be stock / inbound, not only sales). Was: contains('2 pending sales').
  test('offline + unsynced rows: local-only sign-out is refused with the '
      'unsynced-changes message; nothing is wiped', () async {
    when(
      () => status.blockingPendingOfflineSalesCount,
    ).thenAnswer((_) async => 2);
    final b = make();
    final s = await settle(b, const OnLogoutEvent(localOnly: true));

    expect(s.authStatus, AuthStatus.failure);
    expect(s.responseError, contains('2 unsynced changes'));
    verifyNever(() => coordinator.pauseForWipe());
    verifyNever(() => offline.clearAllOnLogout());
    await b.close();
  });

  test('offline: the normal sign-out keeps requiring the network', () async {
    when(
      () => status.blockingPendingOfflineSalesCount,
    ).thenAnswer((_) async => 0);
    final b = make();
    final s = await settle(b, const OnLogoutEvent());

    expect(s.authStatus, AuthStatus.failure);
    expect(s.responseError, contains('offline'));
    verifyNever(() => offline.clearAllOnLogout());
    await b.close();
  });

  test('M5: the refusal is localized (ar)', () async {
    when(
      () => status.blockingPendingOfflineSalesCount,
    ).thenAnswer((_) async => 3);
    final b = AuthBloc(
      useCase: login,
      businessUseCase: _MockBusinessUseCase(),
      offlineLocalCache: offline,
      offlineStatusBloc: status,
      localizations: () => lookupAppLocalizations(const Locale('ar')),
    );
    final s = await settle(b, const OnLogoutEvent(localOnly: true));
    expect(s.authStatus, AuthStatus.failure);
    expect(
      s.responseError,
      lookupAppLocalizations(const Locale('ar')).authLogoutUnsynced(3),
    );
    expect(s.responseError, contains('غير مُزامنة'));
    await b.close();
  });
}
