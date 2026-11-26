import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/stockcount/data/stock_count_reader.dart';
import 'package:amana_pos/features/stockcount/presentation/stock_count_screen.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _AuthState extends Mock implements AuthState {}

void main() {
  late SaleFixture f;
  late StockService service;
  late StockCountReader reader;

  Future<void> pump(
    WidgetTester t, {
    Locale locale = const Locale('en'),
  }) async {
    await t.runAsync(() async {
      f = await SaleFixture.on(await openTestDb());
      for (final id in [kP1, kP2]) {
        await f.db.update(
          'products',
          {
            'json': '{"id":"$id","track_inventory":true,"barcode":"b-$id"}',
            'barcode': 'b-$id',
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      service = StockService(
        writer: f.writer,
        actor: () => const StockActor(
          businessType: AppBusinessType.shop,
          role: AppUserRole.cashier,
          shopId: kShop,
        ),
        now: () => f.clock,
      );
      reader = StockCountReader(db: f.odb);
    });
    addTearDown(() async => f.notifier.dispose());
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final authState = _AuthState();
    when(() => authState.permissions).thenReturn(
      AppPermissions(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
        enabledFeatures: const {},
      ),
    );
    final auth = _Auth();
    when(() => auth.state).thenReturn(authState);
    await t.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: StockCountScreen(
            shopId: kShop,
            reader: reader,
            service: service,
          ),
        ),
      ),
    );
    await t.pump();
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await t.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets(
    'empty state, add all, type counts, apply writes the differences',
    (t) async {
      await pump(t);
      expect(find.text('Start counting'), findsOneWidget);
      expect(t.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);

      await t.tap(find.text('Add all products'));
      await settle(t);
      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('Sugar'), findsOneWidget);

      // Rows are by name: Sugar (shelf 5) then Tea (shelf 10).
      // Sugar counted 5 -> matches. Tea counted 8 -> -2.
      final fields = find.byType(TextField);
      await t.enterText(fields.at(1), '5');
      await t.enterText(fields.at(2), '8');
      await t.pump();
      expect(find.text('−2'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Apply 1 difference'), findsOneWidget);

      await t.tap(find.byType(AppButton));
      await settle(t);
      expect(find.text('Apply the count?'), findsOneWidget);
      await t.tap(find.text('Apply 1 difference').last);
      await settle(t);

      final rows = await t.runAsync(() => f.db.query('outbox'));
      expect(rows!.length, 1);
      expect(rows.single['op'], 'adjust');
    },
  );

  testWidgets('a typed barcode adds the product, a repeat adds one more', (
    t,
  ) async {
    await pump(t);
    final search = find.byType(TextField).first;
    for (var i = 0; i < 2; i++) {
      await t.enterText(search, 'b-$kP1');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await settle(t);
    }
    expect(find.text('Tea'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2'), findsOneWidget);
  });

  testWidgets('a negative count blocks Apply', (t) async {
    await pump(t);
    await t.tap(find.text('Add all products'));
    await settle(t);
    await t.enterText(find.byType(TextField).at(1), '-3');
    await t.pump();
    expect(find.text('A count cannot be negative.'), findsOneWidget);
    expect(t.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
  });

  testWidgets('Arabic renders', (t) async {
    await pump(t, locale: const Locale('ar'));
    expect(find.text('ابدأ الجرد'), findsOneWidget);
  });
}
