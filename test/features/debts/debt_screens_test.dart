import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/debts/data/debt_reader.dart';
import 'package:amana_pos/features/debts/domain/debt_service.dart';
import 'package:amana_pos/features/debts/presentation/customer_picker_sheet.dart';
import 'package:amana_pos/features/debts/presentation/debt_action_sheet.dart';
import 'package:amana_pos/features/debts/presentation/debts_screen.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
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
  late DebtService service;
  late DebtReader reader;
  DebtActor actor = const DebtActor(id: kCashier, name: 'Sara', canManage: true);

  Future<void> seed(WidgetTester t) async {
    await t.runAsync(() async {
      f = await SaleFixture.on(await openTestDb());
      await f.db.insert('customers', {'id': 'c1', 'name': 'Sara Ali', 'phone': '0912', 'json': '{}'});
      await f.db.insert('customers', {'id': 'c2', 'name': 'Omer', 'phone': '0999', 'json': '{}'});
      await f.db.insert('sales', {
        'id': 's1', 'shop_id': kShop, 'customer_id': 'c1', 'status': 'completed',
        'payment_method': 'credit', 'subtotal': '1500', 'discount': '0',
        'tax_amount': '0', 'net_amount': '1500',
        'occurred_at': '2020-01-01T10:00:00.000Z', 'sync_state': 'synced',
      });
      await f.db.insert('sale_payments', {
        'sale_id': 's1', 'position': 0, 'method': 'credit', 'amount': '1500',
      });
      service = DebtService(
        writer: f.writer,
        features: () => const BusinessFeatures(onAccount: true),
        actor: () => actor,
        shopId: () => kShop,
        now: () => f.clock,
      );
      reader = DebtReader(db: f.odb, notifier: f.notifier);
    });
    addTearDown(() async {
      await t.runAsync(() async {
        f.notifier.dispose();
        await f.db.close();
      });
    });
  }

  Widget app(Widget home, {String locale = 'en'}) => MaterialApp(
    theme: AppTheme.light,
    locale: Locale(locale),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  void bigScreen(WidgetTester t) {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  Future<void> openSheet(WidgetTester t, DebtSheetMode mode, {BigInt? balance}) async {
    await t.pumpWidget(app(Builder(
      builder: (ctx) => TextButton(
        onPressed: () => showDebtActionSheet(ctx,
            service: service, mode: mode, customerId: 'c1', balance: balance ?? c('1500')),
        child: const Text('go'),
      ),
    )));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  testWidgets('receive: starts at the whole debt, half chip, button names the amount', (t) async {
    bigScreen(t);
    await seed(t);
    await openSheet(t, DebtSheetMode.receive);
    expect(find.text('Nothing will be left to pay.'), findsOneWidget);
    expect(find.text('Receive 1,500.00'), findsOneWidget);
    await t.tap(find.textContaining('Half'));
    await t.pump();
    expect(find.text('Receive 750.00'), findsOneWidget);
    expect(find.text('750.00 will still be owed.'), findsOneWidget);
  });

  testWidgets('receive: above the balance turns the button off', (t) async {
    bigScreen(t);
    await seed(t);
    await openSheet(t, DebtSheetMode.receive);
    await t.enterText(find.byType(EditableText).first, '1600');
    await t.pump();
    expect(find.textContaining('More than the customer owes'), findsOneWidget);
    final b = t.widget<AppButton>(find.byType(AppButton));
    expect(b.onPressed, isNull);
  });

  testWidgets('receive: saves one payment and closes', (t) async {
    bigScreen(t);
    await seed(t);
    await openSheet(t, DebtSheetMode.receive);
    await t.enterText(find.byType(EditableText).first, '500');
    await t.pump();
    await t.tap(find.byType(AppButton));
    await settle(t);
    final rows = await t.runAsync(() => f.db.query('debt_entries'));
    expect(rows!.single['amount'], '500.00');
    expect(rows.single['method'], 'cash');
    expect(find.text('Receive payment'), findsNothing);
  });

  testWidgets('write off: has a note row and no payment method', (t) async {
    bigScreen(t);
    await seed(t);
    await openSheet(t, DebtSheetMode.writeOff);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Bankak'), findsNothing);
    expect(find.text('Write off 1,500.00'), findsOneWidget);
  });

  testWidgets('debts screen lists debtors with the total', (t) async {
    bigScreen(t);
    await seed(t);
    await t.pumpWidget(app(DebtsScreen(reader: reader)));
    await settle(t);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('1,500.00'), findsWidgets);
    expect(find.text('Omer'), findsNothing);
    expect(find.text('Total owed'), findsOneWidget);
  });

  testWidgets('debts screen with nobody owing says so', (t) async {
    bigScreen(t);
    await seed(t);
    await t.runAsync(() => f.db.delete('sales'));
    await t.runAsync(() => f.db.delete('sale_payments'));
    await t.pumpWidget(app(DebtsScreen(reader: reader)));
    await settle(t);
    expect(find.text('Nobody owes anything.'), findsOneWidget);
  });

  testWidgets('debts screen renders in Arabic', (t) async {
    bigScreen(t);
    await seed(t);
    await t.pumpWidget(app(DebtsScreen(reader: reader), locale: 'ar'));
    await settle(t);
    expect(find.text('الديون'), findsWidgets);
  });

  testWidgets('picker shows owing amount, searches, and returns the pick', (t) async {
    bigScreen(t);
    await seed(t);
    PickCustomer? picked;
    await t.pumpWidget(app(Builder(
      builder: (ctx) => TextButton(
        onPressed: () async => picked = await showCustomerPicker(ctx,
            reader: reader, customers: () => CustomerService(writer: f.writer)),
        child: const Text('go'),
      ),
    )));
    await t.tap(find.text('go'));
    await settle(t);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('Omer'), findsOneWidget);
    expect(find.text('1,500.00'), findsOneWidget);
    await t.enterText(find.byType(EditableText).first, 'ome');
    await settle(t);
    expect(find.text('Sara Ali'), findsNothing);
    await t.tap(find.text('Omer'));
    await settle(t);
    expect(picked!.id, 'c2');
  });

  testWidgets('picker creates a new customer', (t) async {
    bigScreen(t);
    await seed(t);
    PickCustomer? picked;
    await t.pumpWidget(app(Builder(
      builder: (ctx) => TextButton(
        onPressed: () async => picked = await showCustomerPicker(ctx,
            reader: reader, customers: () => CustomerService(writer: f.writer)),
        child: const Text('go'),
      ),
    )));
    await t.tap(find.text('go'));
    await settle(t);
    await t.tap(find.text('New customer'));
    await settle(t);
    await t.enterText(find.byType(EditableText).first, 'Nada');
    await t.pump();
    await t.tap(find.byType(AppButton));
    await settle(t);
    expect(picked!.name, 'Nada');
    final rows = await t.runAsync(() => f.db.query('customers', where: "name='Nada'"));
    expect(rows, hasLength(1));
  });
}
