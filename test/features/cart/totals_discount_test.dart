import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/cart/presentation/totals_section.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
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

class _AuthState extends Mock implements AuthState {}

class _UseCase extends Mock implements PosUseCase {}

void main() {
  late SaleFixture f;
  late PosBloc pos;

  Future<void> boot(
    WidgetTester t, {
    required AppUserRole role,
    bool saleOn = true,
  }) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      f = await SaleFixture.on(await openTestDb());
      await f.db.insert('synced_entities', {
        'entity': 'business',
        'id': 'b1',
        'json': '{"sale_discount_enabled":$saleOn}',
      });
      final features = BusinessFeaturesService(db: f.odb, notifier: f.notifier);
      await features.load();
      await getIt.reset();
      getIt.registerSingleton<BusinessFeaturesService>(features);
      getIt.registerSingleton<AppProgressCubit>(AppProgressCubit());
    });
    addTearDown(() async {
      await t.runAsync(() async {
        await getIt.reset();
        f.notifier.dispose();
        await f.db.close();
      });
    });
    final authState = _AuthState();
    when(() => authState.permissions).thenReturn(
      AppPermissions(
        businessType: AppBusinessType.shop,
        role: role,
        enabledFeatures: const {},
      ),
    );
    final auth = _Auth();
    when(() => auth.state).thenReturn(authState);
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
        localizationsDelegates: [
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
                child: TotalsSection(state: s),
              ),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await t.pump(const Duration(milliseconds: 120));
  }

  testWidgets('owner adds a sale discount from the totals', (t) async {
    await boot(t, role: AppUserRole.owner);
    expect(find.text('Add discount'), findsOneWidget);
    await t.tap(find.text('Add discount'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '10');
    await t.pump();
    await t.tap(find.text('Apply 10% off'));
    await t.pumpAndSettle();
    expect(pos.state.saleDiscount, const CartDiscount.percent('10'));
    expect(find.textContaining('Discount −10%'), findsOneWidget);
    expect(find.text('Add discount'), findsNothing);
  });

  testWidgets('a cashier gets no discount control', (t) async {
    await boot(t, role: AppUserRole.cashier);
    expect(find.text('Add discount'), findsNothing);
  });

  testWidgets('switched off: no control, but a discount already given stays',
      (t) async {
    await boot(t, role: AppUserRole.owner, saleOn: false);
    expect(find.text('Add discount'), findsNothing);
    pos.add(const PosSaleDiscountSet(CartDiscount.percent('10')));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Discount −10%'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });
}
