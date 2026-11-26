import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/presentation/widgets/split_payment_sheet.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<SalePaymentPart>? result;
  var closed = false;

  Future<void> open(
    WidgetTester t, {
    bool bankakReady = true,
    String locale = 'en',
  }) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    result = null;
    closed = false;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () async {
              result = await showSplitPaymentSheet(
                c,
                total: BigInt.from(500000),
                bankakReady: bankakReady,
              );
              closed = true;
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  AppButton confirm(WidgetTester t) => t.widget<AppButton>(find.byType(AppButton));

  testWidgets('confirm is off until the parts add up, fill rest completes it', (t) async {
    await open(t);
    expect(confirm(t).onPressed, isNull);
    expect(find.text('Left'), findsOneWidget);

    await t.enterText(find.byType(EditableText).first, '3000');
    await t.pump();
    expect(find.text('2,000.00'), findsWidgets);
    expect(confirm(t).onPressed, isNull);

    await t.tap(find.text('Fill rest').last);
    await t.pump();
    expect(find.text('Paid in full'), findsOneWidget);
    expect(confirm(t).onPressed, isNotNull);

    await t.tap(find.byType(AppButton));
    await t.pump(const Duration(milliseconds: 400));
    expect(closed, isTrue);
    expect([for (final p in result!) '${p.method}:${p.amount}'], [
      'cash:3000.00',
      'bankak:2000.00',
    ]);
  });

  testWidgets('too much shows Over by and keeps confirm off', (t) async {
    await open(t);
    await t.enterText(find.byType(EditableText).first, '5500');
    await t.pump();
    expect(find.text('Over by'), findsOneWidget);
    expect(confirm(t).onPressed, isNull);
  });

  testWidgets('Bankak not set up shows the hint and only cash can pay', (t) async {
    await open(t, bankakReady: false);
    expect(find.text('Set up your Bankak account first'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    await t.enterText(find.byType(EditableText).first, '5000');
    await t.pump();
    expect(confirm(t).onPressed, isNotNull);
  });

  testWidgets('Arabic renders', (t) async {
    await open(t, locale: 'ar');
    expect(find.text('الدفع المجزأ'), findsOneWidget);
  });
}
