import 'package:amana_pos/features/cart/presentation/discount_sheet.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiscountChoice? result;
  var closed = false;

  Future<void> open(
    WidgetTester t, {
    CartDiscount? initial,
    Locale locale = const Locale('en'),
  }) async {
    result = null;
    closed = false;
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDiscountSheet(
                  context,
                  title: 'T',
                  baseCents: BigInt.from(2000),
                  initial: initial,
                );
                closed = true;
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  testWidgets('percent: shows the new total and returns the discount',
      (t) async {
    await open(t);
    expect(t.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    await t.enterText(find.byType(TextField), '10');
    await t.pump();
    expect(find.text('New total 18.00'), findsOneWidget);
    expect(find.text('Apply 10% off'), findsOneWidget);
    await t.tap(find.byType(AppButton));
    await t.pumpAndSettle();
    expect(closed, isTrue);
    expect(result!.discount, const CartDiscount.percent('10'));
  });

  testWidgets('over 100 percent is refused', (t) async {
    await open(t);
    await t.enterText(find.byType(TextField), '120');
    await t.pump();
    expect(find.text('A percent cannot be more than 100.'), findsOneWidget);
    expect(t.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
  });

  testWidgets('amount above the base is refused, a fair one is accepted',
      (t) async {
    await open(t);
    await t.tap(find.text('Amount'));
    await t.pump();
    await t.enterText(find.byType(TextField), '25');
    await t.pump();
    expect(find.text('The discount cannot be more than 20.00.'), findsOneWidget);
    await t.enterText(find.byType(TextField), '5');
    await t.pump();
    expect(find.text('Apply 5.00 off'), findsOneWidget);
    await t.tap(find.byType(AppButton));
    await t.pumpAndSettle();
    expect(result!.discount, const CartDiscount.amount('5'));
  });

  testWidgets('an existing discount can be removed', (t) async {
    await open(t, initial: const CartDiscount.percent('5'));
    await t.tap(find.text('Remove discount'));
    await t.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNotNull);
    expect(result!.discount, isNull);
  });

  testWidgets('Arabic digits are understood', (t) async {
    await open(t, locale: const Locale('ar'));
    await t.enterText(find.byType(TextField), '١٠');
    await t.pump();
    expect(find.text('الإجمالي الجديد 18.00'), findsOneWidget);
  });
}
