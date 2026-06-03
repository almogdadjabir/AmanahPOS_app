import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/cart/presentation/desktop_cart_panel.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _pump({
  required PosBloc posBloc,
  required AuthBloc authBloc,
  VoidCallback? onCheckout,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<PosBloc>.value(value: posBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: DesktopCartPanel(onCheckout: onCheckout ?? () {}),
      ),
    ),
  );
}

void main() {
  late MockPosBloc posBloc;
  late MockAuthBloc authBloc;

  setUp(() {
    posBloc = MockPosBloc();
    authBloc = MockAuthBloc();
    when(() => posBloc.state).thenReturn(PosState.initial());
    when(() => authBloc.state).thenReturn(AuthState.initial());
  });

  testWidgets('has no drag-handle pill (42×5 SizedBox)', (tester) async {
    await tester.pumpWidget(_pump(posBloc: posBloc, authBloc: authBloc));

    final pill = find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 42 && w.height == 5,
    );
    expect(pill, findsNothing);
  });

  testWidgets('checkout FilledButton calls onCheckout', (tester) async {
    var called = false;
    await tester.pumpWidget(_pump(
      posBloc: posBloc,
      authBloc: authBloc,
      onCheckout: () => called = true,
    ));

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('checkout button is disabled when submitStatus is loading',
      (tester) async {
    when(() => posBloc.state).thenReturn(
      PosState.initial().copyWith(submitStatus: PosSubmitStatus.loading),
    );

    await tester.pumpWidget(_pump(posBloc: posBloc, authBloc: authBloc));

    final btn = tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(btn.onPressed, isNull);
  });
}
