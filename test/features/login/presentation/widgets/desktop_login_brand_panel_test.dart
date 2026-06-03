import 'package:amana_pos/features/login/presentation/widgets/desktop_login_brand_panel.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DesktopLoginBrandPanel renders without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: DesktopLoginBrandPanel()),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(DesktopLoginBrandPanel), findsOneWidget);
  });

  testWidgets('DesktopLoginBrandPanel shows feature badges', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: DesktopLoginBrandPanel()),
            ],
          ),
        ),
      ),
    );

    // Three feature badges must be present
    expect(find.text('Offline-ready'), findsOneWidget);
    expect(find.text('Multi-branch'), findsOneWidget);
    expect(find.text('Secure'), findsOneWidget);
  });
}
