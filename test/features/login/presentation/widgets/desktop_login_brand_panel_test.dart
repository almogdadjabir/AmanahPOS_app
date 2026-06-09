import 'package:amana_pos/features/login/presentation/widgets/desktop_login_brand_panel.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPanel(WidgetTester tester) async {
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
}

void main() {
  testWidgets('DesktopLoginBrandPanel renders without error', (tester) async {
    await _pumpPanel(tester);

    expect(find.byType(DesktopLoginBrandPanel), findsOneWidget);
  });

  testWidgets('DesktopLoginBrandPanel shows feature badges', (tester) async {
    await _pumpPanel(tester);

    // Three feature badges must be present
    expect(find.text('Offline-ready'), findsOneWidget);
    expect(find.text('Multi-branch'), findsOneWidget);
    expect(find.text('Secure by design'), findsOneWidget);
  });

  testWidgets('DesktopLoginBrandPanel shows wordmark and headline',
      (tester) async {
    await _pumpPanel(tester);
    expect(find.text('AmanaPOS'), findsOneWidget);
    expect(find.text('POINT OF SALE PLATFORM'), findsOneWidget);
  });
}
