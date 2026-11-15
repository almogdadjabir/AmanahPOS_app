import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/pin_unlock_screen.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakePinBloc extends Mock implements PinBloc {}

class _FakeVault extends Mock implements PinVaultService {}

class _FakeBiometrics extends Mock implements BiometricUnlockService {}

void main() {
  setUp(() async {
    await getIt.reset();
    final vault = _FakeVault();
    when(() => vault.allUsers()).thenAnswer((_) async => []);
    final bio = _FakeBiometrics();
    when(() => bio.offeredUser()).thenAnswer((_) async => null);
    getIt.registerSingleton<PinVaultService>(vault);
    getIt.registerSingleton<BiometricUnlockService>(bio);
  });

  tearDown(() => getIt.reset());

  testWidgets('shows the different-account link and no Face ID key', (
    tester,
  ) async {
    final bloc = _FakePinBloc();
    when(() => bloc.state).thenReturn(PinState.initial(PinMode.unlock));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PinBloc>.value(
          value: bloc,
          child: const PinUnlockScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('Use a different account'), findsOneWidget);
    expect(find.bySemanticsLabel('Face ID'), findsNothing);
  });
}
