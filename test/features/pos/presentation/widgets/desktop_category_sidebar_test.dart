import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/desktop_category_sidebar.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}
class MockProductBloc extends MockBloc<ProductEvent, ProductState> implements ProductBloc {}
class MockDashboardSummaryBloc
    extends MockBloc<DashboardSummaryEvent, DashboardSummaryState>
    implements DashboardSummaryBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _FakePosEvent extends Fake implements PosEvent {}

Widget _pumpSidebar({
  required PosBloc posBloc,
  required ProductBloc productBloc,
  required DashboardSummaryBloc dashBloc,
  required AuthBloc authBloc,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<PosBloc>.value(value: posBloc),
          BlocProvider<ProductBloc>.value(value: productBloc),
          BlocProvider<DashboardSummaryBloc>.value(value: dashBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const Row(
          children: [DesktopCategorySidebar()],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePosEvent());
  });

  late MockPosBloc posBloc;
  late MockProductBloc productBloc;
  late MockDashboardSummaryBloc dashBloc;
  late MockAuthBloc authBloc;

  setUp(() {
    posBloc = MockPosBloc();
    productBloc = MockProductBloc();
    dashBloc = MockDashboardSummaryBloc();
    authBloc = MockAuthBloc();

    when(() => posBloc.state).thenReturn(PosState.initial());
    when(() => productBloc.state).thenReturn(
      ProductState.initial().copyWith(
        categories: [
          CategoryData(id: 'cat1', name: 'Beverages'),
        ],
      ),
    );
    when(() => dashBloc.state).thenReturn(const DashboardSummaryState());
    when(() => authBloc.state).thenReturn(AuthState.initial());
  });

  testWidgets('renders category from ProductBloc', (tester) async {
    await tester.pumpWidget(_pumpSidebar(
      posBloc: posBloc,
      productBloc: productBloc,
      dashBloc: dashBloc,
      authBloc: authBloc,
    ));

    expect(find.text('Beverages'), findsOneWidget);
  });

  testWidgets('tapping a category dispatches PosCategoryChanged',
      (tester) async {
    await tester.pumpWidget(_pumpSidebar(
      posBloc: posBloc,
      productBloc: productBloc,
      dashBloc: dashBloc,
      authBloc: authBloc,
    ));

    await tester.tap(find.text('Beverages'));
    await tester.pump();

    verify(() => posBloc.add(const PosCategoryChanged('cat1'))).called(1);
  });

  testWidgets('is exactly 160px wide', (tester) async {
    await tester.pumpWidget(_pumpSidebar(
      posBloc: posBloc,
      productBloc: productBloc,
      dashBloc: dashBloc,
      authBloc: authBloc,
    ));

    final box = tester.renderObject<RenderBox>(
      find.byType(DesktopCategorySidebar),
    );
    expect(box.size.width, equals(160.0));
  });

  testWidgets('tapping All Items dispatches PosCategoryChanged(null)',
      (tester) async {
    // Start with a real category selected so "All" is not selected and its
    // onTap is active.
    when(() => posBloc.state).thenReturn(
      PosState.initial().copyWith(selectedCategoryId: 'cat1'),
    );

    await tester.pumpWidget(_pumpSidebar(
      posBloc: posBloc,
      productBloc: productBloc,
      dashBloc: dashBloc,
      authBloc: authBloc,
    ));

    // posAllCategory resolves to "All" in the English locale
    await tester.tap(find.text('All'));
    await tester.pump();

    verify(() => posBloc.add(const PosCategoryChanged(null))).called(1);
  });

  testWidgets('tapping already-selected category does not dispatch event',
      (tester) async {
    // 'cat1' is already the selected category
    when(() => posBloc.state).thenReturn(
      PosState.initial().copyWith(selectedCategoryId: 'cat1'),
    );

    await tester.pumpWidget(_pumpSidebar(
      posBloc: posBloc,
      productBloc: productBloc,
      dashBloc: dashBloc,
      authBloc: authBloc,
    ));

    await tester.tap(find.text('Beverages'));
    await tester.pump();

    // _CategoryItem sets onTap to null when isSelected == true, so no event fires
    verifyNever(() => posBloc.add(any(that: isA<PosCategoryChanged>())));
  });

  testWidgets('stats block shows cashier name for cashier role', (tester) async {
    const cashierName = 'Alice Smith';

    when(() => authBloc.state).thenReturn(
      AuthState.initial().copyWith(
        AuthStateUpdate(
          profile: const User(fullName: cashierName, role: 'cashier'),
        ),
      ),
    );

    await tester.pumpWidget(_pumpSidebar(
      posBloc: posBloc,
      productBloc: productBloc,
      dashBloc: dashBloc,
      authBloc: authBloc,
    ));

    expect(find.text(cashierName), findsOneWidget);
  });
}
