import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/login/presentation/widgets/revoked_pending_notice.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Future<RevokeMarker?> Function() loader) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: RevokedPendingNotice(loader: loader)),
);

void main() {
  testWidgets('marker present -> notice with the count', (t) async {
    await t.pumpWidget(
      _app(
        () async => RevokeMarker(
          reason: 'deviceRevoked',
          pendingCount: 4,
          at: DateTime.utc(2026),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('4 unsynced'), findsOneWidget);
  });

  testWidgets('no marker -> nothing shown', (t) async {
    await t.pumpWidget(_app(() async => null));
    await t.pumpAndSettle();
    expect(find.textContaining('unsynced'), findsNothing);
  });

  testWidgets('loader throws -> nothing shown, no crash', (t) async {
    await t.pumpWidget(_app(() async => throw StateError('x')));
    await t.pumpAndSettle();
    expect(find.textContaining('unsynced'), findsNothing);
  });
}
