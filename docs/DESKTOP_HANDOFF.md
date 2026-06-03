# AmanaPOS — Desktop Support Handoff

A spec for adding **desktop / large-screen** support to the existing Flutter app **without rewriting screens**. The strategy is *adaptive, not separate*: one widget tree that swaps **layout primitives** and **overlay style** based on screen width. Mobile behavior stays exactly as it is today.

Reference mockup: `AmanaPOS Desktop.html` (icon rail + Sell terminal + Home + Products + Inventory + Settings, EN/AR).

---

## 0. Golden rules (read first)

| Rule | Mobile (today) | Desktop (add) | Driver |
|---|---|---|---|
| **R1 — Direction** | `Column` (stacked) | `Row` (side-by-side) | `context.isDesktop` |
| **R2 — Overlays** | `showModalBottomSheet` | side **Drawer / end-panel** (or width-capped dialog) | `context.isDesktop` |
| **R3 — Navigation** | `BottomNav` + center Sell FAB | expandable **`NavigationRail`** at the start side | `context.isDesktop` |
| **R4 — Spacing & density** | base scale (`md = 16`) | larger gutters + max content width | `context.responsive(...)` |
| **R0 — Don't break mobile** | — | every new branch must fall back to the current mobile widget | always |

> Implement R1–R4 as **utilities** (Section 2). Screens then read `context.isDesktop` / `context.responsive(...)` and never hardcode a platform.

---

## 1. Breakpoints

Aligned with Material 3 window size classes. Tune `desktop` if your cart panel feels cramped.

```dart
// lib/core/responsive/breakpoints.dart
abstract final class Breakpoints {
  Breakpoints._();
  static const double tablet  = 600;   // compact  -> medium
  static const double desktop = 1024;  // medium   -> expanded  (POS cart needs the room)
  static const double large   = 1440;  // cap content width above this
}

enum DeviceClass { mobile, tablet, desktop }
```

---

## 2. The responsive utility (the thing you asked for)

```dart
// lib/core/responsive/responsive.dart
import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

extension ResponsiveContext on BuildContext {
  Size   get _size  => MediaQuery.sizeOf(this);
  double get width  => _size.width;

  DeviceClass get deviceClass {
    final w = width;
    if (w >= Breakpoints.desktop) return DeviceClass.desktop;
    if (w >= Breakpoints.tablet)  return DeviceClass.tablet;
    return DeviceClass.mobile;
  }

  bool get isMobile  => deviceClass == DeviceClass.mobile;
  bool get isTablet  => deviceClass == DeviceClass.tablet;
  bool get isDesktop => deviceClass == DeviceClass.desktop;
  bool get isWide    => width >= Breakpoints.tablet; // tablet OR desktop

  /// Pick a value per device class. `tablet` falls back to `desktop`.
  T responsive<T>({required T mobile, T? tablet, required T desktop}) =>
      switch (deviceClass) {
        DeviceClass.desktop => desktop,
        DeviceClass.tablet  => tablet ?? desktop,
        DeviceClass.mobile  => mobile,
      };
}
```

**Why an extension and not a global?** It rebuilds correctly on resize/rotation (it reads `MediaQuery`), works in split-screen, and is testable.

### R1 — Row vs Column helper

Use the extension inline, or this thin wrapper for the common "stack on mobile, beside on desktop" case:

```dart
// lib/core/responsive/adaptive_flex.dart
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
    final row = context.isDesktop && desktopIsRow;
    return Flex(
      direction: row ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: crossAxis,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0) SizedBox(width: row ? spacing : 0, height: row ? 0 : spacing),
          children[i],
        ],
      ],
    );
  }
}
```

> For "main content + sticky side panel" (Sell, Products detail), prefer an explicit `Row` with `Expanded(child: content)` + a fixed-width panel — see Section 5.

### R2 — Adaptive overlay (bottom sheet ⇄ side drawer)

One call site, two presentations. On desktop it slides in from the **end** side (respects RTL); on mobile it's the current modal bottom sheet.

```dart
// lib/core/responsive/adaptive_sheet.dart
Future<T?> showAdaptivePanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double desktopWidth = 480,          // New Product = 480, Cart review = 392
  bool isScrollControlled = true,
}) {
  if (context.isDesktop) {
    // End-anchored drawer/panel. Slides from right (LTR) / left (RTL).
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'panel',
      barrierColor: Colors.black.withOpacity(0.45),
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
      transitionBuilder: (ctx, anim, __, child) {
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

**Replace these existing call sites** with `showAdaptivePanel`:
- New Product form
- Cart "Review sale" sheet (mobile) → on desktop it becomes the **always-visible** cart column, so only call the panel on mobile (see Section 5).
- Category picker, payment confirmation, filters.

---

## 3. Navigation shell (R3)

```dart
// lib/core/shell/app_shell.dart
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.index, required this.onSelect, required this.child});
  final int index;
  final ValueChanged<int> onSelect;
  final Widget child;

  static const _items = [
    (icon: Icons.storefront_outlined, sel: Icons.storefront, label: 'Home'),
    (icon: Icons.shopping_cart_outlined, sel: Icons.shopping_cart, label: 'Sell'),
    (icon: Icons.shopping_bag_outlined, sel: Icons.shopping_bag, label: 'Products'),
    (icon: Icons.inventory_2_outlined, sel: Icons.inventory_2, label: 'Inventory'),
    (icon: Icons.grid_view_outlined, sel: Icons.grid_view, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    // ---------- DESKTOP: expandable rail (R3) ----------
    if (context.isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _PosNavigationRail(index: index, onSelect: onSelect, items: _items),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  const PosTopBar(),        // branch chip + search + SYNCED badge
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ---------- MOBILE: keep today's bottom nav + center Sell FAB ----------
    return Scaffold(
      body: child,
      floatingActionButton: SellFab(onTap: () => onSelect(1)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const PosBottomNav(), // unchanged
    );
  }
}
```

`_PosNavigationRail` = `NavigationRail` with an **extended** toggle so it expands from a 76px icon rail to a ~248px labelled rail (the brandmark/hamburger toggles it). Mirror the mockup:

```dart
class _PosNavigationRail extends StatefulWidget { /* ... */ }
class _PosNavigationRailState extends State<_PosNavigationRail> {
  bool _extended = false;
  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: _extended,
      minWidth: 76,
      minExtendedWidth: 248,
      backgroundColor: Theme.of(context).colorScheme.surface,
      groupAlignment: -1,
      selectedIndex: widget.index,
      onDestinationSelected: widget.onSelect,
      leading: Column(children: [
        BrandMark(onTap: () => setState(() => _extended = !_extended)), // toggle
        const SizedBox(height: AppSpacing.md),
      ]),
      trailing: const Expanded(child: Align(
        alignment: Alignment.bottomCenter, child: RailUserChip())),
      destinations: [
        for (final it in widget.items)
          NavigationRailDestination(
            icon: Icon(it.icon), selectedIcon: Icon(it.sel), label: Text(it.label)),
      ],
    );
  }
}
```

- Selected destination: `AppColors.primaryLight` pill + `AppColors.primaryDark` icon (matches mockup).
- **Sell** is the visually dominant action — render its rail item as a filled `AppColors.primary` button, or keep it as the FAB equivalent at the top of the rail.
- Drive everything off **one** `selectedIndex` so mobile bottom-nav and desktop rail share state (put it in your router / a `NavigationCubit`).

---

## 4. Spacing, density & content width (R4)

Reuse your existing tokens (`AppSpacing`, `AppRadius`, `AppDims`) — just scale a few **layout** values by device class. Don't invent new numbers.

```dart
// lib/core/responsive/layout_metrics.dart
extension LayoutMetrics on BuildContext {
  EdgeInsets get pagePadding => responsive(
        mobile:  const EdgeInsets.all(AppSpacing.md),    // 16
        tablet:  const EdgeInsets.all(AppSpacing.xl),    // 24
        desktop: const EdgeInsets.all(AppSpacing.xxl),   // 32
      );

  double get sectionGap => responsive(mobile: AppSpacing.lg, desktop: AppSpacing.xxl);

  /// Cap reading width on huge monitors; center the body.
  double get maxContentWidth => Breakpoints.large; // 1440

  /// Product-grid columns by available width (use inside LayoutBuilder).
  int gridColumnsFor(double maxWidth, {double tile = 180}) =>
      (maxWidth / tile).floor().clamp(2, 8);
}
```

Wrap top-level pages (Home, Settings, Products) so content doesn't stretch edge-to-edge on wide monitors:

```dart
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: context.maxContentWidth),
    child: Padding(padding: context.pagePadding, child: page),
  ),
)
```

Key fixed sizes from the mockup (desktop):
- Icon rail: **76px** collapsed / **248px** extended.
- Top bar height: **68px** (mobile keeps `AppDims.appBarHeight = 56`).
- Cart panel width: **392px**; New Product panel: **480px**.
- Sell product tile: target ~**168–180px** min; Catalog tile ~**208px** min — use `gridColumnsFor`.
- Hit targets: keep ≥ **44px** everywhere (touchscreen counters are common).

---

## 5. Sell terminal — the flagship (R1 + R2 together)

This is where the adaptive payoff is biggest. Same widgets, different assembly.

```dart
@override
Widget build(BuildContext context) {
  final productPane = Column(children: [
    const SellStatBar(),       // today sales / shift / sparkline
    const SellSearchRow(),     // scan button + search field
    const CategoryChips(),
    Expanded(
      child: LayoutBuilder(builder: (ctx, c) {
        final cols = ctx.gridColumnsFor(c.maxWidth, tile: 176);
        return ProductGrid(crossAxisCount: cols);
      }),
    ),
  ]);

  // DESKTOP: product grid + ALWAYS-VISIBLE cart column (Row)  -> R1
  if (context.isDesktop) {
    return Row(children: [
      Expanded(child: productPane),
      const VerticalDivider(width: 1),
      const SizedBox(width: 392, child: CartPanel()), // persistent, no sheet
    ]);
  }

  // MOBILE: grid full-width; cart lives in the bottom sheet           -> R2
  return Stack(children: [
    productPane,
    Positioned(
      left: 0, right: 0, bottom: 0,
      child: CartPeekBar(                       // your existing "Review" peek
        onTap: () => showAdaptivePanel(context, // becomes bottom sheet on mobile
          desktopWidth: 392,
          builder: (_) => const CartPanel()),
      ),
    ),
  ]);
}
```

`CartPanel` is **one widget** used in both places: line items + qty steppers, payment method (Cash / Bankak), Subtotal/Total, and a full-width **Complete sale** button pinned to the bottom. No duplication.

---

## 6. Per-screen mapping

| Screen | Mobile (keep) | Desktop (add) | Rules |
|---|---|---|---|
| **Home** | scroll: hero → MANAGE grid (2-col) → plan | center, `maxContentWidth`; MANAGE stays 2-col or 4-up; plan full-width | R4 |
| **Sell** | grid + cart bottom sheet | grid (`Expanded`) + 392px cart column | R1, R2 |
| **Products** | card grid; New Product = bottom sheet | wider grid (`gridColumnsFor`); New Product = 480px end-panel | R1, R2, R4 |
| **Inventory** | stacked cards; dark hero | dark hero + 3-up KPIs + 2-col card grid (Health ring, Inbound, Restock, Vendors) | R1, R4 |
| **More / Settings** | stacked list sections | center, `maxContentWidth`; sectioned cards; appearance = 3-up | R4 |
| **New Product / Review / pickers** | `showModalBottomSheet` | `showAdaptivePanel` end-drawer | R2 |

---

## 7. Desktop window chrome (optional but nice)

The mockup shows a macOS-style title bar. For real desktop builds:
- Add a custom frame with **`bitsdojo_window`** or **`window_manager`** (traffic-light buttons / min-max-close, draggable title bar).
- Set a sane **minimum window size** so the cart column always fits: `windowManager.setMinimumSize(const Size(1024, 680));`
- Keep the title bar height ~44px; put the branch name centered, window controls at the start side.
- This is cosmetic — skip it for web/tablet targets; the rail + top bar already work without it.

---

## 8. RTL / Arabic

You already mix English UI + Arabic content. For desktop:
- Use **logical** directions everywhere: `EdgeInsetsDirectional`, `start`/`end`, `MainAxisAlignment.start`. The rail, panels and dividers then flip automatically under `Directionality(textDirection: rtl)`.
- `showAdaptivePanel` above already slides from the correct side in RTL.
- Don't hardcode `left`/`right` in new desktop code.

---

## 9. Implementation order (checklist for the agent)

1. [ ] Add `breakpoints.dart`, `responsive.dart` (extension), `layout_metrics.dart`.
2. [ ] Add `adaptive_flex.dart` and `adaptive_sheet.dart` (`showAdaptivePanel`).
3. [ ] Build `AppShell` with `NavigationRail` (desktop) / existing bottom nav (mobile); share `selectedIndex`.
4. [ ] Wrap top-level pages in `Center > ConstrainedBox(maxContentWidth) > Padding(pagePadding)`.
5. [ ] Refactor **Sell** into `productPane` + `CartPanel`; Row on desktop, sheet on mobile.
6. [ ] Swap every `showModalBottomSheet` → `showAdaptivePanel`.
7. [ ] Convert product grids to `LayoutBuilder` + `gridColumnsFor`.
8. [ ] Audit `left/right` → `start/end`; verify RTL.
9. [ ] (Optional) Add desktop window chrome + min window size.
10. [ ] Test at widths **390 / 768 / 1024 / 1440** — mobile must be byte-for-byte unchanged below 600.

### Guardrails (don't break the code)
- **Never** delete a mobile branch — only add an `if (context.isDesktop)` branch that returns *before* it.
- Keep using the **existing** `AppColors / AppSpacing / AppRadius / AppDims` tokens; do not introduce new color or spacing constants.
- One source of truth for nav index, cart state, selected branch — desktop and mobile read the same state.
- Reuse leaf widgets (`CartPanel`, `ProductCard`, form fields) across layouts; only the **assembly** (Row/Column/overlay) is adaptive.
