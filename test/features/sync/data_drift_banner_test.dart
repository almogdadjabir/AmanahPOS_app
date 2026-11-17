import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/sync/presentation/widgets/data_drift_banner.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

AuditState _st(String status) =>
    AuditState(status: status, at: DateTime.utc(2026, 11, 17));

void main() {
  testWidgets('owner + drift shows the banner', (t) async {
    await t.pumpWidget(
      _app(DataDriftBannerView(isOwner: true, state: _st(AuditState.drift))),
    );
    expect(find.text('Some numbers may be off'), findsOneWidget);
  });

  testWidgets('owner + ok / null shows nothing', (t) async {
    await t.pumpWidget(
      _app(DataDriftBannerView(isOwner: true, state: _st(AuditState.ok))),
    );
    expect(find.text('Some numbers may be off'), findsNothing);
    await t.pumpWidget(
      _app(const DataDriftBannerView(isOwner: true, state: null)),
    );
    expect(find.text('Some numbers may be off'), findsNothing);
  });

  testWidgets('cashier + drift shows nothing', (t) async {
    await t.pumpWidget(
      _app(DataDriftBannerView(isOwner: false, state: _st(AuditState.drift))),
    );
    expect(find.text('Some numbers may be off'), findsNothing);
  });

  testWidgets('Arabic locale renders the Arabic title', (t) async {
    await t.pumpWidget(
      _app(
        DataDriftBannerView(isOwner: true, state: _st(AuditState.drift)),
        locale: const Locale('ar'),
      ),
    );
    expect(find.text('قد تكون بعض الأرقام غير دقيقة'), findsOneWidget);
  });
}
