import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/inventory_screen.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _AuthState extends Mock implements AuthState {}

class _Inv extends MockBloc<InventoryEvent, InventoryState>
    implements InventoryBloc {}

class _Exp extends MockBloc<ExpiryEvent, ExpiryState> implements ExpiryBloc {}

class _Prod extends MockBloc<ProductEvent, ProductState>
    implements ProductBloc {}

class _Pos extends MockBloc<PosEvent, PosState> implements PosBloc {}

class _Features extends Mock implements BusinessFeaturesService {}

void main() {
  setUpAll(() {
    final f = _Features();
    when(() => f.current).thenReturn(const BusinessFeatures());
    when(() => f.changes).thenAnswer((_) => const Stream.empty());
    if (getIt.isRegistered<BusinessFeaturesService>()) {
      getIt.unregister<BusinessFeaturesService>();
    }
    getIt.registerSingleton<BusinessFeaturesService>(f);
  });

  Future<void> pump(
    WidgetTester t, {
    required AppBusinessType type,
    required AppUserRole role,
    Locale locale = const Locale('en'),
  }) async {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final authState = _AuthState();
    when(() => authState.permissions).thenReturn(
      AppPermissions(
        businessType: type,
        role: role,
        // The old plan flag must make no difference.
        enabledFeatures: const {
          AppPermissions.inventoryInboundReceivingFeature: true,
        },
      ),
    );
    when(() => authState.profile).thenReturn(null);
    final auth = _Auth();
    when(() => auth.state).thenReturn(authState);

    final inv = _Inv();
    when(() => inv.state).thenReturn(
      const InventoryState(
        status: InventoryStatus.success,
        stockList: [
          StockData(
            id: 's1',
            product: 'p1',
            productName: 'Tea',
            quantity: '2',
            isLowStock: true,
          ),
          StockData(
            id: 's2',
            product: 'p2',
            productName: 'Sugar',
            quantity: '0',
            isOutOfStock: true,
          ),
        ],
      ),
    );
    final exp = _Exp();
    when(() => exp.state).thenReturn(const ExpiryState());
    final prod = _Prod();
    when(() => prod.state).thenReturn(const ProductState());
    final pos = _Pos();
    when(() => pos.state).thenReturn(const PosState());

    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<InventoryBloc>.value(value: inv),
          BlocProvider<ExpiryBloc>.value(value: exp),
          BlocProvider<ProductBloc>.value(value: prod),
          BlocProvider<PosBloc>.value(value: pos),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InventoryScreen(),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
  }

  for (final type in [AppBusinessType.shop]) {
    for (final role in [AppUserRole.owner, AppUserRole.manager]) {
      testWidgets('basic stock only: $type/$role', (t) async {
        await pump(t, type: type, role: role);
        // Kept: stock list rows, stats, expiry report entry, add stock.
        expect(find.text('Tea'), findsWidgets);
        expect(find.text('Expiry report'), findsOneWidget);
        expect(find.text('Add stock'), findsOneWidget);
        expect(find.text('Stock count'), findsOneWidget);
        // Actions are pinned ABOVE the stock list (easy to reach).
        expect(
          t.getTopLeft(find.text('Expiry report')).dy,
          lessThan(t.getTopLeft(find.text('Tea').first).dy),
        );
        // Hidden: vendors, receipts, the receive flow.
        expect(find.text('Vendors'), findsNothing);
        expect(find.text('Receipts'), findsNothing);
        expect(find.text('Receive stock'), findsNothing);
      });
    }
  }

  testWidgets('Arabic / RTL renders the same basic set', (t) async {
    await pump(
      t,
      type: AppBusinessType.shop,
      role: AppUserRole.owner,
      locale: const Locale('ar'),
    );
    expect(find.text('الموردون'), findsNothing);
    expect(find.text('تقرير الصلاحية'), findsOneWidget);
  });
}
