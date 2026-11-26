import 'dart:async';

import 'package:amana_pos/features/pairing/domain/pairing_service.dart';
import 'package:amana_pos/features/pairing/presentation/link_pos_screen.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake extends PairingService {
  _Fake() : super(Dio());
  Object? createError;
  int made = 0;
  PairingProgress progress = const PairingProgress(PairingStatus.pending);
  @override
  Future<PairingCode> create({String? businessId}) async {
    if (createError != null) throw createError!;
    made++;
    return PairingCode(
      pairingId: 'p$made',
      code: '48291$made',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ttlSeconds: 300,
    );
  }

  @override
  Future<PairingProgress> status(String id) async => progress;
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: child,
);

void main() {
  test('only link-device addresses are accepted', () {
    expect(
      PairingService.isLinkDeviceCode(
        'https://app.amanapos.com/en/link-device?src=desktop',
      ),
      isTrue,
    );
    expect(PairingService.isLinkDeviceCode('6281234567890'), isFalse);
    expect(PairingService.isLinkDeviceCode('https://x.com/en/other'), isFalse);
    expect(PairingService.isLinkDeviceCode('not a url'), isFalse);
  });

  test('countdown format', () {
    expect(formatCountdown(234), '3:54');
    expect(formatCountdown(-3), '0:00');
  });

  testWidgets('show code, then desktop chooses, then linked', (t) async {
    final f = _Fake();
    await t.pumpWidget(
      _app(LinkPosScreen(service: f, pollEvery: const Duration(seconds: 1))),
    );
    await t.tap(find.text('Show code'));
    await t.pump();
    await t.pump();
    expect(find.text('Expires in 5:00'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    f.progress = const PairingProgress(
      PairingStatus.choosing,
      deviceName: 'Counter 1',
    );
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.textContaining('Counter 1 is choosing'), findsOneWidget);

    f.progress = const PairingProgress(
      PairingStatus.used,
      deviceName: 'Counter 1',
    );
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.text('Counter 1 is linked'), findsOneWidget);
    expect(find.text('Link another'), findsOneWidget);
  });

  testWidgets('code expires after its time and a new code replaces it', (
    t,
  ) async {
    final f = _Fake();
    var now = DateTime(2026, 1, 1, 9);
    await t.pumpWidget(
      _app(
        LinkPosScreen(
          service: f,
          pollEvery: const Duration(hours: 1),
          now: () => now,
        ),
      ),
    );
    await t.tap(find.text('Show code'));
    await t.pump();
    await t.pump();
    now = now.add(const Duration(seconds: 301));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('This code expired. Make a new one.'), findsOneWidget);
    await t.tap(find.text('New code'));
    await t.pump();
    await t.pump();
    expect(f.made, 2);
    expect(find.textContaining('Expires in'), findsOneWidget);
  });

  testWidgets('rate limit and offline show friendly messages', (t) async {
    final f = _Fake()
      ..createError = const PairingException(PairingFailure.rateLimited);
    await t.pumpWidget(_app(LinkPosScreen(service: f)));
    await t.tap(find.text('Show code'));
    await t.pump();
    await t.pump();
    expect(find.text('Too many codes'), findsOneWidget);

    final g = _Fake()
      ..createError = const PairingException(PairingFailure.offline);
    await t.pumpWidget(_app(LinkPosScreen(key: UniqueKey(), service: g)));
    await t.tap(find.text('Show code'));
    await t.pump();
    await t.pump();
    expect(find.text('No internet'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a wrong QR is refused and scanning goes on; a desktop QR works', (
    t,
  ) async {
    GlobalSnackBar.enableTestMode();
    final f = _Fake();
    final answers = <String?>['12345', 'https://app.amanapos.com/en/link-device'];
    var asked = 0;
    await t.pumpWidget(
      _app(
        LinkPosScreen(
          service: f,
          pollEvery: const Duration(hours: 1),
          scan: (_) async => answers[asked++],
        ),
      ),
    );
    await t.tap(find.text('Scan the desktop QR'));
    await t.pump();
    await t.pump();
    await t.pump();
    expect(asked, 2);
    expect(f.made, 1);
    expect(find.textContaining('Expires in'), findsOneWidget);
  });

  testWidgets('Arabic code screen shows digits and Arabic text', (t) async {
    final f = _Fake();
    await t.pumpWidget(
      _app(
        LinkPosScreen(service: f, pollEvery: const Duration(hours: 1)),
        locale: const Locale('ar'),
      ),
    );
    await t.tap(find.text('عرض الرمز'));
    await t.pump();
    await t.pump();
    expect(find.text('رمز جديد'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
