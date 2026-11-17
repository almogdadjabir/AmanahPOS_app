import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
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

  PinUserRecord rec() => const PinUserRecord(
    userId: 'u1',
    businessId: 'b1',
    tenantId: 't1',
    fullName: 'U',
    role: 'cashier',
    phone: '+1',
    pinSalt: 's',
    pinHash: 'h',
    accessToken: 'acc',
    refreshToken: 'ref',
    profileJson: {'id': 'u1'},
    enrolledAt: 'n',
    lastUnlockAt: 'n',
  );

  setUp(() {
    vault = _MockVault();
    cache = _MockCache();
    authBloc = _MockAuthBloc();
    when(() => vault.lockoutRemaining()).thenAnswer((_) async => Duration.zero);
  });

  void typed(PinBloc b, String pin) {
    for (final d in pin.split('')) {
      b.add(PinDigitPressed(d));
    }
  }

  blocTest<PinBloc, PinState>(
    'verify current -> new -> confirm calls changePin and reaches success',
    build: () {
      when(() => vault.findUserByPin('1111')).thenAnswer((_) async => rec());
      when(
        () => vault.changePin('u1', '2222'),
      ).thenAnswer((_) async => ChangePinResult.success);
      return PinBloc(
        vault: vault,
        cache: cache,
        authBloc: authBloc,
        mode: PinMode.change,
        changeUserId: 'u1',
      );
    },
    act: (b) async {
      typed(b, '1111');
      await Future.delayed(const Duration(milliseconds: 20));
      typed(b, '2222');
      await Future.delayed(const Duration(milliseconds: 20));
      typed(b, '2222');
    },
    wait: const Duration(milliseconds: 80),
    verify: (_) => verify(() => vault.changePin('u1', '2222')).called(1),
  );

  blocTest<PinBloc, PinState>(
    'wrong current PIN does not advance',
    build: () {
      when(() => vault.findUserByPin('0000')).thenAnswer((_) async => null);
      return PinBloc(
        vault: vault,
        cache: cache,
        authBloc: authBloc,
        mode: PinMode.change,
        changeUserId: 'u1',
      );
    },
    act: (b) => typed(b, '0000'),
    wait: const Duration(milliseconds: 40),
    verify: (bloc) {
      expect(bloc.state.currentVerified, isFalse);
      verifyNever(() => vault.changePin(any(), any()));
    },
  );
}
