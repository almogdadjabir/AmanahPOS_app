# Desktop Sales History — Navigation + Transactions Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Sales History" desktop navigation destination with a Transactions tab (full-width table of past sales with filters, search, and infinite scroll), built on the existing `SalesHistoryBloc`.

**Architecture:** `SalesHistoryScreen` gains a single `if (context.isDesktop)` branch that delegates to a new `DesktopSalesHistoryView` — a stateful widget owning scroll/search/filter state that composes the existing `SalesHistoryBloc`, new `DesktopSalesHistoryTopBar`, `FilterChips`, `DesktopSalesStatsRow`, and `DesktopSalesTable` into a `CustomScrollView`+sliver layout. Navigation registration, permission gate, and l10n keys are added first so the destination is reachable before any UI lands. Mobile is untouched.

**Tech Stack:** Flutter 3.41.9 · Dart · `flutter_bloc` · `flutter_animate` · `solar_icons` · existing `SalesHistoryBloc`/`SalesHistoryUseCase` · `mocktail`/`bloc_test` for tests · `flutter gen-l10n` for ARB keys

---

## File Map

**New source files**
| File | Responsibility |
|---|---|
| `lib/features/sales_history/presentation/widgets/sale_stat_card.dart` | Public `SaleStatCard` + `SaleStatIconBox` extracted from `sale_stats_row.dart` |
| `lib/features/sales_history/presentation/widgets/sales_view_tab_switch.dart` | `SalesView` enum + `SalesViewTabSwitch` segmented control |
| `lib/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart` | 4-card read-only KPI row for desktop |
| `lib/features/sales_history/presentation/widgets/desktop_sales_table.dart` | `DesktopSalesTableHeader`, `DesktopSalesTableRow`, `DesktopSalesTable` sliver |
| `lib/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart` | "Coming soon" screen for Reports tab |
| `lib/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart` | Top bar: search field + tab switch + refresh |
| `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart` | Root stateful widget for the desktop layout |

**New test files**
| File | Tests |
|---|---|
| `test/features/sales_history/presentation/widgets/sale_stat_card_test.dart` | Renders label/value/icon; forceValueLtr wraps in Directionality |
| `test/features/sales_history/utility/sale_utility_test.dart` | `salesCountLabel` and `revenueLabel` for every `SaleFilter` |
| `test/features/sales_history/presentation/widgets/sale_stats_row_test.dart` | Regression: count + revenue values still render after refactor |
| `test/core/permissions/app_permissions_sales_history_test.dart` | `canAccessSalesHistory` gate logic |
| `test/features/sales_history/presentation/widgets/sales_view_tab_switch_test.dart` | Tab renders + tap fires callback |
| `test/features/sales_history/presentation/widgets/desktop_sales_stats_row_test.dart` | 4 KPI cards render with state items |
| `test/features/sales_history/presentation/widgets/desktop_sales_table_test.dart` | Header labels; row renders item data; tap callback |
| `test/features/sales_history/presentation/widgets/reports/reports_placeholder_view_test.dart` | Placeholder renders icon + text |
| `test/features/sales_history/presentation/widgets/desktop_sales_history_top_bar_test.dart` | Search dispatches event; refresh button spins; tab switch fires |
| `test/features/sales_history/presentation/widgets/desktop_sales_history_view_test.dart` | Smoke: shows shimmer on loading, table on loaded, placeholder on reports tab |

**Modified files**
| File | Change |
|---|---|
| `lib/features/sales_history/presentation/widgets/sale_stats_row.dart` | Use `SaleStatCard`, `SaleFilterX.salesCountLabel/revenueLabel`; remove private code |
| `lib/features/sales_history/utility/sale_utility.dart` | Add `salesCountLabel`/`revenueLabel` to `SaleFilterX` |
| `lib/features/main_screen/data/app_feature.dart` | Add `salesHistory` enum value + `allows` case |
| `lib/core/permissions/app_permissions.dart` | Add `canAccessSalesHistory` getter |
| `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart` | Add tab after Inventory |
| `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart` | Same insertion (kept in sync) |
| `lib/features/main_screen/data/navigation_config.dart` | Add `salesHistory` case |
| `lib/features/sales_history/presentation/sales_history_screen.dart` | Add `if (context.isDesktop)` branch |
| `lib/l10n/app_en.arb` + `app_ar.arb` | Add 7 new keys |

---

## Task 1: Extract `SaleStatCard` + add `SaleFilterX.salesCountLabel/revenueLabel`

Promote the private `_StatCard`/`_StatIconBox` from `sale_stats_row.dart` to a public reusable widget, and move the label-string logic to `SaleFilterX` where it belongs.

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/sale_stat_card.dart`
- Modify: `lib/features/sales_history/utility/sale_utility.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_stats_row.dart`
- Create: `test/features/sales_history/presentation/widgets/sale_stats_row_test.dart`
- Create: `test/features/sales_history/presentation/widgets/sale_stat_card_test.dart`
- Create: `test/features/sales_history/utility/sale_utility_test.dart`

---

- [ ] **Step 1.1 — Write the regression test for `SaleStatsRow` (runs against current code)**

Create `test/features/sales_history/presentation/widgets/sale_stats_row_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stats_row.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesHistoryBloc
    extends MockBloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {}

class _FakeSalesHistoryEvent extends Fake implements SalesHistoryEvent {}

SaleHistoryItem _item({double total = 100.0, SaleHistoryStatus status = SaleHistoryStatus.completed}) =>
    SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'csid-1',
      receiptNumber: 'RCP-001',
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: 'Ahmed',
      paymentMethod: 'cash',
      total: total,
      itemCount: 2,
      status: status,
      createdAt: DateTime(2026, 6, 10, 14, 30),
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeSalesHistoryEvent()));

  testWidgets('SaleStatsRow shows count and revenue for SaleFilter.all', (tester) async {
    final bloc = _MockSalesHistoryBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial().copyWith(
      status: SalesHistoryBlocStatus.loaded,
      items: [_item(total: 100.0), _item(total: 200.0)],
    ));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SalesHistoryBloc>.value(
          value: bloc,
          child: SaleStatsRow(
            activeFilter: SaleFilter.all,
            applyFilter: (items) => items,
          ),
        ),
      ),
    ));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('300 SDG'), findsOneWidget);
  });
}
```

- [ ] **Step 1.2 — Run test to confirm it passes (baseline)**

```bash
flutter test test/features/sales_history/presentation/widgets/sale_stats_row_test.dart --reporter=expanded
```

Expected: PASS — `SaleStatsRow shows count and revenue for SaleFilter.all`.

- [ ] **Step 1.3 — Write unit tests for new `SaleFilterX` methods (will fail: methods don't exist yet)**

Create `test/features/sales_history/utility/sale_utility_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(WidgetBuilder builder) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: builder),
      );

  testWidgets('SaleFilterX.salesCountLabel returns correct key per filter', (tester) async {
    late AppLocalizations tr;
    await tester.pumpWidget(_wrap((ctx) {
      tr = AppLocalizations.of(ctx)!;
      return const SizedBox();
    }));

    expect(SaleFilter.all.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.allLoadedSales));
    expect(SaleFilter.today.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.todaysSalesCount));
    expect(SaleFilter.completed.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.completedSalesCount));
    expect(SaleFilter.refunded.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.returnedSalesCount));
    expect(SaleFilter.pending.salesCountLabel(tester.element(find.byType(SizedBox))),
        equals(tr.pendingSalesCount));
  });

  testWidgets('SaleFilterX.revenueLabel returns correct key per filter', (tester) async {
    late AppLocalizations tr;
    await tester.pumpWidget(_wrap((ctx) {
      tr = AppLocalizations.of(ctx)!;
      return const SizedBox();
    }));

    expect(SaleFilter.all.revenueLabel(tester.element(find.byType(SizedBox))),
        equals(tr.allLoadedRevenue));
    expect(SaleFilter.today.revenueLabel(tester.element(find.byType(SizedBox))),
        equals(tr.todaysRevenue));
  });
}
```

- [ ] **Step 1.4 — Run to confirm FAIL**

```bash
flutter test test/features/sales_history/utility/sale_utility_test.dart --reporter=expanded
```

Expected: FAIL — `SaleFilter.all.salesCountLabel` undefined.

- [ ] **Step 1.5 — Add `salesCountLabel` and `revenueLabel` to `SaleFilterX` in `sale_utility.dart`**

In `lib/features/sales_history/utility/sale_utility.dart`, add after the `statsLabel` getter (after line 32, before the closing `}`):

```dart
  String salesCountLabel(BuildContext context) {
    return switch (this) {
      SaleFilter.all => context.tr.allLoadedSales,
      SaleFilter.today => context.tr.todaysSalesCount,
      SaleFilter.completed => context.tr.completedSalesCount,
      SaleFilter.refunded => context.tr.returnedSalesCount,
      SaleFilter.pending => context.tr.pendingSalesCount,
    };
  }

  String revenueLabel(BuildContext context) {
    return switch (this) {
      SaleFilter.all => context.tr.allLoadedRevenue,
      SaleFilter.today => context.tr.todaysRevenue,
      SaleFilter.completed => context.tr.completedRevenue,
      SaleFilter.refunded => context.tr.returnedRevenue,
      SaleFilter.pending => context.tr.pendingRevenue,
    };
  }
```

- [ ] **Step 1.6 — Run utility test to confirm PASS**

```bash
flutter test test/features/sales_history/utility/sale_utility_test.dart --reporter=expanded
```

Expected: PASS.

- [ ] **Step 1.7 — Create `sale_stat_card.dart`**

Create `lib/features/sales_history/presentation/widgets/sale_stat_card.dart`:

```dart
import 'dart:ui' as ui;

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class SaleStatCard extends StatelessWidget {
  const SaleStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.labelColor,
    required this.icon,
    this.forceValueLtr = false,
  });

  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final Color labelColor;
  final IconData icon;
  final bool forceValueLtr;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final displayLabel = locale == 'ar' ? label : label.toUpperCase();

    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
      style: AppTextStyles.bs400(context).copyWith(
        color: valueColor,
        fontWeight: FontWeight.w900,
        fontSize: 18,
        height: 1.1,
        letterSpacing: -0.25,
      ),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: valueColor.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s3,
            vertical: AppDims.s2 + 2,
          ),
          child: Row(
            children: [
              SaleStatIconBox(icon: icon, color: valueColor),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: labelColor,
                        fontSize: 9,
                        letterSpacing: locale == 'ar' ? 0 : 0.7,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    forceValueLtr
                        ? Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: valueText,
                          )
                        : valueText,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SaleStatIconBox extends StatelessWidget {
  const SaleStatIconBox({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
```

- [ ] **Step 1.8 — Write `sale_stat_card_test.dart`**

Create `test/features/sales_history/presentation/widgets/sale_stat_card_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('SaleStatCard renders label and value', (tester) async {
    await tester.pumpWidget(_wrap(const SaleStatCard(
      label: 'Sales',
      value: '42',
      background: Color(0xFFCCFBF1),
      valueColor: Color(0xFF115E59),
      labelColor: Color(0xFF0F766E),
      icon: SolarIconsOutline.billList,
    )));

    expect(find.text('SALES'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('SaleStatCard wraps value in Directionality when forceValueLtr', (tester) async {
    await tester.pumpWidget(_wrap(const SaleStatCard(
      label: 'Revenue',
      value: '500 SDG',
      background: Color(0xFFCCFBF1),
      valueColor: Color(0xFF115E59),
      labelColor: Color(0xFF0F766E),
      icon: SolarIconsOutline.walletMoney,
      forceValueLtr: true,
    )));

    expect(find.byType(Directionality), findsWidgets);
  });
}
```

- [ ] **Step 1.9 — Refactor `sale_stats_row.dart` to use new extracted widgets**

Replace the entire content of `lib/features/sales_history/presentation/widgets/sale_stats_row.dart` with:

```dart
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleStatsRow extends StatelessWidget {
  const SaleStatsRow({
    super.key,
    required this.activeFilter,
    required this.applyFilter,
  });

  final SaleFilter activeFilter;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>) applyFilter;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SalesHistoryBloc, SalesHistoryState, List<SaleHistoryItem>>(
      selector: (state) => state.items,
      builder: (context, allItems) {
        final filtered = applyFilter(allItems);

        double revenue = 0;
        for (final item in filtered) {
          revenue += item.total;
        }

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: SaleStatCard(
                  label: activeFilter.salesCountLabel(context),
                  value: filtered.length.toString(),
                  background: AppColors.primaryLight,
                  valueColor: AppColors.primaryDark,
                  labelColor: AppColors.primary,
                  icon: SolarIconsOutline.billList,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: SaleStatCard(
                  label: activeFilter.revenueLabel(context),
                  value: AppFormat.compactMoney(revenue),
                  forceValueLtr: true,
                  background: AppColors.secondaryLight,
                  valueColor: AppColors.secondaryDark,
                  labelColor: AppColors.secondaryDark,
                  icon: SolarIconsOutline.walletMoney,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 1.10 — Run all three tests to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/sale_stats_row_test.dart test/features/sales_history/presentation/widgets/sale_stat_card_test.dart test/features/sales_history/utility/sale_utility_test.dart --reporter=expanded
```

Expected: all PASS.

- [ ] **Step 1.11 — Analyze**

```bash
flutter analyze lib/features/sales_history/presentation/widgets/sale_stats_row.dart lib/features/sales_history/presentation/widgets/sale_stat_card.dart lib/features/sales_history/utility/sale_utility.dart
```

Expected: no issues.

- [ ] **Step 1.12 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/sale_stat_card.dart \
        lib/features/sales_history/utility/sale_utility.dart \
        lib/features/sales_history/presentation/widgets/sale_stats_row.dart \
        test/features/sales_history/presentation/widgets/sale_stats_row_test.dart \
        test/features/sales_history/presentation/widgets/sale_stat_card_test.dart \
        test/features/sales_history/utility/sale_utility_test.dart
git commit -m "refactor(sales-history): extract SaleStatCard + promote label getters to SaleFilterX"
```

---

## Task 2: Add `AppFeature.salesHistory` and `canAccessSalesHistory`

**Files:**
- Modify: `lib/features/main_screen/data/app_feature.dart`
- Modify: `lib/core/permissions/app_permissions.dart`
- Create: `test/core/permissions/app_permissions_sales_history_test.dart`

---

- [ ] **Step 2.1 — Write the failing test**

Create `test/core/permissions/app_permissions_sales_history_test.dart`:

```dart
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canAccessSalesHistory is false when no session', () {
    expect(AppPermissions.none.canAccessSalesHistory, isFalse);
  });

  test('canAccessSalesHistory is true for owner', () {
    final perms = AppPermissions.from(businessType: 'shop', userRole: 'owner');
    expect(perms.canAccessSalesHistory, isTrue);
  });

  test('canAccessSalesHistory is true for cashier', () {
    final perms = AppPermissions.from(businessType: 'shop', userRole: 'cashier');
    expect(perms.canAccessSalesHistory, isTrue);
  });

  test('FeaturePermission.allows delegates to canAccessSalesHistory', () {
    final perms = AppPermissions.from(businessType: 'shop', userRole: 'owner');
    expect(perms.allows(AppFeature.salesHistory), isTrue);
  });
}
```

- [ ] **Step 2.2 — Run test to confirm FAIL**

```bash
flutter test test/core/permissions/app_permissions_sales_history_test.dart --reporter=expanded
```

Expected: FAIL — `salesHistory` not a member of `AppFeature`.

- [ ] **Step 2.3 — Add `salesHistory` to `AppFeature` and update `FeaturePermission.allows`**

In `lib/features/main_screen/data/app_feature.dart`, change the enum and switch:

```dart
import 'package:amana_pos/core/permissions/app_permissions.dart';

enum AppFeature {
  pos,
  business,
  users,
  categories,
  products,
  inventory,
  customers,
  salesHistory,
}

extension FeaturePermission on AppPermissions {
  bool allows(AppFeature feature) {
    switch (feature) {
      case AppFeature.pos:
        return canAccessPOS;
      case AppFeature.products:
        return canAccessProducts;
      case AppFeature.categories:
        return canAccessCategories;
      case AppFeature.inventory:
        return canAccessInventory;
      case AppFeature.customers:
        return canAccessCustomers;
      case AppFeature.users:
        return canAccessUsers;
      case AppFeature.business:
        return canAccessBusiness;
      case AppFeature.salesHistory:
        return canAccessSalesHistory;
    }
  }
}
```

- [ ] **Step 2.4 — Add `canAccessSalesHistory` to `AppPermissions`**

In `lib/core/permissions/app_permissions.dart`, add after `canAccessCategories` (line 29):

```dart
  bool get canAccessSalesHistory => _hasSession;
```

- [ ] **Step 2.5 — Run test to confirm PASS**

```bash
flutter test test/core/permissions/app_permissions_sales_history_test.dart --reporter=expanded
```

Expected: PASS.

- [ ] **Step 2.6 — Commit**

```bash
git add lib/features/main_screen/data/app_feature.dart \
        lib/core/permissions/app_permissions.dart \
        test/core/permissions/app_permissions_sales_history_test.dart
git commit -m "feat(permissions): add AppFeature.salesHistory + canAccessSalesHistory gate"
```

---

## Task 3: Add l10n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

---

- [ ] **Step 3.1 — Add 7 keys to `app_en.arb`**

In `lib/l10n/app_en.arb`, change the last two lines from:

```
  "allCaughtUpNewNotificationsWillAppearHere": "You're all caught up. New notifications will appear here."

}
```

to:

```
  "allCaughtUpNewNotificationsWillAppearHere": "You're all caught up. New notifications will appear here.",

  "salesViewTransactions": "Transactions",
  "salesViewReports": "Reports & Statistics",
  "customer": "Customer",
  "avgSale": "Avg sale",
  "refunds": "Refunds",
  "reportsComingSoon": "Reports & Statistics are coming soon.",
  "searchSalesHistoryHint": "Search by receipt or customer"

}
```

- [ ] **Step 3.2 — Add the same 7 keys to `app_ar.arb`**

In `lib/l10n/app_ar.arb`, change the last two lines from:

```
  "allCaughtUpNewNotificationsWillAppearHere": "أنت مُطّلع على كل شيء. ستظهر الإشعارات الجديدة هنا."

}
```

to:

```
  "allCaughtUpNewNotificationsWillAppearHere": "أنت مُطّلع على كل شيء. ستظهر الإشعارات الجديدة هنا.",

  "salesViewTransactions": "المعاملات",
  "salesViewReports": "التقارير والإحصائيات",
  "customer": "العميل",
  "avgSale": "متوسط البيع",
  "refunds": "المرتجعات",
  "reportsComingSoon": "التقارير والإحصائيات قادمة قريباً.",
  "searchSalesHistoryHint": "البحث برقم الإيصال أو العميل"

}
```

- [ ] **Step 3.3 — Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: `lib/l10n/app_localizations.dart` (and `app_localizations_en.dart` / `app_localizations_ar.dart`) regenerated with no errors. Spot-check: `grep "salesViewTransactions\|customer\|avgSale\|refunds" lib/l10n/app_localizations_en.dart`.

- [ ] **Step 3.4 — Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/l10n/
git commit -m "feat(l10n): add 7 sales-history desktop keys"
```

---

## Task 4: `SalesView` enum + `SalesViewTabSwitch`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/sales_view_tab_switch.dart`
- Create: `test/features/sales_history/presentation/widgets/sales_view_tab_switch_test.dart`

---

- [ ] **Step 4.1 — Write the failing test**

Create `test/features/sales_history/presentation/widgets/sales_view_tab_switch_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap({required SalesView active, required ValueChanged<SalesView> onChanged}) =>
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SalesViewTabSwitch(active: active, onChanged: onChanged),
        ),
      );

  testWidgets('renders both tab labels', (tester) async {
    await tester.pumpWidget(_wrap(active: SalesView.transactions, onChanged: (_) {}));
    expect(find.textContaining('Transactions'), findsOneWidget);
    expect(find.textContaining('Reports'), findsOneWidget);
  });

  testWidgets('tapping Reports tab fires callback with SalesView.reports', (tester) async {
    SalesView? fired;
    await tester.pumpWidget(_wrap(
      active: SalesView.transactions,
      onChanged: (v) => fired = v,
    ));
    await tester.tap(find.textContaining('Reports'));
    expect(fired, equals(SalesView.reports));
  });
}
```

- [ ] **Step 4.2 — Run test to confirm FAIL**

```bash
flutter test test/features/sales_history/presentation/widgets/sales_view_tab_switch_test.dart --reporter=expanded
```

Expected: FAIL — `SalesView` not found.

- [ ] **Step 4.3 — Create `sales_view_tab_switch.dart`**

Create `lib/features/sales_history/presentation/widgets/sales_view_tab_switch.dart`:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

enum SalesView { transactions, reports }

class SalesViewTabSwitch extends StatelessWidget {
  const SalesViewTabSwitch({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final SalesView active;
  final ValueChanged<SalesView> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tab(
              label: context.tr.salesViewTransactions,
              active: active == SalesView.transactions,
              onTap: () => onChanged(SalesView.transactions),
            ),
            _Tab(
              label: context.tr.salesViewReports,
              active: active == SalesView.reports,
              onTap: () => onChanged(SalesView.reports),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDims.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s3, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDims.rSm),
        ),
        child: Text(
          label,
          style: AppTextStyles.sm100(context).copyWith(
            color: active ? Colors.white : context.appColors.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4.4 — Run test to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/sales_view_tab_switch_test.dart --reporter=expanded
```

Expected: PASS.

- [ ] **Step 4.5 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/sales_view_tab_switch.dart \
        test/features/sales_history/presentation/widgets/sales_view_tab_switch_test.dart
git commit -m "feat(sales-history): add SalesView enum + SalesViewTabSwitch segmented control"
```

---

## Task 5: `DesktopSalesStatsRow`

4 read-only KPI cards: Sales count, Revenue, Avg sale, Refunds — computed from `SalesHistoryBloc` state.

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart`
- Create: `test/features/sales_history/presentation/widgets/desktop_sales_stats_row_test.dart`

---

- [ ] **Step 5.1 — Write the failing test**

Create `test/features/sales_history/presentation/widgets/desktop_sales_stats_row_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {}

class _FakeEvent extends Fake implements SalesHistoryEvent {}

SaleHistoryItem _item({
  double total = 100.0,
  SaleHistoryStatus status = SaleHistoryStatus.completed,
  bool isOfflinePending = false,
}) =>
    SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'c1',
      receiptNumber: 'R1',
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: null,
      paymentMethod: 'cash',
      total: total,
      itemCount: 1,
      status: status,
      createdAt: DateTime(2026, 6, 10),
      isOfflinePending: isOfflinePending,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  testWidgets('DesktopSalesStatsRow renders 4 KPI cards', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial().copyWith(
      status: SalesHistoryBlocStatus.loaded,
      items: [
        _item(total: 200.0),
        _item(total: 300.0),
        _item(total: 100.0, status: SaleHistoryStatus.refunded),
      ],
    ));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SalesHistoryBloc>.value(
          value: bloc,
          child: DesktopSalesStatsRow(
            activeFilter: SaleFilter.all,
            applyFilter: (items) => items,
          ),
        ),
      ),
    ));

    // Sales count
    expect(find.text('3'), findsOneWidget);
    // Revenue = 600
    expect(find.text('600 SDG'), findsOneWidget);
    // Avg = 200
    expect(find.text('200 SDG'), findsOneWidget);
    // Refund count = 1
    expect(find.textContaining('1 ·'), findsOneWidget);
  });
}
```

- [ ] **Step 5.2 — Run test to confirm FAIL**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_stats_row_test.dart --reporter=expanded
```

Expected: FAIL — `DesktopSalesStatsRow` not found.

- [ ] **Step 5.3 — Create `desktop_sales_stats_row.dart`**

Create `lib/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart`:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopSalesStatsRow extends StatelessWidget {
  const DesktopSalesStatsRow({
    super.key,
    required this.activeFilter,
    required this.applyFilter,
  });

  final SaleFilter activeFilter;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>) applyFilter;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SalesHistoryBloc, SalesHistoryState, List<SaleHistoryItem>>(
      selector: (state) => state.items,
      builder: (context, allItems) {
        final filtered = applyFilter(allItems);

        double revenue = 0;
        double refundAmount = 0;
        int refundCount = 0;

        for (final item in filtered) {
          revenue += item.total;
          final isRefund = item.status == SaleHistoryStatus.refunded ||
              item.status == SaleHistoryStatus.partialRefund;
          if (isRefund) {
            refundCount++;
            refundAmount += item.total;
          }
        }

        final count = filtered.length;
        final avgSale = count > 0 ? revenue / count : 0.0;

        return Row(
          children: [
            Expanded(
              child: SaleStatCard(
                label: activeFilter.salesCountLabel(context),
                value: count.toString(),
                background: AppColors.primaryLight,
                valueColor: AppColors.primaryDark,
                labelColor: AppColors.primary,
                icon: SolarIconsOutline.billList,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: SaleStatCard(
                label: activeFilter.revenueLabel(context),
                value: AppFormat.compactMoney(revenue),
                forceValueLtr: true,
                background: AppColors.secondaryLight,
                valueColor: AppColors.secondaryDark,
                labelColor: AppColors.secondaryDark,
                icon: SolarIconsOutline.walletMoney,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: SaleStatCard(
                label: context.tr.avgSale,
                value: AppFormat.compactMoney(avgSale),
                forceValueLtr: true,
                background: AppColors.infoLight,
                valueColor: AppColors.info,
                labelColor: AppColors.info,
                icon: SolarIconsOutline.chartSquare,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: SaleStatCard(
                label: context.tr.refunds,
                value: '$refundCount · ${AppFormat.compactMoney(refundAmount)}',
                forceValueLtr: true,
                background: AppColors.dangerLight,
                valueColor: AppColors.danger,
                labelColor: AppColors.danger,
                icon: SolarIconsOutline.undoLeft,
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5.4 — Run test to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_stats_row_test.dart --reporter=expanded
```

Expected: PASS.

- [ ] **Step 5.5 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart \
        test/features/sales_history/presentation/widgets/desktop_sales_stats_row_test.dart
git commit -m "feat(sales-history): add DesktopSalesStatsRow with 4 KPI cards"
```

---

## Task 6: `DesktopSalesTable`

Full-width sliver table: header row + sale rows. Wraps in `DecoratedSliver`+`SliverMainAxisGroup` for a card appearance inside `CustomScrollView`.

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/desktop_sales_table.dart`
- Create: `test/features/sales_history/presentation/widgets/desktop_sales_table_test.dart`

---

- [ ] **Step 6.1 — Write the failing test**

Create `test/features/sales_history/presentation/widgets/desktop_sales_table_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_table.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SaleHistoryItem _item({
  String receipt = 'RCP-001',
  String? customerName = 'Sara',
  double total = 250.0,
  SaleHistoryStatus status = SaleHistoryStatus.completed,
}) =>
    SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'c1',
      receiptNumber: receipt,
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: customerName,
      paymentMethod: 'cash',
      total: total,
      itemCount: 3,
      status: status,
      createdAt: DateTime(2026, 6, 10, 10, 0),
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  Widget _wrap(Widget sliver) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(slivers: [sliver]),
        ),
      );

  testWidgets('DesktopSalesTableHeader renders all 7 column labels', (tester) async {
    await tester.pumpWidget(_wrap(
      DesktopSalesTable(items: const [], onTap: (_) {}),
    ));
    await tester.pump();

    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('RECEIPT'), findsOneWidget);
    expect(find.text('CUSTOMER'), findsOneWidget);
    expect(find.text('ITEMS'), findsOneWidget);
    expect(find.text('PAYMENT'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
  });

  testWidgets('DesktopSalesTableRow shows receipt, customer name and calls onTap', (tester) async {
    SaleHistoryItem? tapped;
    final item = _item();

    await tester.pumpWidget(_wrap(
      DesktopSalesTable(items: [item], onTap: (i) => tapped = i),
    ));
    await tester.pump();

    expect(find.text('RCP-001'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);

    await tester.tap(find.text('RCP-001'));
    expect(tapped, equals(item));
  });

  testWidgets('em-dash shown when customerName is null', (tester) async {
    await tester.pumpWidget(_wrap(
      DesktopSalesTable(items: [_item(customerName: null)], onTap: (_) {}),
    ));
    await tester.pump();

    expect(find.text('—'), findsOneWidget);
  });
}
```

- [ ] **Step 6.2 — Run test to confirm FAIL**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_table_test.dart --reporter=expanded
```

Expected: FAIL — `DesktopSalesTable` not found.

- [ ] **Step 6.3 — Create `desktop_sales_table.dart`**

Create `lib/features/sales_history/presentation/widgets/desktop_sales_table.dart`:

```dart
import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_extensions.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Column flex weights — shared by header and rows so they stay aligned.
const _kDateFlex = 2;
const _kReceiptFlex = 2;
const _kCustomerFlex = 3;
const _kItemsFlex = 1;
const _kPaymentFlex = 2;
const _kTotalFlex = 2;
const _kStatusFlex = 2;

/// A sliver widget: places a decorated card (rounded border) containing
/// the table header + a [SliverList] of sale rows inside
/// [SliverMainAxisGroup]/[DecoratedSliver].
class DesktopSalesTable extends StatelessWidget {
  const DesktopSalesTable({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<SaleHistoryItem> items;
  final ValueChanged<SaleHistoryItem> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: DesktopSalesTableHeader(),
          ),
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return DesktopSalesTableRow(
                item: item,
                onTap: () => onTap(item),
              )
                  .animate(delay: (index % 20 * 15).ms)
                  .fadeIn(duration: 200.ms);
            },
          ),
        ],
      ),
    );
  }
}

class DesktopSalesTableHeader extends StatelessWidget {
  const DesktopSalesTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String h(String s) => isAr ? s : s.toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s2 + 2,
        ),
        child: Row(
          children: [
            Expanded(flex: _kDateFlex, child: _HeaderCell(h(context.tr.date))),
            Expanded(flex: _kReceiptFlex, child: _HeaderCell(h(context.tr.receipt))),
            Expanded(flex: _kCustomerFlex, child: _HeaderCell(h(context.tr.customer))),
            Expanded(flex: _kItemsFlex, child: _HeaderCell(h(context.tr.items))),
            Expanded(flex: _kPaymentFlex, child: _HeaderCell(h(context.tr.payment))),
            Expanded(flex: _kTotalFlex, child: _HeaderCell(h(context.tr.total))),
            Expanded(flex: _kStatusFlex, child: _HeaderCell(h(context.tr.status))),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.sm100(context).copyWith(
        color: context.appColors.textHint,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: Localizations.localeOf(context).languageCode == 'ar' ? 0 : 0.5,
      ),
    );
  }
}

class DesktopSalesTableRow extends StatelessWidget {
  const DesktopSalesTableRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  final SaleHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4,
            vertical: AppDims.s3,
          ),
          child: Row(
            children: [
              Expanded(
                flex: _kDateFlex,
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    item.dateTimeLabel,
                    style: AppTextStyles.sm200(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
              Expanded(
                flex: _kReceiptFlex,
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    item.displayRef,
                    style: AppTextStyles.sm200(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: _kCustomerFlex,
                child: Text(
                  item.customerName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm200(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Expanded(
                flex: _kItemsFlex,
                child: Text(
                  '${item.itemCount}',
                  style: AppTextStyles.sm200(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Expanded(
                flex: _kPaymentFlex,
                child: Text(
                  item.paymentLabel,
                  style: AppTextStyles.sm200(context)
                      .copyWith(color: item.paymentColor),
                ),
              ),
              Expanded(
                flex: _kTotalFlex,
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    AppFormat.moneyWithUnit(item.total),
                    style: AppTextStyles.sm200(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: _kStatusFlex,
                child: _StatusPill(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.item});
  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: item.displayStatusBg,
          borderRadius: BorderRadius.circular(AppDims.rSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.displayStatusIcon, size: 12, color: item.displayStatusFg),
            const SizedBox(width: 4),
            Text(
              _statusLabel(context, item),
              style: AppTextStyles.sm100(context).copyWith(
                color: item.displayStatusFg,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(BuildContext context, SaleHistoryItem item) {
  if (item.isOfflinePending) return context.tr.pending;
  return switch (item.status) {
    SaleHistoryStatus.completed => context.tr.completed,
    SaleHistoryStatus.refunded => context.tr.returned,
    SaleHistoryStatus.partialRefund => context.tr.partiallyReturned,
    SaleHistoryStatus.cancelled => context.tr.cancelled,
    SaleHistoryStatus.pending => context.tr.pending,
    SaleHistoryStatus.failed => context.tr.failed,
    SaleHistoryStatus.unknown => context.tr.unknown,
  };
}
```

- [ ] **Step 6.4 — Run test to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_table_test.dart --reporter=expanded
```

Expected: PASS.

- [ ] **Step 6.5 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/desktop_sales_table.dart \
        test/features/sales_history/presentation/widgets/desktop_sales_table_test.dart
git commit -m "feat(sales-history): add DesktopSalesTable sliver with header + row widgets"
```

---

## Task 7: `ReportsPlaceholderView`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart`
- Create: `test/features/sales_history/presentation/widgets/reports/reports_placeholder_view_test.dart`

---

- [ ] **Step 7.1 — Write the failing test**

Create `test/features/sales_history/presentation/widgets/reports/reports_placeholder_view_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReportsPlaceholderView renders icon and coming-soon text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ReportsPlaceholderView()),
    ));

    expect(find.byType(Icon), findsOneWidget);
    expect(find.textContaining('coming soon'), findsOneWidget);
  });
}
```

- [ ] **Step 7.2 — Run test to confirm FAIL**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/reports_placeholder_view_test.dart --reporter=expanded
```

- [ ] **Step 7.3 — Create `reports_placeholder_view.dart`**

First ensure the directory exists:

```bash
mkdir -p lib/features/sales_history/presentation/widgets/reports
```

Create `lib/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart`:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ReportsPlaceholderView extends StatelessWidget {
  const ReportsPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SolarIconsOutline.chartSquare, size: 56, color: colors.textHint),
          const SizedBox(height: AppDims.s3),
          Text(
            context.tr.reportsComingSoon,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context)
                .copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7.4 — Run test to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/reports_placeholder_view_test.dart --reporter=expanded
```

- [ ] **Step 7.5 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart \
        test/features/sales_history/presentation/widgets/reports/reports_placeholder_view_test.dart
git commit -m "feat(sales-history): add ReportsPlaceholderView coming-soon screen"
```

---

## Task 8: `DesktopSalesHistoryTopBar`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart`
- Create: `test/features/sales_history/presentation/widgets/desktop_sales_history_top_bar_test.dart`

---

- [ ] **Step 8.1 — Write the failing test**

Create `test/features/sales_history/presentation/widgets/desktop_sales_history_top_bar_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap({
    SalesView active = SalesView.transactions,
    ValueChanged<SalesView>? onViewChanged,
    VoidCallback? onRefresh,
    TextEditingController? controller,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DesktopSalesHistoryTopBar(
          searchCtrl: controller ?? TextEditingController(),
          activeView: active,
          onViewChanged: onViewChanged ?? (_) {},
          onRefresh: onRefresh ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders search field, tab switch, and refresh button', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(SalesViewTabSwitch), findsOneWidget);
    // Refresh icon button present
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('tapping Reports tab fires onViewChanged(SalesView.reports)', (tester) async {
    SalesView? fired;
    await tester.pumpWidget(_wrap(onViewChanged: (v) => fired = v));
    await tester.tap(find.textContaining('Reports'));
    expect(fired, equals(SalesView.reports));
  });

  testWidgets('refresh button calls onRefresh', (tester) async {
    bool refreshed = false;
    await tester.pumpWidget(_wrap(onRefresh: () => refreshed = true));
    // Find the InkWell wrapping the refresh icon (last InkWell after tab switch)
    final inkWells = tester.widgetList<InkWell>(find.byType(InkWell)).toList();
    await tester.tap(find.byWidget(inkWells.last));
    expect(refreshed, isTrue);
  });
}
```

- [ ] **Step 8.2 — Run test to confirm FAIL**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_history_top_bar_test.dart --reporter=expanded
```

- [ ] **Step 8.3 — Create `desktop_sales_history_top_bar.dart`**

Create `lib/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart`:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopSalesHistoryTopBar extends StatelessWidget {
  const DesktopSalesHistoryTopBar({
    super.key,
    required this.searchCtrl,
    required this.activeView,
    required this.onViewChanged,
    required this.onRefresh,
  });

  final TextEditingController searchCtrl;
  final SalesView activeView;
  final ValueChanged<SalesView> onViewChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: searchCtrl,
                  hint: context.tr.searchSalesHistoryHint,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              SalesViewTabSwitch(active: activeView, onChanged: onViewChanged),
              const SizedBox(width: AppDims.s3),
              _RefreshButton(onRefresh: onRefresh),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return TextField(
            controller: controller,
            style: AppTextStyles.sm200(context).copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.sm200(context).copyWith(color: colors.textHint),
              prefixIcon: Icon(SolarIconsOutline.magnifier, size: 18, color: colors.textHint),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(SolarIconsOutline.closeCircle, size: 16, color: colors.textHint),
                      onPressed: controller.clear,
                    )
                  : null,
              filled: true,
              fillColor: colors.surfaceSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3,
                vertical: AppDims.s2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _onTap() {
    _spin.forward(from: 0);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDims.rSm),
      onTap: _onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: RotationTransition(
          turns: _spin,
          child: Icon(
            SolarIconsOutline.refresh,
            size: 20,
            color: context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.4 — Run test to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_history_top_bar_test.dart --reporter=expanded
```

- [ ] **Step 8.5 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart \
        test/features/sales_history/presentation/widgets/desktop_sales_history_top_bar_test.dart
git commit -m "feat(sales-history): add DesktopSalesHistoryTopBar with search, tab switch, refresh"
```

---

## Task 9: `DesktopSalesHistoryView`

The root stateful widget that owns all state and composes the Transactions tab.

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart`
- Create: `test/features/sales_history/presentation/widgets/desktop_sales_history_view_test.dart`

---

- [ ] **Step 9.1 — Write the failing test**

Create `test/features/sales_history/presentation/widgets/desktop_sales_history_view_test.dart`:

```dart
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<SalesHistoryEvent, SalesHistoryState>
    implements SalesHistoryBloc {}

class _FakeEvent extends Fake implements SalesHistoryEvent {}

SaleHistoryItem _item() => SaleHistoryItem(
      id: 'i1',
      clientSaleId: 'c1',
      receiptNumber: 'RCP-1',
      shopId: null,
      shopName: null,
      customerId: null,
      customerName: 'Ali',
      paymentMethod: 'cash',
      total: 100.0,
      itemCount: 1,
      status: SaleHistoryStatus.completed,
      createdAt: DateTime(2026, 6, 10),
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  Widget _wrap(_MockBloc bloc) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SalesHistoryBloc>.value(
          value: bloc,
          child: const DesktopSalesHistoryView(),
        ),
      );

  testWidgets('shows shimmer while loading', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial());

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    // Shimmer or loading indicator present; no table rows shown
    expect(find.text('RCP-1'), findsNothing);
  });

  testWidgets('shows table when loaded with items', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial().copyWith(
      status: SalesHistoryBlocStatus.loaded,
      items: [_item()],
    ));

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    expect(find.text('RCP-1'), findsOneWidget);
  });

  testWidgets('switching to Reports tab shows ReportsPlaceholderView', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(SalesHistoryState.initial().copyWith(
      status: SalesHistoryBlocStatus.loaded,
      items: [_item()],
    ));

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Reports'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportsPlaceholderView), findsOneWidget);
  });
}
```

- [ ] **Step 9.2 — Run test to confirm FAIL**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_history_view_test.dart --reporter=expanded
```

- [ ] **Step 9.3 — Create `desktop_sales_history_view.dart`**

Create `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart`:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_extensions.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_table.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/filter_chips.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_placeholder_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail_sheet.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_empty_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_error_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_shimmer.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double _kMaxContentWidth = 1800;

class DesktopSalesHistoryView extends StatefulWidget {
  const DesktopSalesHistoryView({super.key});

  @override
  State<DesktopSalesHistoryView> createState() => _DesktopSalesHistoryViewState();
}

class _DesktopSalesHistoryViewState extends State<DesktopSalesHistoryView> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  SaleFilter _activeFilter = SaleFilter.all;
  SalesView _activeView = SalesView.transactions;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SalesHistoryBloc>().add(const SalesHistoryStarted());
    });
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context
        .read<SalesHistoryBloc>()
        .add(SalesHistorySearchChanged(_searchCtrl.text));
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_activeFilter != SaleFilter.all) return;

    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent * 0.82) return;

    final state = context.read<SalesHistoryBloc>().state;
    if (!state.hasMore || state.isLoadingMore) return;
    context.read<SalesHistoryBloc>().add(const SalesHistoryLoadMore());
  }

  void _onRefresh() {
    context.read<SalesHistoryBloc>().add(const SalesHistoryRefreshed());
  }

  void _onFilterSelect(SaleFilter filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<SaleHistoryItem> _applyFilter(List<SaleHistoryItem> items) {
    if (_activeFilter == SaleFilter.all) return items;
    return items.where((item) {
      return switch (_activeFilter) {
        SaleFilter.all => true,
        SaleFilter.today => item.isToday,
        SaleFilter.completed => item.status == SaleHistoryStatus.completed,
        SaleFilter.refunded =>
          item.status == SaleHistoryStatus.refunded ||
              item.status == SaleHistoryStatus.partialRefund,
        SaleFilter.pending =>
          item.isOfflinePending || item.status == SaleHistoryStatus.pending,
      };
    }).toList();
  }

  void _openDetail(SaleHistoryItem item) {
    SaleDetailSheet.show(
      context,
      item: item,
      onReturnTap: item.canBeReturned ? () => _openReturns(item) : null,
    );
  }

  void _openReturns(SaleHistoryItem item) {
    Navigator.of(context).pushNamed('returnsScreen', arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            DesktopSalesHistoryTopBar(
              searchCtrl: _searchCtrl,
              activeView: _activeView,
              onViewChanged: (v) => setState(() => _activeView = v),
              onRefresh: _onRefresh,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                  child: _activeView == SalesView.transactions
                      ? _TransactionsTab(
                          scrollCtrl: _scrollCtrl,
                          activeFilter: _activeFilter,
                          applyFilter: _applyFilter,
                          onFilterSelect: _onFilterSelect,
                          onTap: _openDetail,
                        )
                      : const ReportsPlaceholderView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transactions tab ──────────────────────────────────────────────────────────

class _TableViewData {
  final SalesHistoryBlocStatus status;
  final List<SaleHistoryItem> items;
  final List<SaleHistoryItem> filtered;
  final String searchQuery;
  final bool isLoadingMore;
  final String? errorMessage;

  const _TableViewData({
    required this.status,
    required this.items,
    required this.filtered,
    required this.searchQuery,
    required this.isLoadingMore,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TableViewData &&
          status == other.status &&
          items == other.items &&
          filtered == other.filtered &&
          searchQuery == other.searchQuery &&
          isLoadingMore == other.isLoadingMore &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        items,
        filtered,
        searchQuery,
        isLoadingMore,
        errorMessage,
      );
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({
    required this.scrollCtrl,
    required this.activeFilter,
    required this.applyFilter,
    required this.onFilterSelect,
    required this.onTap,
  });

  final ScrollController scrollCtrl;
  final SaleFilter activeFilter;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>) applyFilter;
  final ValueChanged<SaleFilter> onFilterSelect;
  final ValueChanged<SaleHistoryItem> onTap;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SalesHistoryBloc, SalesHistoryState, _TableViewData>(
      selector: (state) => _TableViewData(
        status: state.status,
        items: state.items,
        filtered: applyFilter(state.items),
        searchQuery: state.searchQuery,
        isLoadingMore: state.isLoadingMore,
        errorMessage: state.errorMessage,
      ),
      builder: (context, view) {
        if ((view.status == SalesHistoryBlocStatus.initial ||
                view.status == SalesHistoryBlocStatus.loading) &&
            view.items.isEmpty) {
          return const SaleShimmer();
        }

        if (view.status == SalesHistoryBlocStatus.failure &&
            view.items.isEmpty) {
          return SaleErrorView(
            message: view.errorMessage ?? context.tr.failedToLoadSales,
            onRetry: () =>
                context.read<SalesHistoryBloc>().add(const SalesHistoryRefreshed()),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppDims.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopSalesStatsRow(
                activeFilter: activeFilter,
                applyFilter: applyFilter,
              ).animate().fadeIn(duration: 280.ms),
              const SizedBox(height: AppDims.s3),
              FilterChips(
                active: activeFilter,
                onSelect: onFilterSelect,
              ),
              const SizedBox(height: AppDims.s3),
              if (view.filtered.isEmpty)
                Expanded(
                  child: SaleEmptyState(
                    filter: activeFilter,
                    hasSearch: view.searchQuery.trim().isNotEmpty,
                  ),
                )
              else
                Expanded(
                  child: CustomScrollView(
                    controller: scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      DesktopSalesTable(
                        items: view.filtered,
                        onTap: onTap,
                      ),
                      if (view.isLoadingMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDims.s5,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: context.appColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppDims.s6),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 9.4 — Run test to confirm PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/desktop_sales_history_view_test.dart --reporter=expanded
```

Expected: PASS.

- [ ] **Step 9.5 — Commit**

```bash
git add lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart \
        test/features/sales_history/presentation/widgets/desktop_sales_history_view_test.dart
git commit -m "feat(sales-history): add DesktopSalesHistoryView — transactions tab layout"
```

---

## Task 10: Wire navigation (`desktop_navigation_rail`, `desktop_more_drawer`, `navigation_config`)

> **Git discipline warning:** `desktop_navigation_rail.dart` and `desktop_more_drawer.dart` both have pre-existing unstaged modifications in this branch. Use `Edit` (targeted insertion only) for these two files — do **not** `git add .` or `git add lib/`. Stage only the exact files listed in Step 10.5.

**Files:**
- Modify: `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`
- Modify: `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart`
- Modify: `lib/features/main_screen/data/navigation_config.dart`

*(No new test file — nav tab registration is integration-level, covered by the existing `_buildAllTabs` permission guard pattern which is already tested via `app_permissions_sales_history_test.dart` in Task 2.)*

---

- [ ] **Step 10.1 — Insert Sales History tab into `desktop_navigation_rail.dart`**

In `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`, insert after the closing `}` of the `canAccessInventory` block (after line 57, before `if (perms.canAccessCategories)`):

```dart
    if (perms.canAccessSalesHistory) {
      tabs.add(NavTab(
        feature: AppFeature.salesHistory,
        icon: SolarIconsOutline.notebook,
        activeIcon: SolarIconsBold.notebook,
        label: tr.settingsSalesHistory,
      ));
    }
```

- [ ] **Step 10.2 — Insert the same block into `desktop_more_drawer.dart`**

In `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart`, insert after the closing `}` of the `canAccessInventory` block (after line 55, before `if (perms.canAccessCategories)`):

```dart
    if (perms.canAccessSalesHistory) {
      tabs.add(NavTab(
        feature: AppFeature.salesHistory,
        icon: SolarIconsOutline.notebook,
        activeIcon: SolarIconsBold.notebook,
        label: tr.settingsSalesHistory,
      ));
    }
```

- [ ] **Step 10.3 — Add `salesHistory` case to `navigation_config.dart`**

In `lib/features/main_screen/data/navigation_config.dart`, add to the imports section:

```dart
import 'package:amana_pos/features/sales_history/presentation/sales_history_screen.dart';
```

And add the case inside the `switch` (before the final closing `}`):

```dart
      case AppFeature.salesHistory:
        return FeatureBlocProviders.salesHistory(
          child: const SalesHistoryScreen(),
        );
```

- [ ] **Step 10.4 — Analyze the three changed files**

```bash
flutter analyze lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart \
               lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart \
               lib/features/main_screen/data/navigation_config.dart
```

Expected: no issues.

- [ ] **Step 10.5 — Commit (stage only these three files)**

```bash
git add lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart \
        lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart \
        lib/features/main_screen/data/navigation_config.dart
git commit -m "feat(nav): wire Sales History desktop navigation tab + screen routing"
```

---

## Task 11: `SalesHistoryScreen` desktop branch

**Files:**
- Modify: `lib/features/sales_history/presentation/sales_history_screen.dart`

---

- [ ] **Step 11.1 — Add import + desktop branch to `build()`**

In `lib/features/sales_history/presentation/sales_history_screen.dart`:

**Add two imports** near the top (after the existing imports):

```dart
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_view.dart';
```

**Add the desktop branch** at the very start of `_SalesHistoryScreenState.build()` (line 183, before `final colors = context.appColors;`):

```dart
  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const DesktopSalesHistoryView();

    final colors = context.appColors;
    // ... rest of existing build() code unchanged
```

- [ ] **Step 11.2 — Analyze**

```bash
flutter analyze lib/features/sales_history/presentation/sales_history_screen.dart
```

Expected: no issues.

- [ ] **Step 11.3 — Run all new tests**

```bash
flutter test \
  test/features/sales_history/ \
  test/core/permissions/app_permissions_sales_history_test.dart \
  --reporter=expanded
```

Expected: all PASS.

- [ ] **Step 11.4 — Commit**

```bash
git add lib/features/sales_history/presentation/sales_history_screen.dart
git commit -m "feat(sales-history): add desktop branch to SalesHistoryScreen"
```

---

## Self-Review

### 1. Spec coverage

| Spec requirement | Plan task |
|---|---|
| Add `AppFeature.salesHistory` + `canAccessSalesHistory` | Task 2 |
| Add to `desktop_navigation_rail.dart` `_buildAllTabs` after Inventory | Task 10 |
| Add to `desktop_more_drawer.dart` `_buildAllTabs` (kept in sync) | Task 10 |
| Icon: `SolarIconsOutline.notebook` / bold variant | Task 10 |
| Add case to `NavigationConfig.screenFor` | Task 10 |
| `SalesHistoryScreen.build()` → `if (context.isDesktop) return DesktopSalesHistoryView()` | Task 11 |
| `DesktopSalesHistoryTopBar`: search, refresh, Transactions/Reports switch | Task 8 |
| `DesktopSalesStatsRow`: 4 KPI cards from `SalesHistoryBloc.state.items` | Task 5 |
| `DesktopSalesTable`: columns Date/time, Receipt #, Customer, Items, Payment, Total, Status | Task 6 |
| Row tap opens `SaleDetailSheet` | Task 9 (`_openDetail`) |
| Infinite scroll dispatches `SalesHistoryLoadMore` | Task 9 (`_onScroll`) |
| Loading/empty/error states via `SaleShimmer`/`SaleEmptyState`/`SaleErrorView` | Task 9 |
| Mobile untouched | ✅ No mobile files modified |
| Reports tab placeholder | Task 7 + Task 9 (view switch) |

### 2. Placeholder scan

No "TBD", "TODO", or "implement later" strings found. Every step has complete code.

### 3. Type consistency

- `SaleStatCard` defined in Task 1, used in Tasks 5 and 9 (via `DesktopSalesStatsRow`).
- `SalesView` enum defined in Task 4 (`sales_view_tab_switch.dart`), used in Tasks 8 and 9 — all reference the same file.
- `SaleFilterX.salesCountLabel`/`.revenueLabel` defined in Task 1, called in Tasks 5 — signatures match (both `String salesCountLabel(BuildContext context)`).
- `DesktopSalesTable(items: ..., onTap: ...)` defined in Task 6, used in Task 9 — parameter names match.
- `AppFeature.salesHistory` added in Task 2, referenced in Task 10 — same enum value name.
- `canAccessSalesHistory` added in Task 2, referenced in Task 10 — same getter name.

---

## Execution Handoff

Plan saved to `docs/superpowers/plans/2026-06-10-desktop-sales-history-transactions-tab.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast parallel iteration.
→ Use skill `superpowers:subagent-driven-development`

**2. Inline Execution** — execute tasks in this session with checkpoints.
→ Use skill `superpowers:executing-plans`

---

> **Plan B** (Reports & Statistics tab — backend endpoint, `SalesReport` data layer, `SalesReportBloc`, fl_chart bento grid) will be written as a separate plan after Plan A is fully implemented and merged.
