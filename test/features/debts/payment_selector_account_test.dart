import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/cart/presentation/payment_selector.dart';
import 'package:amana_pos/features/debts/data/debt_reader.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _UseCase extends Mock implements PosUseCase {}

void main() {
  late SaleFixture f;
  late PosBloc pos;
  late _Auth auth;

  Future<void> boot(WidgetTester t, {required bool onAccount}) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      f = await SaleFixture.on(await openTestDb());
      await f.db.insert('synced_entities', {
        'entity': 'business',
        'id': 'b1',
        'json': '{"on_account_enabled":$onAccount,"split_payments_enabled":true}',
      });
      await f.db.insert('customers', {'id': 'c1', 'name': 'Sara Ali', 'phone': '0912', 'json': '{}'});
      await f.db.insert('sales', {
        'id': 's1', 'shop_id': kShop, 'customer_id': 'c1', 'status': 'completed',
        'payment_method': 'credit', 'subtotal': '1200', 'discount': '0',
        'tax_amount': '0', 'net_amount': '1200',
        'occurred_at': '2020-01-01T10:00:00.000Z', 'sync_state': 'synced',
      });
      await f.db.insert('sale_payments', {
        'sale_id': 's1', 'position': 0, 'method': 'credit', 'amount': '1200',
      });
      final features = BusinessFeaturesService(db: f.odb, notifier: f.notifier);
      await features.load();
      await getIt.reset();
      getIt.registerSingleton<BusinessFeaturesService>(features);
      getIt.registerSingleton<DebtReader>(DebtReader(db: f.odb, notifier: f.notifier));
      getIt.registerSingleton<AppProgressCubit>(AppProgressCubit());
    });
    addTearDown(() async {
      await t.runAsync(() async {
        await getIt.reset();
        f.notifier.dispose();
        await f.db.close();
      });
    });
    auth = _Auth();
    when(() => auth.state).thenReturn(const AuthState());
    pos = PosBloc(useCase: _UseCase());
    addTearDown(pos.close);
    pos.add(PosAddProduct(
      ProductData.fromJson(const {
        'id': 'p1', 'name': 'W', 'price': '100.00', 'track_inventory': false,
      }),
      ignoreStockLimit: true,
    ));
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<PosBloc>.value(value: pos),
          ],
          child: Scaffold(
            body: BlocBuilder<PosBloc, PosState>(
              builder: (_, s) => SingleChildScrollView(
                child: PaymentSelector(paymentMethod: s.paymentMethod),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(t);
  }

  testWidgets('On account on: Account option and an optional customer row', (t) async {
    await boot(t, onAccount: true);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Add (optional)'), findsOneWidget);
  });

  testWidgets('On account off: no Account option, no customer row', (t) async {
    await boot(t, onAccount: false);
    expect(find.text('Account'), findsNothing);
    expect(find.text('Add (optional)'), findsNothing);
    expect(find.text('Split'), findsOneWidget);
  });

  testWidgets('Account with no customer opens the picker; picking selects On account and shows what is owed', (t) async {
    await boot(t, onAccount: true);
    await t.tap(find.text('Account'));
    await settle(t);
    expect(find.text('Sara Ali'), findsOneWidget);
    await t.tap(find.text('Sara Ali'));
    await settle(t);
    expect(pos.state.paymentMethod, 'credit');
    expect(pos.state.customerId, 'c1');
    expect(find.textContaining('Owes 1,200.00 now'), findsOneWidget);
    expect(find.textContaining('After this sale: 1,300.00'), findsOneWidget);
  });

  testWidgets('removing the customer puts Cash back', (t) async {
    await boot(t, onAccount: true);
    pos.add(const PosCustomerSelected(id: 'c1', name: 'Sara Ali'));
    pos.add(const PosPaymentMethodChanged('credit'));
    await settle(t);
    await t.tap(find.text('Remove'));
    await settle(t);
    expect(pos.state.paymentMethod, 'cash');
    expect(pos.state.customerId, isNull);
  });
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 100));
  }
}
