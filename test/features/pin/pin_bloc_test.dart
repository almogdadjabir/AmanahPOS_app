import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';

class _MockVault extends Mock implements PinVaultService {}
class _MockCache extends Mock implements CacheStorage {}
class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockVault vault;
  late _MockCache cache;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(OnLoadProfileEvent());
    registerFallbackValue(const PinUserRecord(
      userId: 'fallback', businessId: 'b', tenantId: 't', fullName: 'f',
      role: 'cashier', phone: '+1', pinSalt: 's', pinHash: 'h',
      accessToken: 'a', refreshToken: 'r', profileJson: {},
      enrolledAt: 'n', lastUnlockAt: 'n',
    ));
  });

  setUp(() {
    vault = _MockVault();
    cache = _MockCache();
    authBloc = _MockAuthBloc();
    when(() => cache.save(any(), any())).thenAnswer((_) async => true);
    when(() => vault.lockoutRemaining()).thenAnswer((_) async => Duration.zero);
    when(() => vault.recordFailedAttempt()).thenAnswer((_) async {});
    when(() => authBloc.add(any())).thenReturn(null);
  });

  PinUserRecord rec() => const PinUserRecord(
        userId: 'u1', businessId: 'b1', tenantId: 't1', fullName: 'U',
        role: 'cashier', phone: '+1', pinSalt: 's', pinHash: 'h',
        accessToken: 'acc', refreshToken: 'ref',
        profileJson: {'id': 'u1'}, enrolledAt: 'n', lastUnlockAt: 'n',
      );

  void typed(PinBloc b, String pin) {
    for (final d in pin.split('')) {
      b.add(PinDigitPressed(d));
    }
  }

  group('unlock', () {
    blocTest<PinBloc, PinState>(
      'matching pin writes tokens, loads profile, reaches success',
      build: () {
        when(() => vault.findUserByPin('1234')).thenAnswer((_) async => rec());
        return PinBloc(
            vault: vault, cache: cache, authBloc: authBloc, mode: PinMode.unlock);
      },
      act: (b) => typed(b, '1234'),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => cache.save(Constants.authToken, 'acc')).called(1);
        verify(() => cache.save(Constants.refreshToken, 'ref')).called(1);
        verify(() => cache.save(Constants.xTenantID, 't1')).called(1);
        verify(() => authBloc.add(any(that: isA<OnLoadProfileEvent>()))).called(1);
      },
    );

    blocTest<PinBloc, PinState>(
      'wrong pin records failed attempt and does not load profile',
      build: () {
        when(() => vault.findUserByPin('0000')).thenAnswer((_) async => null);
        return PinBloc(
            vault: vault, cache: cache, authBloc: authBloc, mode: PinMode.unlock);
      },
      act: (b) => typed(b, '0000'),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => vault.recordFailedAttempt()).called(1);
        verifyNever(() => authBloc.add(any()));
      },
    );
  });

  group('setup', () {
    blocTest<PinBloc, PinState>(
      'enter then matching confirm enrolls and reaches success',
      build: () {
        when(() => vault.isPinTaken('1234')).thenAnswer((_) async => false);
        when(() => vault.enrollUser(any())).thenAnswer((_) async {});
        return PinBloc(
          vault: vault, cache: cache, authBloc: authBloc, mode: PinMode.setup,
          enrollUser: const User(id: 'u1', businessId: 'b1', role: 'cashier',
              fullName: 'U', phone: '+1'),
          enrollTokens: (access: 'acc', refresh: 'ref', tenantId: 't1'),
        );
      },
      act: (b) async {
        typed(b, '1234');
        await Future.delayed(const Duration(milliseconds: 20));
        typed(b, '1234');
      },
      wait: const Duration(milliseconds: 60),
      verify: (_) => verify(() => vault.enrollUser(any())).called(1),
    );
  });
}
