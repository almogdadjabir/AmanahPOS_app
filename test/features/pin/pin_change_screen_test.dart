import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/pin_change_screen.dart';
import 'package:amana_pos/theme/app_theme.dart';

class _FakePinBloc extends Mock implements PinBloc {}

void main() {
  testWidgets('shows Enter current PIN first', (tester) async {
    final bloc = _FakePinBloc();
    when(() => bloc.state).thenReturn(PinState.initial(PinMode.change));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PinBloc>.value(value: bloc, child: const PinChangeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Enter current PIN'), findsWidgets);
  });
}
