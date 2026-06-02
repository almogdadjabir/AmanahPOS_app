# Desktop Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add adaptive desktop layout (NavigationRail, persistent cart column, side panels, content-width caps, responsive product grids) across all screens of AmanaPOS, targeting macOS, Windows, and web — without changing any mobile behaviour.

**Architecture:** Shell-first. Five new `lib/core/responsive/` utilities land first (breakpoints, extension, layout metrics, adaptive flex, adaptive sheet). A new `DesktopShell` replaces `MainScreen`'s Scaffold on desktop; mobile path is byte-for-byte untouched. All `showModalBottomSheet` call sites are replaced with `showAdaptivePanel`. Each screen then adds a single `if (context.isDesktop)` branch that swaps layout from stacked to side-by-side.

**Tech Stack:** Flutter 3.x, BLoC (`flutter_bloc`), Solar Icons, existing `AppColors / AppSpacing / AppRadius / AppDims` tokens (no new design constants).

**Spec:** `docs/superpowers/specs/2026-06-02-desktop-support-design.md`

---

## File Map

### New files
```
lib/core/responsive/
  breakpoints.dart                — Breakpoints constants + DeviceClass enum
  responsive.dart                 — BuildContext extension (isMobile/isTablet/isDesktop/responsive<T>)
  layout_metrics.dart             — BuildContext extension (pagePadding/sectionGap/maxContentWidth/gridColumnsFor)
  adaptive_flex.dart              — AdaptiveFlex widget (Column ↔ Row based on deviceClass)
  adaptive_sheet.dart             — showAdaptivePanel<T>() (bottom sheet on mobile, end-panel on desktop)

lib/features/main_screen/presentation/widgets/
  desktop_navigation_rail.dart    — NavigationRail with Sell FAB pinned at bottom
  desktop_shell.dart              — Desktop scaffold: rail + divider + [PosAppBar / currentScreen]

test/core/responsive/
  responsive_test.dart            — Widget tests for ResponsiveContext + AdaptiveFlex
```

### Modified files
```
lib/features/main_screen/presentation/main_screen.dart              — isDesktop branch → DesktopShell
lib/features/cart/presentation/cart_panel.dart                      — sheet migration
lib/features/pos/presentation/widgets/sale_receipt_sheet.dart       — sheet migration
lib/features/main_screen/presentation/widgets/location_chip.dart    — sheet migration
lib/features/products/presentation/widgets/add_product_sheet.dart   — sheet migration
lib/features/products/presentation/widgets/edit_product_sheet.dart  — sheet migration
lib/features/products/presentation/widgets/category_picker.dart     — sheet migration
lib/features/category/presentation/widgets/add_category_sheet.dart  — sheet migration
lib/features/category/presentation/widgets/edit_category_sheet.dart — sheet migration
lib/features/business/presentation/widgets/add_business_sheet.dart  — sheet migration
lib/features/business/presentation/widgets/edit_business_sheet.dart — sheet migration
lib/features/business/presentation/widgets/shop/add_shop_sheet.dart — sheet migration
lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart — sheet migration
lib/features/users/presentation/widgets/add_user_sheet.dart         — sheet migration
lib/features/users/presentation/widgets/edit_user_sheet.dart        — sheet migration
lib/features/inventory/presentation/widgets/inbound_receiving_sheet.dart — sheet migration
lib/features/inventory/presentation/widgets/stock_action_sheet.dart — sheet migration
lib/features/inventory/presentation/widgets/add_stock_product_sheet.dart — sheet migration
lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart    — sheet migration
lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart    — sheet migration
lib/features/inventory/presentation/premium/sheets/stock_levels_sheet.dart — sheet migration
lib/features/inventory/presentation/premium/sheets/low_stock_sheet.dart    — sheet migration
lib/features/inventory/presentation/premium/sheets/expiry_report_sheet.dart — sheet migration
lib/features/customers/presentation/widgets/customer_form_sheet.dart — sheet migration
lib/features/returns/presentation/widgets/return_success_sheet.dart  — sheet migration
lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart — sheet migration
lib/features/notification/presentation/widgets/notification_tile.dart   — sheet migration
lib/features/settings/presentation/settings_screen.dart             — sheet migration + desktop layout
lib/features/settings/presentation/widgets/bankak_payment_card.dart — sheet migration
lib/common/widgets/permission_required_sheet.dart                   — sheet migration
lib/common/widgets/image_upload_box.dart                            — sheet migration
lib/widgets/app_deactivate_bottom_sheet.dart                        — sheet migration
lib/features/pos/presentation/pos_screen.dart                       — desktop Row layout
lib/features/pos/presentation/widgets/product_grid.dart             — add optional crossAxisCount param (if hardcoded today)
lib/features/business/presentation/business_screen.dart             — desktop content-width + grid cols
lib/features/products/presentation/product_screen.dart              — desktop grid cols
lib/features/inventory/presentation/basic_inventory_view.dart       — desktop AdaptiveFlex (check path)
```

---

## Task 1 — Breakpoints + DeviceClass

**Files:**
- Create: `lib/core/responsive/breakpoints.dart`

- [ ] **Create the file**

```dart
// lib/core/responsive/breakpoints.dart
abstract final class Breakpoints {
  Breakpoints._();

  static const double tablet  = 600;
  static const double desktop = 1024;
  static const double large   = 1440;
}

enum DeviceClass { mobile, tablet, desktop }
```

- [ ] **Verify it compiles**

```bash
flutter analyze lib/core/responsive/breakpoints.dart
```

Expected: no issues.

- [ ] **Commit**

```bash
git add lib/core/responsive/breakpoints.dart
git commit -m "feat(responsive): add Breakpoints constants and DeviceClass enum"
```

---

## Task 2 — ResponsiveContext extension + widget test

**Files:**
- Create: `lib/core/responsive/responsive.dart`
- Create: `test/core/responsive/responsive_test.dart`

- [ ] **Write the failing tests first**

```dart
// test/core/responsive/responsive_test.dart
import 'package:amana_pos/core/responsive/breakpoints.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, double width) => MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  group('ResponsiveContext.deviceClass', () {
    testWidgets('returns mobile below 600', (tester) async {
      late DeviceClass result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) { result = ctx.deviceClass; return const SizedBox(); }),
        390,
      ));
      expect(result, DeviceClass.mobile);
    });

    testWidgets('returns tablet at 768', (tester) async {
      late DeviceClass result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) { result = ctx.deviceClass; return const SizedBox(); }),
        768,
      ));
      expect(result, DeviceClass.tablet);
    });

    testWidgets('returns desktop at 1024', (tester) async {
      late DeviceClass result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) { result = ctx.deviceClass; return const SizedBox(); }),
        1024,
      ));
      expect(result, DeviceClass.desktop);
    });

    testWidgets('responsive() picks tablet value when provided', (tester) async {
      late String result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          result = ctx.responsive(mobile: 'mob', tablet: 'tab', desktop: 'desk');
          return const SizedBox();
        }),
        768,
      ));
      expect(result, 'tab');
    });

    testWidgets('responsive() falls back to desktop when tablet omitted', (tester) async {
      late String result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          result = ctx.responsive(mobile: 'mob', desktop: 'desk');
          return const SizedBox();
        }),
        768,
      ));
      expect(result, 'desk');
    });
  });
}
```

- [ ] **Run tests — expect failure (class not found)**

```bash
flutter test test/core/responsive/responsive_test.dart
```

Expected: compilation error — `ResponsiveContext` not defined.

- [ ] **Create the extension**

```dart
// lib/core/responsive/responsive.dart
import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

extension ResponsiveContext on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  DeviceClass get deviceClass {
    final w = _width;
    if (w >= Breakpoints.desktop) return DeviceClass.desktop;
    if (w >= Breakpoints.tablet)  return DeviceClass.tablet;
    return DeviceClass.mobile;
  }

  bool get isMobile  => deviceClass == DeviceClass.mobile;
  bool get isTablet  => deviceClass == DeviceClass.tablet;
  bool get isDesktop => deviceClass == DeviceClass.desktop;
  bool get isWide    => _width >= Breakpoints.tablet;

  T responsive<T>({required T mobile, T? tablet, required T desktop}) =>
      switch (deviceClass) {
        DeviceClass.desktop => desktop,
        DeviceClass.tablet  => tablet ?? desktop,
        DeviceClass.mobile  => mobile,
      };
}
```

- [ ] **Run tests — expect all pass**

```bash
flutter test test/core/responsive/responsive_test.dart
```

Expected: 5 tests pass.

- [ ] **Commit**

```bash
git add lib/core/responsive/responsive.dart test/core/responsive/responsive_test.dart
git commit -m "feat(responsive): add ResponsiveContext BuildContext extension"
```

---

## Task 3 — LayoutMetrics extension

**Files:**
- Create: `lib/core/responsive/layout_metrics.dart`

- [ ] **Create the file**

```dart
// lib/core/responsive/layout_metrics.dart
import 'package:amana_pos/core/responsive/breakpoints.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

extension LayoutMetrics on BuildContext {
  EdgeInsets get pagePadding => responsive(
        mobile:  const EdgeInsets.all(AppSpacing.md),
        tablet:  const EdgeInsets.all(AppSpacing.xl),
        desktop: const EdgeInsets.all(AppSpacing.xxl),
      );

  double get sectionGap =>
      responsive(mobile: AppSpacing.lg, desktop: AppSpacing.xxl);

  double get maxContentWidth => Breakpoints.large;

  int gridColumnsFor(double maxWidth, {double tile = 180}) =>
      (maxWidth / tile).floor().clamp(2, 8);
}
```

- [ ] **Add gridColumnsFor tests to `responsive_test.dart`** (append to the `main()` body)

```dart
group('LayoutMetrics.gridColumnsFor', () {
  testWidgets('clamps to minimum 2', (tester) async {
    late int result;
    await tester.pumpWidget(_wrap(
      Builder(builder: (ctx) {
        result = ctx.gridColumnsFor(300, tile: 200);
        return const SizedBox();
      }),
      1024,
    ));
    expect(result, 2); // floor(300/200)=1 → clamped to 2
  });

  testWidgets('returns 4 for 800px / 200px tile', (tester) async {
    late int result;
    await tester.pumpWidget(_wrap(
      Builder(builder: (ctx) {
        result = ctx.gridColumnsFor(800, tile: 200);
        return const SizedBox();
      }),
      1024,
    ));
    expect(result, 4);
  });
});
```

- [ ] **Run tests**

```bash
flutter test test/core/responsive/responsive_test.dart
```

Expected: all pass.

- [ ] **Commit**

```bash
git add lib/core/responsive/layout_metrics.dart test/core/responsive/responsive_test.dart
git commit -m "feat(responsive): add LayoutMetrics extension (pagePadding, gridColumnsFor)"
```

---

## Task 4 — AdaptiveFlex widget

**Files:**
- Create: `lib/core/responsive/adaptive_flex.dart`

- [ ] **Add AdaptiveFlex tests to `responsive_test.dart`** (append to `main()` body — import AdaptiveFlex at top of file too)

```dart
// add import at top of test file:
// import 'package:amana_pos/core/responsive/adaptive_flex.dart';

group('AdaptiveFlex', () {
  testWidgets('uses horizontal Flex on desktop', (tester) async {
    await tester.pumpWidget(_wrap(
      AdaptiveFlex(children: [const Text('A'), const Text('B')]),
      1024,
    ));
    final flex = tester.widget<Flex>(find.byType(Flex));
    expect(flex.direction, Axis.horizontal);
  });

  testWidgets('uses vertical Flex on mobile', (tester) async {
    await tester.pumpWidget(_wrap(
      AdaptiveFlex(children: [const Text('A'), const Text('B')]),
      390,
    ));
    final flex = tester.widget<Flex>(find.byType(Flex));
    expect(flex.direction, Axis.vertical);
  });
});
```

- [ ] **Run tests — expect failure**

```bash
flutter test test/core/responsive/responsive_test.dart
```

Expected: compilation error — `AdaptiveFlex` not defined.

- [ ] **Create AdaptiveFlex**

```dart
// lib/core/responsive/adaptive_flex.dart
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

class AdaptiveFlex extends StatelessWidget {
  const AdaptiveFlex({
    super.key,
    required this.children,
    this.desktopIsRow = true,
    this.spacing = AppSpacing.md,
    this.crossAxis = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final bool desktopIsRow;
  final double spacing;
  final CrossAxisAlignment crossAxis;

  @override
  Widget build(BuildContext context) {
    final useRow = context.isDesktop && desktopIsRow;
    return Flex(
      direction: useRow ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: crossAxis,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0)
            SizedBox(width: useRow ? spacing : 0, height: useRow ? 0 : spacing),
          children[i],
        ],
      ],
    );
  }
}
```

- [ ] **Run tests — expect all pass**

```bash
flutter test test/core/responsive/responsive_test.dart
```

Expected: all pass.

- [ ] **Commit**

```bash
git add lib/core/responsive/adaptive_flex.dart test/core/responsive/responsive_test.dart
git commit -m "feat(responsive): add AdaptiveFlex widget"
```

---

## Task 5 — showAdaptivePanel

**Files:**
- Create: `lib/core/responsive/adaptive_sheet.dart`

- [ ] **Create the function**

```dart
// lib/core/responsive/adaptive_sheet.dart
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet on mobile and a slide-in end-panel on desktop.
/// RTL-aware: the panel slides from the start side in RTL locales.
Future<T?> showAdaptivePanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double desktopWidth = 480,
  bool isScrollControlled = true,
}) {
  if (context.isDesktop) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: AppDims.medium,
      pageBuilder: (ctx, _, __) {
        final isRtl = Directionality.of(ctx) == TextDirection.rtl;
        return Align(
          alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            child: SizedBox(
              width: desktopWidth,
              height: double.infinity,
              child: SafeArea(child: builder(ctx)),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final isRtl = Directionality.of(ctx) == TextDirection.rtl;
        final begin = Offset(isRtl ? -1 : 1, 0);
        return SlideTransition(
          position: Tween(begin: begin, end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: builder,
  );
}
```

- [ ] **Verify it compiles**

```bash
flutter analyze lib/core/responsive/adaptive_sheet.dart
```

Expected: no issues.

- [ ] **Commit**

```bash
git add lib/core/responsive/adaptive_sheet.dart
git commit -m "feat(responsive): add showAdaptivePanel (bottom sheet ↔ end-panel)"
```

---

## Task 6 — DesktopNavigationRail

**Files:**
- Create: `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`

The rail reuses `BottomNav.buildTabs()` for permission-gated tab list (filtering out the Sell/POS tab). Sell is rendered as a standalone FAB in `trailing`, not as a `NavigationRailDestination` — so `selectedIndex` only covers non-Sell destinations.

- [ ] **Create the widget**

```dart
// lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/bottom_nav.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopNavigationRail extends StatefulWidget {
  const DesktopNavigationRail({super.key});

  @override
  State<DesktopNavigationRail> createState() => _DesktopNavigationRailState();
}

class _DesktopNavigationRailState extends State<DesktopNavigationRail> {
  bool _extended = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        final allTabs = BottomNav.buildTabs(context, state.permissions);
        final railTabs =
            allTabs.where((t) => t.feature != AppFeature.pos).toList();
        final isPosActive = state.currentFeature == AppFeature.pos;

        final activeIdx = _activeIndex(railTabs, state.currentFeature);
        final colors = context.appColors;

        return NavigationRail(
          extended: _extended,
          minWidth: 76,
          minExtendedWidth: 248,
          backgroundColor: colors.surface,
          groupAlignment: -1,
          selectedIndex: activeIdx,
          indicatorColor: colors.primary.withValues(alpha: 0.12),
          selectedIconTheme: IconThemeData(color: colors.primary),
          selectedLabelTextStyle: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedIconTheme: IconThemeData(color: colors.textSecondary),
          unselectedLabelTextStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
          onDestinationSelected: (i) => _onTap(context, railTabs[i]),
          leading: GestureDetector(
            onTap: () => setState(() => _extended = !_extended),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.lg, bottom: AppSpacing.md),
              child: const BrandLogo(),
            ),
          ),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: _SellFab(
                  isActive: isPosActive,
                  extended: _extended,
                ),
              ),
            ),
          ),
          destinations: [
            for (final tab in railTabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: Text(tab.label),
              ),
          ],
        );
      },
    );
  }

  int? _activeIndex(List<NavTab> railTabs, AppFeature? currentFeature) {
    if (currentFeature == AppFeature.pos) return null;
    for (int i = 0; i < railTabs.length; i++) {
      final tab = railTabs[i];
      if (tab.isMore) {
        final directFeatures = railTabs
            .where((t) => !t.isMore && t.feature != null)
            .map((t) => t.feature!)
            .toSet();
        if (!directFeatures.contains(currentFeature)) return i;
      } else if (tab.feature == currentFeature) {
        return i;
      }
    }
    return null;
  }

  void _onTap(BuildContext context, NavTab tab) {
    if (tab.isMore) {
      Navigator.of(context).pushNamed(RouteStrings.settingsScreen);
      return;
    }
    if (tab.feature != null) {
      context
          .read<NavigationBloc>()
          .add(NavigationFeatureSelected(tab.feature!));
    }
  }
}

class _SellFab extends StatelessWidget {
  const _SellFab({required this.isActive, required this.extended});

  final bool isActive;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => context
          .read<NavigationBloc>()
          .add(const NavigationFeatureSelected(AppFeature.pos)),
      child: AnimatedContainer(
        duration: AppDims.fast,
        width: extended ? 200 : 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isActive ? colors.primary : colors.surfaceSoft,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.cartLarge_4,
              color: isActive ? Colors.white : colors.textSecondary,
              size: 24,
            ),
            if (extended) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Sell',
                style: TextStyle(
                  color: isActive ? Colors.white : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Note:** If `BrandLogo` is not the correct widget name, check `lib/widgets/` — alternatives are `AmanaLogo` (`lib/widgets/amana_logo.dart`). Use whichever renders the app logo mark.

- [ ] **Verify it compiles**

```bash
flutter analyze lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart
```

Expected: no issues. Fix any import path mismatches (e.g. `BrandLogo` → `AmanaLogo` if needed).

- [ ] **Commit**

```bash
git add lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart
git commit -m "feat(desktop): add DesktopNavigationRail with Sell FAB at bottom"
```

---

## Task 7 — DesktopShell

**Files:**
- Create: `lib/features/main_screen/presentation/widgets/desktop_shell.dart`

- [ ] **Create the widget**

```dart
// lib/features/main_screen/presentation/widgets/desktop_shell.dart
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_navigation_rail.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/pos_app_bar.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  static const double _topBarHeight = 74;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const DesktopNavigationRail(),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.border,
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: _topBarHeight,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.xs,
                    ),
                    child: const PosAppBar(),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colors.border),
                Expanded(
                  child: BlocBuilder<NavigationBloc, NavigationState>(
                    buildWhen: (prev, curr) =>
                        prev.currentFeature != curr.currentFeature,
                    builder: (context, state) => state.currentScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Verify it compiles**

```bash
flutter analyze lib/features/main_screen/presentation/widgets/desktop_shell.dart
```

Expected: no issues.

- [ ] **Commit**

```bash
git add lib/features/main_screen/presentation/widgets/desktop_shell.dart
git commit -m "feat(desktop): add DesktopShell (rail + top bar + content area)"
```

---

## Task 8 — Wire MainScreen to DesktopShell

**Files:**
- Modify: `lib/features/main_screen/presentation/main_screen.dart`

- [ ] **Add isDesktop branch to `MainScreen.build`**

In `main_screen.dart`, add two imports at the top of the file:

```dart
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_shell.dart';
```

Then in the `build` method, wrap the return so `OfflinePreparationListener` covers both branches and the desktop path short-circuits before the mobile `Scaffold`:

```dart
@override
Widget build(BuildContext context) {
  final colors = context.appColors;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final overlayStyle = isDark
      ? SystemUiOverlayStyle.light.copyWith(/* ... existing ... */)
      : SystemUiOverlayStyle.dark.copyWith(/* ... existing ... */);

  // ── Desktop: rail shell replaces the mobile Scaffold ──────────────────
  if (context.isDesktop) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: OfflinePreparationListener(child: const DesktopShell()),
    );
  }

  // ── Mobile: unchanged ─────────────────────────────────────────────────
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: overlayStyle,
    child: OfflinePreparationListener(
      child: Scaffold(
        extendBody: true,
        backgroundColor: colors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: _appBarHeight,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          systemOverlayStyle: overlayStyle,
          title: const PosAppBar(),
        ),
        body: BlocBuilder<NavigationBloc, NavigationState>(
          buildWhen: (prev, curr) =>
              prev.currentFeature != curr.currentFeature,
          builder: (context, state) => state.currentScreen,
        ),
        bottomNavigationBar: const MainBottomArea(),
      ),
    ),
  );
}
```

- [ ] **Run the app at 1024px+ width and verify the rail appears**

```bash
flutter run -d macos
# or: flutter run -d chrome
```

Resize the window above 1024px. You should see the rail with the brand logo, nav destinations, and the round Sell FAB at the bottom. Mobile layout (bottom nav + center Sell FAB) should still appear when window is narrower than 1024px.

- [ ] **Commit**

```bash
git add lib/features/main_screen/presentation/main_screen.dart
git commit -m "feat(desktop): wire MainScreen to DesktopShell on desktop"
```

---

## Task 9 — Sheet migration: cart + POS + main_screen (3 files)

**Migration pattern:** Add `import 'package:amana_pos/core/responsive/adaptive_sheet.dart';` to each file, then replace every `showModalBottomSheet(context: context, ...)` call with `showAdaptivePanel(context, desktopWidth: <N>, builder: ...)`. The `isScrollControlled`, `showDragHandle`, `backgroundColor`, and `shape` parameters are handled inside `showAdaptivePanel` and should be removed from the call site.

### `lib/features/cart/presentation/cart_panel.dart`

- [ ] **Replace `_openCart`**

Find the existing `_openCart` method which calls `showModalBottomSheet`. Replace the entire call with:

```dart
void _openCart(BuildContext context) {
  final posBloc = context.read<PosBloc>();

  showAdaptivePanel<void>(
    context,
    desktopWidth: 392,
    builder: (sheetCtx) {
      final size = MediaQuery.sizeOf(sheetCtx);
      final safeBottom = MediaQuery.viewPaddingOf(sheetCtx).bottom;
      final sheetHeight = math.max(
        _minSheetHeight,
        size.height - _bottomReserve - safeBottom,
      );
      return SizedBox(
        height: sheetHeight,
        child: BlocProvider.value(
          value: posBloc,
          child: ExpandedCart(
            onCollapse: () => Navigator.of(sheetCtx).pop(),
            onCheckout: onCheckout,
          ),
        ),
      );
    },
  );
}
```

Add the import at the top of `cart_panel.dart`:
```dart
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
```

### `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`

- [ ] **Replace `showModalBottomSheet` call**

Find the `showModalBottomSheet` call and replace it with:

```dart
showAdaptivePanel<void>(
  context,
  desktopWidth: 360,
  builder: (ctx) => /* existing builder content */,
);
```

Add import: `import 'package:amana_pos/core/responsive/adaptive_sheet.dart';`

### `lib/features/main_screen/presentation/widgets/location_chip.dart`

- [ ] **Replace `showModalBottomSheet` call**

```dart
showAdaptivePanel<void>(
  context,
  desktopWidth: 360,
  builder: (ctx) => /* existing builder content */,
);
```

Add import: `import 'package:amana_pos/core/responsive/adaptive_sheet.dart';`

- [ ] **Verify all three files compile**

```bash
flutter analyze lib/features/cart/presentation/cart_panel.dart \
  lib/features/pos/presentation/widgets/sale_receipt_sheet.dart \
  lib/features/main_screen/presentation/widgets/location_chip.dart
```

Expected: no issues.

- [ ] **Commit**

```bash
git add lib/features/cart/presentation/cart_panel.dart \
        lib/features/pos/presentation/widgets/sale_receipt_sheet.dart \
        lib/features/main_screen/presentation/widgets/location_chip.dart
git commit -m "feat(responsive): migrate cart/POS/main_screen sheets to showAdaptivePanel"
```

---

## Task 10 — Sheet migration: products + category + business + users (11 files)

Apply the same migration pattern from Task 9 to each file below. For each file:
1. Add `import 'package:amana_pos/core/responsive/adaptive_sheet.dart';`
2. Replace `showModalBottomSheet(context: context, ...)` → `showAdaptivePanel(context, desktopWidth: <N>, builder: ...)`
3. Remove `isScrollControlled`, `showDragHandle`, `backgroundColor`, `shape` from call site (they're handled inside `showAdaptivePanel`)

| File | `desktopWidth` |
|---|---|
| `lib/features/products/presentation/widgets/add_product_sheet.dart` | 480 |
| `lib/features/products/presentation/widgets/edit_product_sheet.dart` | 480 |
| `lib/features/products/presentation/widgets/category_picker.dart` | 360 |
| `lib/features/category/presentation/widgets/add_category_sheet.dart` | 480 |
| `lib/features/category/presentation/widgets/edit_category_sheet.dart` | 480 |
| `lib/features/business/presentation/widgets/add_business_sheet.dart` | 480 |
| `lib/features/business/presentation/widgets/edit_business_sheet.dart` | 480 |
| `lib/features/business/presentation/widgets/shop/add_shop_sheet.dart` | 480 |
| `lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart` | 480 |
| `lib/features/users/presentation/widgets/add_user_sheet.dart` | 480 |
| `lib/features/users/presentation/widgets/edit_user_sheet.dart` | 480 |

- [ ] **Apply migration to all 11 files** (open each, add import, replace call)

- [ ] **Verify all 11 files compile**

```bash
flutter analyze \
  lib/features/products/presentation/widgets/add_product_sheet.dart \
  lib/features/products/presentation/widgets/edit_product_sheet.dart \
  lib/features/products/presentation/widgets/category_picker.dart \
  lib/features/category/presentation/widgets/add_category_sheet.dart \
  lib/features/category/presentation/widgets/edit_category_sheet.dart \
  lib/features/business/presentation/widgets/add_business_sheet.dart \
  lib/features/business/presentation/widgets/edit_business_sheet.dart \
  lib/features/business/presentation/widgets/shop/add_shop_sheet.dart \
  lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart \
  lib/features/users/presentation/widgets/add_user_sheet.dart \
  lib/features/users/presentation/widgets/edit_user_sheet.dart
```

Expected: no issues in any file.

- [ ] **Commit**

```bash
git add \
  lib/features/products/presentation/widgets/add_product_sheet.dart \
  lib/features/products/presentation/widgets/edit_product_sheet.dart \
  lib/features/products/presentation/widgets/category_picker.dart \
  lib/features/category/presentation/widgets/add_category_sheet.dart \
  lib/features/category/presentation/widgets/edit_category_sheet.dart \
  lib/features/business/presentation/widgets/add_business_sheet.dart \
  lib/features/business/presentation/widgets/edit_business_sheet.dart \
  lib/features/business/presentation/widgets/shop/add_shop_sheet.dart \
  lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart \
  lib/features/users/presentation/widgets/add_user_sheet.dart \
  lib/features/users/presentation/widgets/edit_user_sheet.dart
git commit -m "feat(responsive): migrate products/category/business/users sheets to showAdaptivePanel"
```

---

## Task 11 — Sheet migration: inventory + customers + returns + settings + common (17 files)

Same migration pattern. For each file: add import, replace `showModalBottomSheet` → `showAdaptivePanel`.

| File | `desktopWidth` |
|---|---|
| `lib/features/inventory/presentation/widgets/inbound_receiving_sheet.dart` | 480 |
| `lib/features/inventory/presentation/widgets/stock_action_sheet.dart` | 480 |
| `lib/features/inventory/presentation/widgets/add_stock_product_sheet.dart` | 480 |
| `lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart` | 480 |
| `lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart` | 480 |
| `lib/features/inventory/presentation/premium/sheets/stock_levels_sheet.dart` | 480 |
| `lib/features/inventory/presentation/premium/sheets/low_stock_sheet.dart` | 480 |
| `lib/features/inventory/presentation/premium/sheets/expiry_report_sheet.dart` | 480 |
| `lib/features/customers/presentation/widgets/customer_form_sheet.dart` | 480 |
| `lib/features/returns/presentation/widgets/return_success_sheet.dart` | 360 |
| `lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart` | 480 |
| `lib/features/notification/presentation/widgets/notification_tile.dart` | 360 |
| `lib/features/settings/presentation/settings_screen.dart` | 480 (all 4 calls) |
| `lib/features/settings/presentation/widgets/bankak_payment_card.dart` | 480 |
| `lib/common/widgets/permission_required_sheet.dart` | 360 |
| `lib/common/widgets/image_upload_box.dart` | 360 |
| `lib/widgets/app_deactivate_bottom_sheet.dart` | 360 |

- [ ] **Apply migration to all 17 files**

- [ ] **Verify all 17 files compile**

```bash
flutter analyze lib/features/inventory/presentation/widgets/ \
  lib/features/inventory/presentation/premium/sheets/ \
  lib/features/customers/presentation/widgets/customer_form_sheet.dart \
  lib/features/returns/presentation/widgets/return_success_sheet.dart \
  lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart \
  lib/features/notification/presentation/widgets/notification_tile.dart \
  lib/features/settings/presentation/settings_screen.dart \
  lib/features/settings/presentation/widgets/bankak_payment_card.dart \
  lib/common/widgets/permission_required_sheet.dart \
  lib/common/widgets/image_upload_box.dart \
  lib/widgets/app_deactivate_bottom_sheet.dart
```

Expected: no issues.

- [ ] **Commit**

```bash
git add \
  lib/features/inventory/presentation/widgets/inbound_receiving_sheet.dart \
  lib/features/inventory/presentation/widgets/stock_action_sheet.dart \
  lib/features/inventory/presentation/widgets/add_stock_product_sheet.dart \
  lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart \
  lib/features/inventory/presentation/premium/sheets/inbound_sheet.dart \
  lib/features/inventory/presentation/premium/sheets/stock_levels_sheet.dart \
  lib/features/inventory/presentation/premium/sheets/low_stock_sheet.dart \
  lib/features/inventory/presentation/premium/sheets/expiry_report_sheet.dart \
  lib/features/customers/presentation/widgets/customer_form_sheet.dart \
  lib/features/returns/presentation/widgets/return_success_sheet.dart \
  lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart \
  lib/features/notification/presentation/widgets/notification_tile.dart \
  lib/features/settings/presentation/settings_screen.dart \
  lib/features/settings/presentation/widgets/bankak_payment_card.dart \
  lib/common/widgets/permission_required_sheet.dart \
  lib/common/widgets/image_upload_box.dart \
  lib/widgets/app_deactivate_bottom_sheet.dart
git commit -m "feat(responsive): migrate inventory/settings/common sheets to showAdaptivePanel"
```

---

## Task 12 — POS screen desktop layout

**Files:**
- Modify: `lib/features/pos/presentation/pos_screen.dart`

On desktop, the product grid and the expanded cart appear side-by-side. The cart column is always visible (no peek/expand flow). `_PosScreenState._handleCheckout` — which already exists in the file — is wired to the desktop cart's checkout button.

- [ ] **Add imports at the top of `pos_screen.dart`**

```dart
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/cart/presentation/expanded_cart.dart';
```

- [ ] **Extract `productPane` and add the desktop branch inside `_PosScreenState.build`**

Inside the outer `BlocBuilder<PosBloc, PosState>` (the one with `buildWhen: prev.cartExpanded != curr.cartExpanded`), extract the existing `Column` into a local `productPane` variable, then branch:

```dart
builder: (context, posState) {
  // ── Shared: product pane (same widget tree mobile + desktop) ──────
  final productPane = Column(
    children: [
      // ── Shift / today card ────────────────────────────────────────
      BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.summary != curr.summary,
        builder: (context, state) {
          // ... existing CashierShiftCard builder — copy as-is ...
        },
      ),
      PosSearchSection(searchCtrl: _searchCtrl),
      const CategoryBar(),
      Expanded(
        child: BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, curr) =>
              prev.productStatus != curr.productStatus ||
              prev.products != curr.products ||
              prev.categories != curr.categories,
          builder: (context, productState) {
            if (productState.productStatus == ProductStatus.loading ||
                productState.productStatus == ProductStatus.initial) {
              return const ProductsLoadingGrid();
            }
            if (productState.productStatus == ProductStatus.failure) {
              return ProductErrorView(message: productState.responseError);
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
                // ── Responsive grid column count ─────────────────
                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cols =
                        ctx.gridColumnsFor(constraints.maxWidth, tile: 176);
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
  );

  // ── Desktop: side-by-side product grid + persistent cart ──────────
  if (context.isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: productPane),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: context.appColors.border,
        ),
        SizedBox(
          width: 392,
          child: ExpandedCart(
            onCollapse: () {}, // no-op — cart is always visible on desktop
            onCheckout: _handleCheckout,
          ),
        ),
      ],
    );
  }

  // ── Mobile: unchanged ─────────────────────────────────────────────
  return RefreshIndicator(
    color: context.appColors.primary,
    notificationPredicate: (_) => !posState.cartExpanded,
    onRefresh: posState.cartExpanded ? () async {} : () async {
      // ... existing refresh logic unchanged ...
    },
    child: Stack(
      children: [
        productPane,
        BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) => prev.isEmpty != curr.isEmpty,
          builder: (context, state) =>
              SizedBox(height: state.isEmpty ? 0 : 88),
        ),
      ],
    ),
  );
},
```

**Note on `ProductGrid`:** Check whether `ProductGrid` already accepts a `crossAxisCount` parameter. If it hardcodes columns internally, add an optional `int? crossAxisCount` parameter to `ProductGrid` and use it (falling back to the existing hardcoded value when null) — this keeps mobile unchanged.

**Note on the bottom spacer:** The original mobile `Column` has a final `BlocBuilder<PosBloc>` child that renders a `SizedBox(height: state.isEmpty ? 0 : 88)` as spacing for the cart peek bar. This spacer belongs in the **mobile-only** `RefreshIndicator > Column` — do NOT include it in `productPane`. `productPane` should contain only the shift card, search, category bar, and product grid.

- [ ] **Verify it compiles**

```bash
flutter analyze lib/features/pos/presentation/pos_screen.dart
```

- [ ] **Run at 1024px+ and verify the persistent cart column appears**

```bash
flutter run -d macos
```

The product grid should show on the left, the expanded cart (with all cart items, payment selector, and checkout button) on the right. Resize below 1024px and verify the original bottom-sheet cart peek behaviour is restored.

- [ ] **Commit**

```bash
git add lib/features/pos/presentation/pos_screen.dart
git commit -m "feat(desktop): add side-by-side product grid + cart column on POS screen"
```

---

## Task 13 — Business/Home screen desktop layout

**Files:**
- Modify: `lib/features/business/presentation/business_screen.dart`

- [ ] **Add imports**

```dart
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
```

- [ ] **Wrap the screen body in a content-width constraint**

Find the screen's top-level return (or the `Scaffold.body` widget). Wrap the main scrollable/content widget with:

```dart
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: context.maxContentWidth),
    child: Padding(
      padding: context.pagePadding,
      child: /* existing content */,
    ),
  ),
)
```

If the existing screen uses `CustomScrollView` or `ListView`, wrap the entire scroll widget (not its children individually) so the scroll itself is width-capped.

- [ ] **Verify it compiles and runs correctly**

```bash
flutter analyze lib/features/business/presentation/business_screen.dart
flutter run -d macos
```

On desktop: Home screen content is centred and width-capped at 1440px with 32px padding. On mobile: identical to before (padding/width constraints are resolved from `pagePadding` / `maxContentWidth` which use the mobile values).

- [ ] **Commit**

```bash
git add lib/features/business/presentation/business_screen.dart
git commit -m "feat(desktop): apply content-width constraint to Home screen"
```

---

## Task 14 — Products screen desktop layout

**Files:**
- Modify: `lib/features/products/presentation/product_screen.dart`

The products grid already uses a `GridView` or similar. On desktop it should use `gridColumnsFor` to fill wider screens.

- [ ] **Add imports**

```dart
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
```

- [ ] **Wrap the product grid in `LayoutBuilder`**

Find where the product grid (`GridView` or similar) is built. Replace the fixed `crossAxisCount` with a dynamic one:

```dart
LayoutBuilder(
  builder: (ctx, constraints) {
    final cols = ctx.gridColumnsFor(constraints.maxWidth, tile: 208);
    return /* existing GridView / SliverGrid */ (
      crossAxisCount: cols,
      // ... rest of grid unchanged ...
    );
  },
)
```

- [ ] **Verify it compiles**

```bash
flutter analyze lib/features/products/presentation/product_screen.dart
```

- [ ] **Run and verify grid columns scale on desktop**

```bash
flutter run -d macos
```

Navigate to the Products screen. At 1024px the grid should show 4+ columns; at 390px it should show 2 columns.

- [ ] **Commit**

```bash
git add lib/features/products/presentation/product_screen.dart
git commit -m "feat(desktop): responsive grid columns on Products screen"
```

---

## Task 15 — Inventory screen desktop layout

**Files:**
- Modify: `lib/features/inventory/presentation/basic_inventory_view.dart` (and `premium_inventory_shell.dart` if it has a KPI card row)

- [ ] **Add imports to the file(s) being modified**

```dart
import 'package:amana_pos/core/responsive/adaptive_flex.dart';
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
```

- [ ] **Wrap any horizontal KPI card rows with `AdaptiveFlex`**

Find where KPI/summary cards are rendered in a `Column` (stacked on mobile). Replace the `Column` wrapper with `AdaptiveFlex`:

```dart
AdaptiveFlex(
  spacing: AppSpacing.md,
  children: [
    KpiCard(/* ... */),
    KpiCard(/* ... */),
    KpiCard(/* ... */),
  ],
)
```

On mobile `AdaptiveFlex` is vertical (unchanged). On desktop it becomes a horizontal `Row`.

- [ ] **Cap content width on the inventory screen**

Wrap the screen's main content with:

```dart
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: context.maxContentWidth),
    child: Padding(
      padding: context.pagePadding,
      child: /* existing content */,
    ),
  ),
)
```

- [ ] **Verify it compiles**

```bash
flutter analyze lib/features/inventory/presentation/basic_inventory_view.dart
```

- [ ] **Commit**

```bash
git add lib/features/inventory/presentation/basic_inventory_view.dart
git commit -m "feat(desktop): AdaptiveFlex KPI row + content-width cap on Inventory"
```

---

## Task 16 — Settings screen desktop layout

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

(The `showModalBottomSheet` → `showAdaptivePanel` migration for this file was already done in Task 11. This task adds the layout adaptation.)

- [ ] **Add imports** (if not already present from Task 11)

```dart
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
```

- [ ] **Cap content width**

Wrap the Settings screen's main `Scaffold.body` content (the scrollable list of sections) with:

```dart
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: context.maxContentWidth),
    child: Padding(
      padding: context.pagePadding,
      child: /* existing settings list */,
    ),
  ),
)
```

- [ ] **Verify it compiles and the settings look correct at 1024px+**

```bash
flutter analyze lib/features/settings/presentation/settings_screen.dart
flutter run -d macos
```

On desktop: settings list is centred, not edge-to-edge. On mobile: unchanged.

- [ ] **Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat(desktop): content-width constraint on Settings screen"
```

---

## Task 17 — RTL audit + final verification

**Files:**
- Read-only audit of all new files created in Tasks 1–16.

- [ ] **Grep for raw `left` / `right` in new desktop code**

```bash
grep -rn "\.left\b\|\.right\b\|EdgeInsets\.only(left\|EdgeInsets\.only(right\|Alignment\.centerLeft\|Alignment\.centerRight" \
  lib/core/responsive/ \
  lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart \
  lib/features/main_screen/presentation/widgets/desktop_shell.dart
```

Expected: only intentional uses — `Alignment.centerRight` and `Alignment.centerLeft` in `adaptive_sheet.dart` are correct (already gated on `Directionality`). Any bare `EdgeInsets.only(left:...)` or `EdgeInsets.only(right:...)` in new files should be replaced with `EdgeInsetsDirectional.only(start:...)` or `EdgeInsetsDirectional.only(end:...)`.

- [ ] **Verify no `showModalBottomSheet` calls remain in the app**

```bash
grep -rn "showModalBottomSheet" lib/ --include="*.dart"
```

Expected: zero results. If any remain, apply the Task 9 migration pattern to those files.

- [ ] **Run full flutter analyze**

```bash
flutter analyze lib/
```

Expected: no errors. Address any warnings in new files.

- [ ] **Run widget tests**

```bash
flutter test test/core/responsive/responsive_test.dart
```

Expected: all pass.

- [ ] **Manual width-breakpoint test**

Run the app on macOS or Chrome. Resize and verify at each width:

| Width | Expected |
|---|---|
| 390px | Mobile bottom nav, center Sell FAB, cart as bottom sheet peek |
| 768px | Mobile layout still (below 1024 desktop threshold) |
| 1024px | Desktop rail appears, mobile bottom nav gone, cart column in POS |
| 1440px | Content width caps, no horizontal overflow |

- [ ] **Commit audit clean-up (if any fixes were needed)**

```bash
git add -u
git commit -m "fix(desktop): RTL audit — replace directional EdgeInsets in new code"
```

---

## Summary

| Wave | Tasks | Outcome |
|---|---|---|
| Infrastructure | 1–5 | Breakpoints, extension, metrics, flex, sheet helper |
| Shell | 6–8 | Desktop rail + shell wired into MainScreen |
| Overlays | 9–11 | All 31 sheet call sites migrated |
| Screens | 12–16 | POS, Home, Products, Inventory, Settings adapted |
| Quality | 17 | RTL, analyzer, manual breakpoint testing |
