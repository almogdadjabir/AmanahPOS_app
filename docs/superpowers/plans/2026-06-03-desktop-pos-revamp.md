# Desktop POS Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the mobile-pattern desktop POS layout with a true 3-column workstation — category sidebar, compact product grid, desktop cart panel — without touching any mobile code path.

**Architecture:** Two new widgets (`DesktopCategorySidebar`, `DesktopCartPanel`) plus a rewritten `if (context.isDesktop)` branch in `PosScreen`. All existing sub-widgets (`CartLine`, `PaymentSelector`, `TotalsSection`, `PosProductCard`, `CategoryBar`) are reused unchanged. The mobile path is untouched.

**Tech Stack:** Flutter, flutter_bloc, bloc_test, mocktail, solar_icons, AppThemeColors / AppTextStyles / AppSpacing

**Spec:** `docs/superpowers/specs/2026-06-03-desktop-pos-revamp-design.md`

---

## File Map

| Action | File |
|---|---|
| Create | `lib/features/pos/presentation/widgets/desktop_category_sidebar.dart` |
| Create | `lib/features/cart/presentation/desktop_cart_panel.dart` |
| Modify | `lib/features/pos/presentation/pos_screen.dart` |
| Create | `test/features/pos/presentation/widgets/desktop_category_sidebar_test.dart` |
| Create | `test/features/cart/presentation/desktop_cart_panel_test.dart` |

---

### Task 0: Add test dependencies

`bloc_test` and `mocktail` are not yet in `pubspec.yaml`. Both are needed to mock BLoCs in widget tests.

- [ ] **Step 1: Add dependencies**

Run:

```bash
flutter pub add dev:bloc_test dev:mocktail
```

- [ ] **Step 2: Verify resolution**

```bash
flutter pub get
```

Expected: no version conflicts. If there are conflicts, check `flutter pub outdated` and align versions manually.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add bloc_test and mocktail as dev dependencies"
```

---

### Task 1: `DesktopCategorySidebar`

**Files:**
- Create: `lib/features/pos/presentation/widgets/desktop_category_sidebar.dart`
- Create: `test/features/pos/presentation/widgets/desktop_category_sidebar_test.dart`

160px-wide sidebar. Compact stats block (name / amount / count) at top reading from `DashboardSummaryBloc` + `AuthBloc`. Scrollable vertical category list reading from `ProductBloc.state.categories` + `PosBloc.state.selectedCategoryId`. Tapping a category dispatches `PosCategoryChanged`.

- [ ] **Step 1: Write the failing test**

Create `test/features/pos/presentation/widgets/desktop_category_sidebar_test.dart`:

```dart
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/desktop_category_sidebar.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
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

Widget _pumpSidebar({
  required PosBloc posBloc,
  required ProductBloc productBloc,
  required DashboardSummaryBloc dashBloc,
  required AuthBloc authBloc,
}) {
  return MaterialApp(
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
}
```

- [ ] **Step 2: Run to confirm it fails**

```bash
flutter test test/features/pos/presentation/widgets/desktop_category_sidebar_test.dart
```

Expected: FAIL — `desktop_category_sidebar.dart` does not exist.

- [ ] **Step 3: Create `lib/features/pos/presentation/widgets/desktop_category_sidebar.dart`**

```dart
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopCategorySidebar extends StatelessWidget {
  const DesktopCategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 160,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CompactStatsBlock(),
            Divider(height: 1, thickness: 1, color: colors.border),
            const Expanded(child: _CategoryList()),
          ],
        ),
      ),
    );
  }
}

// ── Compact stats block ───────────────────────────────────────────────────────

class _CompactStatsBlock extends StatelessWidget {
  const _CompactStatsBlock();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.summary != curr.summary,
      builder: (context, dashState) {
        final authState = context.read<AuthBloc>().state;
        final summary = dashState.summary;
        final shift = summary?.shift;
        final isCashier = authState.permissions.isCashier;

        final name = isCashier
            ? (shift?.cashierName?.trim().isNotEmpty == true
                ? shift!.cashierName!
                : authState.profile?.fullName ?? 'Cashier')
            : context.tr.posTodaySales;

        final amount = isCashier
            ? (shift?.grossSalesAmount ?? summary?.today.grossSalesAmount ?? 0)
            : (summary?.today.grossSalesAmount ?? 0);

        final salesCount = isCashier
            ? (shift?.salesCount ?? summary?.today.salesCount ?? 0)
            : (summary?.today.salesCount ?? 0);

        final currency = summary?.currency ?? 'SDG';

        return Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sm200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt(amount)} $currency',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs500(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$salesCount sales',
                style: AppTextStyles.sm100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(dynamic value) {
    final v = double.tryParse(value.toString()) ?? 0.0;
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }
}

// ── Category list ─────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) => prev.categories != curr.categories,
      builder: (context, productState) {
        final categories = productState.categories;

        return BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) =>
              prev.selectedCategoryId != curr.selectedCategoryId,
          builder: (context, posState) {
            final selectedId = posState.selectedCategoryId;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _SectionLabel(),
                _CategoryItem(
                  label: context.tr.posAllCategory,
                  isSelected: selectedId == null,
                  onTap: () => context
                      .read<PosBloc>()
                      .add(const PosCategoryChanged(null)),
                ),
                for (final category in categories)
                  _CategoryItem(
                    key: ValueKey(category.id),
                    label: category.name?.trim().isNotEmpty == true
                        ? category.name!.trim()
                        : 'Category',
                    isSelected: selectedId == category.id,
                    onTap: () => context
                        .read<PosBloc>()
                        .add(PosCategoryChanged(category.id)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s3, AppDims.s2, AppDims.s3, AppDims.s1),
      child: Text(
        'CATEGORIES',
        style: AppTextStyles.sm100(context).copyWith(
          color: context.appColors.textHint,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          height: 1,
        ),
      ),
    );
  }
}

// ── Category item ─────────────────────────────────────────────────────────────

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: isSelected ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2 + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsetsDirectional.only(end: AppDims.s2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : colors.border,
              ),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test**

```bash
flutter test test/features/pos/presentation/widgets/desktop_category_sidebar_test.dart
```

Expected: all 3 tests PASS. Fix any failures before continuing.

- [ ] **Step 5: Commit**

```bash
git add lib/features/pos/presentation/widgets/desktop_category_sidebar.dart \
        test/features/pos/presentation/widgets/desktop_category_sidebar_test.dart
git commit -m "feat(desktop-pos): add DesktopCategorySidebar with compact stats and category list"
```

---

### Task 2: `DesktopCartPanel`

**Files:**
- Create: `lib/features/cart/presentation/desktop_cart_panel.dart`
- Create: `test/features/cart/presentation/desktop_cart_panel_test.dart`

Desktop cart panel with a flat 56px header (title + count badge + clear button). No drag-handle pill, no rounded-top border, no collapse button. Reuses `CartLine`, `PaymentSelector`, `TotalsSection`. `BlocListener` shows `SaleReceiptSheet` on checkout success.

- [ ] **Step 1: Write the failing test**

Create `test/features/cart/presentation/desktop_cart_panel_test.dart`:

```dart
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/cart/presentation/desktop_cart_panel.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _pump({
  required PosBloc posBloc,
  required AuthBloc authBloc,
  VoidCallback? onCheckout,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<PosBloc>.value(value: posBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: DesktopCartPanel(onCheckout: onCheckout ?? () {}),
      ),
    ),
  );
}

void main() {
  late MockPosBloc posBloc;
  late MockAuthBloc authBloc;

  setUp(() {
    posBloc = MockPosBloc();
    authBloc = MockAuthBloc();
    when(() => posBloc.state).thenReturn(PosState.initial());
    when(() => authBloc.state).thenReturn(AuthState.initial());
  });

  testWidgets('has no drag-handle pill (42×5 SizedBox)', (tester) async {
    await tester.pumpWidget(_pump(posBloc: posBloc, authBloc: authBloc));

    final pill = find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 42 && w.height == 5,
    );
    expect(pill, findsNothing);
  });

  testWidgets('checkout FilledButton calls onCheckout', (tester) async {
    var called = false;
    await tester.pumpWidget(_pump(
      posBloc: posBloc,
      authBloc: authBloc,
      onCheckout: () => called = true,
    ));

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('checkout button is disabled when submitStatus is loading',
      (tester) async {
    when(() => posBloc.state).thenReturn(
      PosState.initial().copyWith(submitStatus: PosSubmitStatus.loading),
    );

    await tester.pumpWidget(_pump(posBloc: posBloc, authBloc: authBloc));

    final btn = tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(btn.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Run to confirm it fails**

```bash
flutter test test/features/cart/presentation/desktop_cart_panel_test.dart
```

Expected: FAIL — `desktop_cart_panel.dart` does not exist.

- [ ] **Step 3: Create `lib/features/cart/presentation/desktop_cart_panel.dart`**

```dart
import 'dart:ui' as ui;

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/cart/presentation/cart_line.dart';
import 'package:amana_pos/features/cart/presentation/payment_selector.dart';
import 'package:amana_pos/features/cart/presentation/totals_section.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/sale_receipt_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopCartPanel extends StatelessWidget {
  const DesktopCartPanel({
    super.key,
    required this.onCheckout,
  });

  final VoidCallback onCheckout;

  Future<void> _confirmClearCart(BuildContext context) async {
    final colors = context.appColors;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.rXl),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          context.tr.clearCartQuestion,
          style: AppTextStyles.bs500(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          context.tr.clearCartDescription,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(context.tr.clear),
          ),
        ],
      ),
    );
    if (shouldClear == true && context.mounted) {
      context.read<PosBloc>().add(const PosClearCart());
    }
  }

  void _showReceiptSheet(BuildContext context, PosState state) {
    final authState = context.read<AuthBloc>().state;
    final businessName = authState.defaultBusiness?.name ??
        authState.profile?.fullName ??
        'AmanaPOS';
    SaleReceiptSheet.show(
      context,
      receiptNumber: state.lastReceiptNumber,
      clientSaleId: state.lastClientSaleId ?? '',
      items: state.lastCartSnapshot,
      total: state.lastTotal,
      paymentMethod: state.lastPaymentMethod,
      isOffline: state.lastSaleWasOffline,
      businessName: businessName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) =>
          prev.submitStatus != curr.submitStatus &&
          curr.submitStatus == PosSubmitStatus.success,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) _showReceiptSheet(context, state);
        });
      },
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surface),
        child: BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) =>
              prev.items != curr.items ||
              prev.paymentMethod != curr.paymentMethod ||
              prev.submitStatus != curr.submitStatus,
          builder: (context, state) {
            final isLoading = state.submitStatus == PosSubmitStatus.loading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopCartHeader(
                  itemCount: state.itemCount,
                  isLoading: isLoading,
                  onClear: () => _confirmClearCart(context),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border.withValues(alpha: 0.75),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s3),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDims.s3),
                    itemBuilder: (_, index) {
                      final item = state.items[index];
                      return CartLine(
                        key: ValueKey(item.product.id ?? index),
                        item: item,
                      );
                    },
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.border.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PaymentSelector(paymentMethod: state.paymentMethod),
                      TotalsSection(state: state),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s4),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: isLoading ? null : onCheckout,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              disabledBackgroundColor: colors.border,
                              foregroundColor: colors.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              child: isLoading
                                  ? SizedBox(
                                      key: const ValueKey('loading'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: colors.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : _CheckoutContent(
                                      key: const ValueKey('content'),
                                      total: state.total,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Desktop cart header ───────────────────────────────────────────────────────

class _DesktopCartHeader extends StatelessWidget {
  const _DesktopCartHeader({
    required this.itemCount,
    required this.isLoading,
    required this.onClear,
  });

  final int itemCount;
  final bool isLoading;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4, 0, AppDims.s4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.tr.reviewSale,
              style: AppTextStyles.bs400(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: itemCount > 0
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$itemCount',
                style: AppTextStyles.sm100(context).copyWith(
                  color: itemCount > 0 ? colors.primary : colors.textHint,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const Spacer(),
            if (itemCount > 0)
              GestureDetector(
                onTap: isLoading ? null : onClear,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: isLoading ? 0.45 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SolarIconsOutline.trashBinTrash,
                        size: 14,
                        color: colors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.tr.clear,
                        style: AppTextStyles.sm200(context).copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Checkout button content ───────────────────────────────────────────────────

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({super.key, required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            _money(total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const Spacer(),
        Text(
          context.tr.completeSale,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs400(context).copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);
```

- [ ] **Step 4: Run test**

```bash
flutter test test/features/cart/presentation/desktop_cart_panel_test.dart
```

Expected: all 3 tests PASS. Fix any failures.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cart/presentation/desktop_cart_panel.dart \
        test/features/cart/presentation/desktop_cart_panel_test.dart
git commit -m "feat(desktop-pos): add DesktopCartPanel — flat desktop header, no mobile chrome"
```

---

### Task 3: Rewrite `PosScreen` desktop branch

**Files:**
- Modify: `lib/features/pos/presentation/pos_screen.dart`

Replace the `if (context.isDesktop)` block with the 3-column layout. The mobile `RefreshIndicator` path and `productPane` variable are not touched.

- [ ] **Step 1: Add two imports**

Open `lib/features/pos/presentation/pos_screen.dart`. Add after the existing imports (keep alphabetical order):

```dart
import 'package:amana_pos/features/cart/presentation/desktop_cart_panel.dart';
import 'package:amana_pos/features/pos/presentation/widgets/desktop_category_sidebar.dart';
```

- [ ] **Step 2: Replace the desktop branch**

Find the comment `// Desktop: persistent side-by-side layout` (around line 399). Replace the entire `if (context.isDesktop) { return Row(...); }` block — from the `if` keyword through its closing `}` — with:

```dart
// Desktop: 3-column workstation layout
if (context.isDesktop) {
  final colors = context.appColors;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const DesktopCategorySidebar(),
      VerticalDivider(width: 1, thickness: 1, color: colors.border),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: colors.surface),
              child: PosSearchSection(searchCtrl: _searchCtrl),
            ),
            Divider(height: 1, thickness: 1, color: colors.border),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (prev, curr) =>
                    prev.productStatus != curr.productStatus ||
                    prev.products != curr.products,
                builder: (context, productState) {
                  if (productState.productStatus == ProductStatus.loading ||
                      productState.productStatus == ProductStatus.initial) {
                    return const ProductsLoadingGrid();
                  }
                  if (productState.productStatus == ProductStatus.failure) {
                    return ProductErrorView(
                        message: productState.responseError);
                  }
                  return BlocBuilder<PosBloc, PosState>(
                    buildWhen: (prev, curr) =>
                        prev.searchQuery != curr.searchQuery ||
                        prev.selectedCategoryId != curr.selectedCategoryId,
                    builder: (context, posState) {
                      final products =
                          _filterProducts(productState.products, posState);
                      if (products.isEmpty) {
                        return ProductsEmpty(query: posState.searchQuery);
                      }
                      return LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cols = ctx.gridColumnsFor(
                            constraints.maxWidth,
                            tile: 140,
                          );
                          return ProductGrid(
                            products: products,
                            crossAxisCount: cols,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      VerticalDivider(width: 1, thickness: 1, color: colors.border),
      SizedBox(
        width: 380,
        child: DesktopCartPanel(onCheckout: _handleCheckout),
      ),
    ],
  );
}
```

- [ ] **Step 3: Remove the now-unused `ExpandedCart` import**

The old desktop branch used `ExpandedCart`. Confirm that `ExpandedCart` is no longer referenced anywhere in `pos_screen.dart`:

```bash
grep -n "ExpandedCart" lib/features/pos/presentation/pos_screen.dart
```

Expected: 0 matches. If 0 matches, remove this import line from the top of the file:

```dart
import 'package:amana_pos/features/cart/presentation/expanded_cart.dart';
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests PASS. Fix any failures before continuing.

- [ ] **Step 5: Commit**

```bash
git add lib/features/pos/presentation/pos_screen.dart
git commit -m "feat(desktop-pos): rewrite PosScreen desktop branch — 3-column workstation layout"
```

---

### Task 4: Smoke test

- [ ] **Step 1: Run on macOS**

```bash
flutter run -d macos
```

Navigate to the POS screen and verify all of the following:

- [ ] Left column shows the 160px category sidebar with compact stats (name, amount, count) at top
- [ ] Category list shows "All Items" + your actual categories
- [ ] Tapping a category highlights it with a primary-colored left border and filters products
- [ ] Center column shows a search bar at top, then a dense product grid (4–5 columns)
- [ ] Right column shows the cart panel with a flat 56px header — no rounded top, no drag pill, no collapse button
- [ ] The cart header shows item count badge and "Clear" link (when items exist)
- [ ] Adding products (tap in grid) updates the cart panel immediately
- [ ] Checkout button triggers the payment flow and shows the receipt sheet on success

- [ ] **Step 2: Verify mobile is unchanged**

```bash
flutter run -d <ios-simulator-or-android-device>
```

Verify on mobile:

- [ ] Categories appear as the horizontal chip bar (`CategoryBar`) above the product grid
- [ ] `CashierShiftCard` (stats widget) appears above the search bar
- [ ] Cart opens as a bottom sheet (not a side panel)
- [ ] All mobile checkout and cart interactions work normally

- [ ] **Step 3: Commit smoke-test fixes (if any)**

If step 1 or 2 revealed any visual issues (spacing, overflow, missing data), fix and commit:

```bash
git add lib/features/pos/presentation/pos_screen.dart \
        lib/features/pos/presentation/widgets/desktop_category_sidebar.dart \
        lib/features/cart/presentation/desktop_cart_panel.dart
git commit -m "fix(desktop-pos): smoke-test adjustments"
```
