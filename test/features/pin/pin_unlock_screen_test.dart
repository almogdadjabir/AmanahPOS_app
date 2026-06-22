import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/pin_unlock_screen.dart';
import 'package:amana_pos/theme/app_theme.dart';

class _FakePinBloc extends Mock implements PinBloc {}

void main() {
  testWidgets('shows forgot-pin link', (tester) async {
    final bloc = _FakePinBloc();
    when(() => bloc.state).thenReturn(PinState.initial(PinMode.unlock));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<PinBloc>.value(value: bloc, child: const PinUnlockScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('account'), findsWidgets);
  });
}
