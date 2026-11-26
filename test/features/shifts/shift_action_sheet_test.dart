import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/shifts/domain/shift_reconciler.dart';
import 'package:amana_pos/features/shifts/domain/shift_service.dart';
import 'package:amana_pos/features/shifts/presentation/shift_action_sheet.dart';
import 'package:amana_pos/features/shifts/presentation/shifts_cubit.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

BigInt c(String s) => Cents.parse(s)!;

void main() {
  late SaleFixture f;
  late ShiftsCubit cubit;
  late BusinessFeaturesService featuresService;
  late ShiftService service;

  Future<void> setUpAll_(WidgetTester t) async {
    await t.runAsync(() async {
      f = await SaleFixture.on(await openTestDb());
      await f.db.insert('synced_entities', {
        'entity': 'business',
        'id': 'b1',
        'json': '{"shifts_mode":"manual","cash_drawer_enabled":true}',
      });
      featuresService = BusinessFeaturesService(db: f.odb, notifier: f.notifier);
      await featuresService.load();
      service = ShiftService(
        writer: f.writer,
        state: f.state,
        features: () => featuresService.current,
        actor: () => const ShiftActor(id: kCashier, name: 'Sara', canManage: true),
        shopId: () => kShop,
        now: () => f.clock,
      );
      cubit = ShiftsCubit(
        service: service,
        reconciler: ShiftReconciler(
          service: service,
          db: () => f.odb.database,
          features: () => featuresService.current,
          shopId: () => kShop,
          timezone: () async => null,
        ),
        features: featuresService,
        db: f.odb,
        notifier: f.notifier,
        shopId: () => kShop,
        now: () => f.clock,
      );
    });
    addTearDown(() async {
      await cubit.close();
      await featuresService.dispose();
      f.notifier.dispose();
    });
  }

  Future<void> pumpSheet(
    WidgetTester t,
    ShiftSheetMode mode, {
    BigInt? expected,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showShiftActionSheet(
                  context,
                  cubit: cubit,
                  mode: mode,
                  expected: expected,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  Future<void> settle(WidgetTester t) async {
    // Database work finishes on the real event loop, the widgets on the fake
    // one: alternate until both are quiet. (No pumpAndSettle: the success
    // toast keeps animating.)
    for (var round = 0; round < 6; round++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await t.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('close: shows what it should be and the difference as you type',
      (t) async {
    await setUpAll_(t);
    await t.runAsync(() => service.open(openingCash: c('1285')));
    await pumpSheet(t, ShiftSheetMode.close, expected: c('1285'));

    expect(find.text('1,285.00'), findsOneWidget);
    // The action button is off until an amount is typed.
    final btn = find.byType(AppButton);
    expect(t.widget<AppButton>(btn).onPressed, isNull);

    await t.enterText(find.byType(TextField).first, '1280');
    await t.pump();
    expect(find.text('Short 5.00'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, '1285');
    await t.pump();
    expect(find.text('Exact'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, '1287');
    await t.pump();
    expect(find.text('Over 2.00'), findsOneWidget);
  });

  testWidgets('close: saving closes the shift and the sheet', (t) async {
    await setUpAll_(t);
    await t.runAsync(() => service.open(openingCash: c('100')));
    await pumpSheet(t, ShiftSheetMode.close, expected: c('100'));
    await t.enterText(find.byType(TextField).first, '98');
    await t.pump();
    await t.tap(find.byType(AppButton));
    await settle(t);

    final rows = await t.runAsync(() => f.db.query('shifts'));
    expect(rows!.single['counted_cash'], '98.00');
    expect(rows.single['closed_at'], isNotNull);
    expect(find.text('Should be'), findsNothing); // sheet is gone
  });

  testWidgets('pay out beyond the drawer shows a calm note, still allowed',
      (t) async {
    await setUpAll_(t);
    await t.runAsync(() => service.open(openingCash: c('100')));
    await pumpSheet(t, ShiftSheetMode.payOut, expected: c('100'));
    await t.enterText(find.byType(TextField).at(0), '2000');
    await t.enterText(find.byType(TextField).at(1), 'Supplier');
    await t.pump();
    expect(
      find.text('This is more than the drawer should hold. You can continue.'),
      findsOneWidget,
    );
    await t.tap(find.byType(AppButton));
    await settle(t);
    final m = await t.runAsync(() => f.db.query('cash_movements'));
    expect(m!.single['amount'], '2000.00');
  });

  testWidgets('pay out needs a reason', (t) async {
    await setUpAll_(t);
    await t.runAsync(() => service.open(openingCash: c('100')));
    await pumpSheet(t, ShiftSheetMode.payOut, expected: c('100'));
    await t.enterText(find.byType(TextField).at(0), '5');
    await t.pump();
    expect(
      t.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNull,
    );
  });

  testWidgets('open is pre-filled from the last count', (t) async {
    await setUpAll_(t);
    await t.runAsync(() async {
      await service.open(openingCash: c('100'));
      await service.close(counted: c('130'));
    });
    await pumpSheet(t, ShiftSheetMode.open);
    await settle(t);
    expect(find.text('130.00'), findsOneWidget);
    expect(
      find.text('Carried over from the last count. Change it if the drawer is different.'),
      findsOneWidget,
    );
  });
}
