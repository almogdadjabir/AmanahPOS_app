import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/shifts/domain/shift_reconciler.dart';
import 'package:amana_pos/features/shifts/domain/shift_service.dart';
import 'package:amana_pos/features/shifts/presentation/shifts_cubit.dart';
import 'package:amana_pos/features/shifts/presentation/shifts_screen.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _FakeAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

BigInt c(String s) => Cents.parse(s)!;

void main() {
  late SaleFixture f;
  late ShiftsCubit cubit;
  late BusinessFeaturesService features;
  late ShiftService service;

  Future<void> boot(
    WidgetTester t,
    Map<String, Object?> business, {
    String role = 'owner',
    Locale locale = const Locale('en'),
  }) async {
    await t.runAsync(() async {
      f = await SaleFixture.on(await openTestDb());
      await f.db.insert('synced_entities', {
        'entity': 'business',
        'id': 'b1',
        'json': Uri.decodeFull(
          '{${business.entries.map((e) => '"${e.key}":${e.value is String ? '"${e.value}"' : e.value}').join(',')}}',
        ),
      });
      features = BusinessFeaturesService(db: f.odb, notifier: f.notifier);
      await features.load();
      service = ShiftService(
        writer: f.writer,
        state: f.state,
        features: () => features.current,
        actor: () =>
            const ShiftActor(id: kCashier, name: 'Sara', canManage: true),
        shopId: () => kShop,
        now: () => f.clock,
      );
      cubit = ShiftsCubit(
        service: service,
        reconciler: ShiftReconciler(
          service: service,
          db: () => f.odb.database,
          features: () => features.current,
          shopId: () => kShop,
          timezone: () async => null,
        ),
        features: features,
        db: f.odb,
        notifier: f.notifier,
        shopId: () => kShop,
        now: () => f.clock,
      );
    });
    addTearDown(() async {
      await cubit.close();
      await features.dispose();
      f.notifier.dispose();
    });
    final auth = _FakeAuth();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: AuthState(profile: User(id: kCashier, role: role)),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ShiftsCubit>.value(value: cubit),
          ],
          child: const ShiftsScreen(),
        ),
      ),
    );
    await _settle(t);
  }

  testWidgets('shifts off: says so, no actions', (t) async {
    await boot(t, {});
    expect(find.text('Shifts are off'), findsOneWidget);
    expect(find.text('Open shift'), findsNothing);
  });

  testWidgets('manual, no shift: offers to open it', (t) async {
    await boot(t, {'shifts_mode': 'manual'});
    expect(find.text('No shift is open'), findsOneWidget);
    expect(find.text('Open shift'), findsOneWidget);
    expect(find.text('No earlier shifts yet.'), findsOneWidget);
  });

  testWidgets('a cashier cannot open unless the owner allows it', (t) async {
    await boot(t, {'shifts_mode': 'manual'}, role: 'cashier');
    expect(find.text('No shift is open'), findsOneWidget);
    expect(find.text('Open shift'), findsNothing);
  });

  testWidgets('open shift with the drawer on shows the cash maths', (t) async {
    await boot(t, {'shifts_mode': 'manual', 'cash_drawer_enabled': true});
    await t.runAsync(() => service.open(openingCash: c('500')));
    await _settle(t);
    expect(find.text('Cash that should be in the drawer'), findsOneWidget);
    expect(find.text('500.00'), findsWidgets);
    expect(find.widgetWithText(AppButton, 'Pay in'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Pay out'), findsOneWidget);
    expect(find.text('Close shift'), findsOneWidget);
  });

  testWidgets('open shift with the drawer off is a sales summary only',
      (t) async {
    await boot(t, {'shifts_mode': 'manual'});
    await t.runAsync(() => service.open());
    await _settle(t);
    expect(find.text('Current shift'), findsOneWidget);
    expect(find.text('Cash that should be in the drawer'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Pay in'), findsNothing);
    expect(find.text('Close shift'), findsOneWidget);
  });

  testWidgets('history shows exact, short and needs-count pills', (t) async {
    await boot(t, {'shifts_mode': 'manual', 'cash_drawer_enabled': true});
    await t.runAsync(() async {
      f.clock = DateTime.utc(2026, 11, 10, 8);
      await service.open(openingCash: c('100'));
      f.clock = DateTime.utc(2026, 11, 10, 20);
      await service.close(counted: c('100'));
      f.clock = DateTime.utc(2026, 11, 11, 8);
      await service.open(openingCash: c('100'));
      f.clock = DateTime.utc(2026, 11, 11, 20);
      await service.close(counted: c('95'));
      f.clock = DateTime.utc(2026, 11, 12, 8);
      await service.open(openingCash: c('95'));
      f.clock = DateTime.utc(2026, 11, 12, 20);
      await service.close(); // no count
    });
    await _settle(t);
    expect(find.text('Exact'), findsOneWidget);
    expect(find.text('Short 5.00'), findsOneWidget);
    expect(find.text('Needs count'), findsOneWidget);
    expect(find.text('Shifts waiting for a cash count: 1'), findsOneWidget);
  });

  testWidgets('Arabic renders right to left', (t) async {
    await boot(
      t,
      {'shifts_mode': 'manual'},
      locale: const Locale('ar'),
    );
    expect(find.text('لا توجد وردية مفتوحة'), findsOneWidget);
  });
}

Future<void> _settle(WidgetTester t) async {
  for (var round = 0; round < 6; round++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await t.pump(const Duration(milliseconds: 120));
  }
}
