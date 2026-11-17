import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/offline/presentation/first_setup_screen.dart';
import 'package:amana_pos/core/sync/sync_engine.dart' show SyncBlockReason;
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockOffline extends MockBloc<OfflineStatusEvent, OfflineStatusState>
    implements OfflineStatusBloc {}

const _accountReasons = [
  SyncBlockReason.tokenExpired,
  SyncBlockReason.accountDisabled,
  SyncBlockReason.deviceRevoked,
  SyncBlockReason.noSession,
];

void main() {
  Widget wrap(
    FirstSetupStatus status, {
    VoidCallback? onRetry,
    VoidCallback? onSignOut,
    Locale locale = const Locale('en'),
  }) => MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FirstSetupView(
      status: status,
      onRetry: onRetry ?? () {},
      onSignOut: onSignOut ?? () {},
    ),
  );

  const running = FirstSetupStatus.running(
    entity: 'product',
    index: 3,
    count: 15,
    rowsApplied: 120,
  );

  Future<void> pump(WidgetTester tester, Widget w) async {
    await tester.pumpWidget(w);
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('running: step N of M, rows, current step highlighted, no '
      'retry', (tester) async {
    await pump(tester, wrap(running));
    expect(find.text('Setting up your business'), findsOneWidget);
    expect(find.textContaining('Step 4 of 15'), findsOneWidget);
    expect(find.textContaining('120 records saved'), findsOneWidget);
    // product belongs to the catalog step.
    final current = find.byKey(const ValueKey('fs-step-current'));
    expect(current, findsOneWidget);
    expect(
      find.descendant(
        of: current,
        matching: find.text('Products and categories'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(FirstSetupView.retryKey), findsNothing);
    expect(find.byKey(const ValueKey('fs-step-done-0')), findsOneWidget);
  });

  testWidgets('required: preparing text and a retry', (tester) async {
    var taps = 0;
    await pump(
      tester,
      wrap(const FirstSetupStatus.required(), onRetry: () => taps++),
    );
    expect(find.textContaining('Getting ready'), findsOneWidget);
    await tester.tap(find.byKey(FirstSetupView.retryKey));
    expect(taps, 1);
  });

  testWidgets('blockedOffline: offline message and retry fires', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      wrap(const FirstSetupStatus.blockedOffline(), onRetry: () => taps++),
    );
    expect(
      find.textContaining('Internet is required only for first setup'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(FirstSetupView.retryKey));
    await tester.pump();
    await tester.tap(find.byKey(FirstSetupView.retryKey));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('blockedServer: server-not-ready message and retry fires', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      wrap(const FirstSetupStatus.blockedServer(), onRetry: () => taps++),
    );
    expect(find.text('Server not ready'), findsOneWidget);
    await tester.ensureVisible(find.byKey(FirstSetupView.retryKey));
    await tester.pump();
    await tester.tap(find.byKey(FirstSetupView.retryKey));
    await tester.pump();
    expect(taps, 1);
  });

  // F7: each account/session block shows its own message (en + ar), never
  // the generic 'Getting ready' text, and keeps the sign-out way out.
  const accountTitles = {
    SyncBlockReason.tokenExpired: 'Session expired',
    SyncBlockReason.accountDisabled: 'Account disabled',
    SyncBlockReason.deviceRevoked: 'Device removed',
    SyncBlockReason.noSession: 'Not signed in',
  };
  for (final r in _accountReasons) {
    testWidgets('blockedAccount(${r.name}): its own message + sign out', (
      tester,
    ) async {
      await pump(tester, wrap(FirstSetupStatus.blockedAccount(r)));
      expect(find.text(accountTitles[r]!), findsOneWidget);
      for (final other in _accountReasons.where((o) => o != r)) {
        expect(find.text(accountTitles[other]!), findsNothing);
      }
      expect(find.textContaining('Getting ready'), findsNothing);
      expect(find.text('Server not ready'), findsNothing);
      expect(find.byKey(FirstSetupView.signOutKey), findsOneWidget);
    });

    testWidgets('blockedAccount(${r.name}) in Arabic: no overflow, not the '
        'English text', (tester) async {
      await pump(
        tester,
        wrap(FirstSetupStatus.blockedAccount(r), locale: const Locale('ar')),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(accountTitles[r]!), findsNothing);
      expect(find.byKey(FirstSetupView.signOutKey), findsOneWidget);
    });
  }

  testWidgets('done: images keep downloading (non-blocking note)', (
    tester,
  ) async {
    await pump(tester, wrap(const FirstSetupStatus.done()));
    expect(find.textContaining('Images'), findsOneWidget);
    expect(find.byKey(FirstSetupView.retryKey), findsNothing);
    expect(find.byKey(const ValueKey('fs-step-current')), findsNothing);
  });

  testWidgets('Arabic renders right-to-left without overflow', (tester) async {
    for (final s in [
      running,
      const FirstSetupStatus.blockedOffline(),
      const FirstSetupStatus.blockedServer(),
      const FirstSetupStatus.required(),
      const FirstSetupStatus.done(),
    ]) {
      await pump(tester, wrap(s, locale: const Locale('ar')));
      expect(tester.takeException(), isNull, reason: '$s');
      final dir = Directionality.of(
        tester.element(find.byType(FirstSetupView)),
      );
      expect(dir, TextDirection.rtl);
    }
    await pump(tester, wrap(running, locale: const Locale('ar')));
    expect(find.text('تجهيز نشاطك التجاري'), findsOneWidget);
  });

  testWidgets('small phone (320x568) fits every state', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final s in [
      running,
      const FirstSetupStatus.blockedOffline(),
      const FirstSetupStatus.blockedServer(),
    ]) {
      await pump(tester, wrap(s));
      expect(tester.takeException(), isNull, reason: '$s');
    }
  });

  // Review I1: a blocking first setup always has a way out.
  testWidgets('sign out is offered in every blocking state and fires', (
    tester,
  ) async {
    for (final st in [
      const FirstSetupStatus.required(),
      running,
      const FirstSetupStatus.blockedOffline(),
      const FirstSetupStatus.blockedServer(),
      for (final r in _accountReasons) FirstSetupStatus.blockedAccount(r),
    ]) {
      var taps = 0;
      await pump(tester, wrap(st, onSignOut: () => taps++));
      final btn = find.byKey(FirstSetupView.signOutKey);
      expect(btn, findsOneWidget, reason: '$st');
      await tester.ensureVisible(btn);
      await tester.pump();
      await tester.tap(btn);
      await tester.pump();
      expect(taps, 1, reason: '$st');
    }
    await pump(tester, wrap(const FirstSetupStatus.done()));
    expect(find.byKey(FirstSetupView.signOutKey), findsNothing);
  });

  group('FirstSetupBody wiring', () {
    late _MockAuth auth;
    late _MockOffline offline;

    setUpAll(() => registerFallbackValue(const OnLogoutEvent()));

    setUp(() {
      auth = _MockAuth();
      offline = _MockOffline();
      when(() => offline.state).thenReturn(
        OfflineStatusState.initial().copyWith(
          setupStatus: const FirstSetupStatus.blockedServer(),
        ),
      );
    });

    Widget body() => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<OfflineStatusBloc>.value(
        value: offline,
        child: FirstSetupBody(authBloc: auth),
      ),
    );

    testWidgets('sign out dispatches the local-only logout event (F2: works '
        'offline when nothing is unsynced)', (tester) async {
      when(() => auth.state).thenReturn(AuthState.initial());
      await pump(tester, body());
      await tester.ensureVisible(find.byKey(FirstSetupView.signOutKey));
      await tester.pump();
      await tester.tap(find.byKey(FirstSetupView.signOutKey));
      await tester.pump();
      verify(() => auth.add(const OnLogoutEvent(localOnly: true))).called(1);
      verifyNever(() => auth.add(const OnLogoutEvent()));
    });

    testWidgets('a refused logout shows the gate message', (tester) async {
      final failed = AuthState.initial().copyWith(
        const AuthStateUpdate(
          authStatus: AuthStatus.failure,
          responseError: 'gate says no',
        ),
      );
      whenListen(
        auth,
        Stream.fromIterable([failed]),
        initialState: AuthState.initial(),
      );
      await pump(tester, body());
      await tester.pump();
      expect(find.text('gate says no'), findsOneWidget);
    });
  });

  test('every first-setup string exists in en and ar', () {
    Map<String, dynamic> load(String f) =>
        jsonDecode(File('lib/l10n/$f').readAsStringSync())
            as Map<String, dynamic>;
    final en = load('app_en.arb');
    final ar = load('app_ar.arb');
    final keys = en.keys.where((k) => k.startsWith('fs')).toList();
    expect(keys.length, greaterThanOrEqualTo(10));
    for (final k in keys) {
      expect(ar.containsKey(k), isTrue, reason: 'ar lacks $k');
      expect((ar[k] as String).trim(), isNotEmpty);
    }
  });
}
