import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';

class _MockCache extends Mock implements CacheStorage {}
class _MockVault extends Mock implements PinVaultService {}

void main() {
  late _MockCache cache;
  late _MockVault vault;

  setUp(() {
    cache = _MockCache();
    vault = _MockVault();
  });

  blocTest<SplashBloc, SplashState>(
    'routes to pinLocked when vault has users',
    build: () {
      when(() => cache.getValue(Constants.authToken)).thenAnswer((_) async => 'tok');
      when(() => vault.hasAnyEnrolled()).thenAnswer((_) async => true);
      return SplashBloc(cacheStorage: cache, vault: vault);
    },
    act: (b) => b.add(const SplashStarted()),
    wait: const Duration(seconds: 2),
    expect: () => [
      isA<SplashState>().having((s) => s.status, 'status', SplashStatus.loading),
      isA<SplashState>().having((s) => s.status, 'status', SplashStatus.pinLocked),
    ],
  );

  blocTest<SplashBloc, SplashState>(
    'routes to unauthenticated when no token and empty vault',
    build: () {
      when(() => cache.getValue(Constants.authToken)).thenAnswer((_) async => null);
      when(() => vault.hasAnyEnrolled()).thenAnswer((_) async => false);
      return SplashBloc(cacheStorage: cache, vault: vault);
    },
    act: (b) => b.add(const SplashStarted()),
    wait: const Duration(seconds: 2),
    expect: () => [
      isA<SplashState>().having((s) => s.status, 'status', SplashStatus.loading),
      isA<SplashState>()
          .having((s) => s.status, 'status', SplashStatus.unauthenticated),
    ],
  );
}
