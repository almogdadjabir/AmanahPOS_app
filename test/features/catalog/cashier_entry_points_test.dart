// Phase 3 Task 7 (spec builder-check 5): catalog writes are owner/manager
// only, so a cashier gets no add / edit / delete entry point on the
// products list, product detail, categories list, category detail and the
// vendors sheet. The services refuse cashiers too (bloc tests).
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/features/category/presentation/category_screen.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/sheets/vendors_sheet.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/product_detail_screen.dart';
import 'package:amana_pos/features/products/presentation/product_screen.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockProducts extends MockBloc<ProductEvent, ProductState>
    implements ProductBloc {}

class _MockCategories extends MockBloc<CategoryEvent, CategoryState>
    implements CategoryBloc {}

class _MockVendors extends MockBloc<VendorsEvent, VendorsState>
    implements VendorsBloc {}

class _MockDashboard
    extends MockBloc<DashboardSummaryEvent, DashboardSummaryState>
    implements DashboardSummaryBloc {}

const _product = ProductData(
  id: 'p1',
  name: 'Tea',
  price: '5.00',
  category: 'c1',
  isActive: true,
  trackInventory: true,
  stockLevel: 3,
);
final _category = CategoryData(id: 'c1', name: 'Drinks', productCount: 1);

void main() {
  late _MockAuth auth;
  late _MockProducts products;
  late _MockCategories categories;
  late _MockVendors vendors;
  late _MockDashboard dashboard;

  void signIn(String role, {String business = 'restaurant'}) {
    final s = AuthState(
      isLoggedIn: true,
      profile: User(id: 'u1', role: role),
      defaultBusiness: BusinessData(id: 't1', businessType: business),
    );
    whenListen(auth, const Stream<AuthState>.empty(), initialState: s);
  }

  setUp(() {
    auth = _MockAuth();
    products = _MockProducts();
    categories = _MockCategories();
    vendors = _MockVendors();
    dashboard = _MockDashboard();
    whenListen(
      products,
      const Stream<ProductState>.empty(),
      initialState: ProductState(
        productStatus: ProductStatus.success,
        products: const [_product],
        categories: [_category],
        isGrid: false,
      ),
    );
    whenListen(
      categories,
      const Stream<CategoryState>.empty(),
      initialState: CategoryState(
        categoryStatus: CategoryStatus.success,
        categoryList: [_category],
        productsStatus: CategoryProductsStatus.success,
        products: const [_product],
      ),
    );
    whenListen(
      vendors,
      const Stream<VendorsState>.empty(),
      initialState: const VendorsState(
        status: VendorsStatus.success,
        vendors: [VendorData(id: 'v1', name: 'Acme', isActive: true)],
      ),
    );
    whenListen(
      dashboard,
      const Stream<DashboardSummaryState>.empty(),
      initialState: const DashboardSummaryState(),
    );
  });

  Widget app(Widget home) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<ProductBloc>.value(value: products),
      BlocProvider<CategoryBloc>.value(value: categories),
      BlocProvider<VendorsBloc>.value(value: vendors),
      BlocProvider<DashboardSummaryBloc>.value(value: dashboard),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  List<String> swipeLabels(WidgetTester tester) => [
    for (final w in tester.widgetList<AppSwipeActions>(
      find.byType(AppSwipeActions),
    ))
      for (final a in w.actions) a.label,
  ];

  for (final (role, canEdit) in [
    ('cashier', false),
    ('manager', true),
    ('owner', true),
  ]) {
    group(role, () {
      setUp(() => signIn(role));

      testWidgets('products list: add and delete '
          '${canEdit ? 'shown' : 'hidden'}', (tester) async {
        await tester.pumpWidget(app(const ProductsScreen(isWithAppbar: true)));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('products-add')),
          canEdit ? findsOneWidget : findsNothing,
        );
        expect(swipeLabels(tester).contains('Delete'), canEdit);
      });

      testWidgets('product detail: edit ${canEdit ? 'shown' : 'hidden'}', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(const ProductDetailScreen(product: _product)),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('product-edit')),
          canEdit ? findsOneWidget : findsNothing,
        );
      });

      testWidgets('categories list: add, edit and delete '
          '${canEdit ? 'shown' : 'hidden'}', (tester) async {
        await tester.pumpWidget(
          app(const CategoriesScreen(isWithAppbar: true)),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('categories-add')),
          canEdit ? findsOneWidget : findsNothing,
        );
        expect(swipeLabels(tester), canEdit ? ['Edit', 'Delete'] : isEmpty);
      });

      testWidgets('category detail: add product and edit/delete menu '
          '${canEdit ? 'shown' : 'hidden'}', (tester) async {
        await tester.pumpWidget(app(CategoryDetailScreen(category: _category)));
        await tester.pump();
        expect(
          find.byIcon(PhosphorIconsRegular.plus),
          canEdit ? findsOneWidget : findsNothing,
        );
        final menus = find.byWidgetPredicate((w) => w is PopupMenuButton);
        expect(menus, canEdit ? findsOneWidget : findsNothing);
      });

      testWidgets('vendors sheet: add and edit/deactivate '
          '${canEdit ? 'shown' : 'hidden'}', (tester) async {
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showVendorsSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Acme'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('vendors-add')),
          canEdit ? findsOneWidget : findsNothing,
        );
        expect(
          find.byWidgetPredicate((w) => w is PopupMenuButton),
          canEdit ? findsOneWidget : findsNothing,
        );
      });
    });
  }

  test('AppPermissions.canEditCatalog: owner and manager only', () {
    for (final (role, can) in [
      ('owner', true),
      ('manager', true),
      ('cashier', false),
      ('staff', false),
      (null, false),
    ]) {
      expect(
        AppPermissions.from(
          businessType: 'shop',
          userRole: role,
        ).canEditCatalog,
        can,
        reason: '$role',
      );
    }
  });
}
