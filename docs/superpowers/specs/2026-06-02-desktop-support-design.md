# Desktop Support Design — AmanaPOS

**Date:** 2026-06-02
**Reference:** `docs/DESKTOP_HANDOFF.md`
**Approach:** Shell-first, adaptive layout — one widget tree that switches layout primitives based on screen width. Mobile behavior is unchanged below 600px.

---

## Decisions

| Question | Decision |
|---|---|
| Target platforms | macOS native, Windows native, web (Flutter multi-platform) |
| Sell rail treatment | Round FAB pinned to bottom of `NavigationRail` (mirrors mobile center-FAB metaphor) |
| Window chrome | Skipped — use OS-default window frame; no `window_manager` dependency |
| Implementation order | Shell-first (utilities → shell → overlays → per-screen) |

---

## Breakpoints

```
mobile  < 600px   (DeviceClass.mobile)
tablet  600–1023px (DeviceClass.tablet)
desktop ≥ 1024px  (DeviceClass.desktop)
large   ≥ 1440px  (content width cap only)
```

---

## Section 1 — Responsive Infrastructure

Five new files in `lib/core/responsive/`. No changes to existing files.

### `breakpoints.dart`
Abstract class with three `double` constants (`tablet=600`, `desktop=1024`, `large=1440`) and a `DeviceClass` enum (`mobile`, `tablet`, `desktop`).

### `responsive.dart`
`BuildContext` extension `ResponsiveContext`. Reads `MediaQuery.sizeOf(context)` — rebuilds correctly on resize and split-screen.

Exposes:
- `deviceClass` → `DeviceClass`
- `isMobile`, `isTablet`, `isDesktop`, `isWide` (≥ tablet)
- `responsive<T>({required T mobile, T? tablet, required T desktop})` — `tablet` falls back to `desktop` if omitted

The existing `lib/utilities/responsive_size.dart` (`ResponsiveSize`) handles font/size scaling and is **not changed**.

### `layout_metrics.dart`
Second `BuildContext` extension. Provides layout values that scale by device class:

| Property | Mobile | Tablet | Desktop |
|---|---|---|---|
| `pagePadding` | `EdgeInsets.all(16)` | `EdgeInsets.all(24)` | `EdgeInsets.all(32)` |
| `sectionGap` | `AppSpacing.lg` (20) | — | `AppSpacing.xxl` (32) |
| `maxContentWidth` | — | — | 1440 |

`gridColumnsFor(double maxWidth, {double tile = 180})` — `(maxWidth / tile).floor().clamp(2, 8)`. Used inside `LayoutBuilder` for product grids.

### `adaptive_sheet.dart`
Top-level function `showAdaptivePanel<T>(BuildContext, {required WidgetBuilder builder, double desktopWidth = 480, bool isScrollControlled = true})`.

- **Mobile:** delegates to `showModalBottomSheet` with existing `AppBottomSheet` styling (rounded top corners, drag handle, surface colour).
- **Desktop:** `showGeneralDialog` end-panel that slides in from the trailing side. RTL-aware — reads `Directionality.of(context)` and slides from `start` in RTL. `barrierDismissible: true`, 45% dark scrim, `easeOutCubic` slide animation (`AppDims.medium` = 320ms).

Panel widths by call site:
- Cart review / payment confirm → 392px
- New Product / edit product → 480px
- Pickers (category, theme, language, filters) → 360px
- Permission / deactivate / info sheets → 360px

### `adaptive_flex.dart`
`AdaptiveFlex` stateless widget — wraps `Flex` and flips direction based on `context.isDesktop`. Parameters: `children`, `desktopIsRow` (default `true`), `spacing`, `crossAxis`. Used for sections that simply need to flip from stacked to side-by-side.

---

## Section 2 — Navigation Shell

### `MainScreen` changes
Single `if (context.isDesktop)` branch at the top of `build`. Mobile returns the exact existing `Scaffold` (appBar + body + bottomNavigationBar) with zero changes.

Desktop returns `DesktopShell`.

### `DesktopShell` (`lib/features/main_screen/presentation/widgets/desktop_shell.dart`)

```
Scaffold
└── body: Row
      ├── DesktopNavigationRail   (76px collapsed / 248px extended)
      ├── VerticalDivider (width: 1)
      └── Expanded
            └── Column
                  ├── PosAppBar (existing widget, reused unchanged)
                  └── Expanded → currentScreen (from NavigationBloc)
```

`Scaffold.bottomNavigationBar` is null on desktop. `MainBottomArea` (cart peek + bottom nav) is not rendered.

The cart column lives inside `PosScreen` itself (see Section 4) — `DesktopShell` has no knowledge of cart state. This keeps the shell a pure layout container.

### `DesktopNavigationRail` (`lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`)

Wraps Flutter's `NavigationRail`:
- `extended` toggled by tapping the brand logo in `leading`
- `minWidth: 76`, `minExtendedWidth: 248`
- `groupAlignment: -1.0` (top-aligned destinations)
- Destinations derived from `BottomNav.buildTabs(context, permissions)` — same permission logic, one source of truth
- **Sell/POS destination:** rendered as a round filled-circle FAB via `trailing` — it is **not** a `NavigationRailDestination`, so it does not affect `selectedIndex`. Pinned to the bottom of the rail column with `Expanded > Align(alignment: Alignment.bottomCenter)`. Active state derived by reading `NavigationBloc.state.currentFeature == AppFeature.pos` directly. Tapping fires `NavigationBloc.add(NavigationFeatureSelected(AppFeature.pos))`
- `selectedIndex` covers only the non-Sell destinations (Home, Products, Inventory, More); `onDestinationSelected` maps back to the corresponding `AppFeature` via the same `tabs` list used by `BottomNav`

### `CartSideColumn` (`lib/features/main_screen/presentation/widgets/cart_side_column.dart`)

- Fixed width 392px, full height
- Shows `CartPanel` (existing widget, reused) when `AppFeature.pos` is active
- Animates to zero width (`AnimatedContainer`, `AppDims.medium`) when switching away from POS — avoids layout jump
- `VerticalDivider` between content and cart column

---

## Section 3 — Adaptive Overlays

### Call-site migration (~18 sites)

Every `showModalBottomSheet` call is replaced with `showAdaptivePanel`. Content builders are unchanged. The `AppBottomSheet` wrapper already used in most sites is preserved.

Files containing call sites (confirmed by grep):
- `lib/features/cart/presentation/cart_panel.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/products/presentation/product_screen.dart` (New Product form)
- `lib/features/products/presentation/product_detail_screen.dart`
- `lib/features/business/presentation/widgets/add_business_sheet.dart`
- `lib/features/business/presentation/widgets/edit_business_sheet.dart`
- `lib/features/business/presentation/widgets/shop/add_shop_sheet.dart`
- `lib/features/business/presentation/widgets/shop/edit_shop_sheet.dart`
- `lib/features/inventory/presentation/widgets/stock_action_sheet.dart`
- `lib/features/inventory/presentation/widgets/add_stock_product_sheet.dart`
- `lib/features/inventory/presentation/widgets/inbound_receiving_sheet.dart`
- `lib/features/customers/presentation/widgets/customer_form_sheet.dart`
- `lib/features/returns/presentation/widgets/return_success_sheet.dart`
- `lib/widgets/app_deactivate_bottom_sheet.dart`
- `lib/common/widgets/permission_required_sheet.dart`
- `lib/common/widgets/image_upload_box.dart`
- `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`
- `lib/features/main_screen/presentation/widgets/location_chip.dart`

---

## Section 4 — Per-Screen Layout Adaptations

Each screen adds an `if (context.isDesktop)` branch. No existing mobile widget tree is modified.

### Home / Dashboard
- Wrap page in `Center > ConstrainedBox(maxWidth: context.maxContentWidth) > Padding(context.pagePadding)`
- MANAGE feature grid: `gridColumnsFor` with `tile=200` → 2-col on mobile, 4-col on desktop

### Sell / POS (`pos_screen.dart`)
Major refactor within the screen (shell is unchanged):

```dart
final productPane = Column([
  CashierShiftCard,
  PosSearchSection,
  CategoryBar,
  Expanded(LayoutBuilder → ProductGrid(crossAxisCount: gridColumnsFor)),
]);

if (context.isDesktop) {
  return Row([Expanded(productPane), VerticalDivider, SizedBox(392, CartPanel)]);
}
// mobile: existing Stack + CartPeekBar
```

`CartPanel` is used in both places — no duplication. The cart peek / bottom-sheet flow on mobile is unchanged.

### Products (`product_screen.dart`)
- Grid: `LayoutBuilder + gridColumnsFor(tile: 208)`
- New Product button → `showAdaptivePanel(desktopWidth: 480, builder: ...)`

### Inventory (`inventory_screen.dart`)
- KPI cards row: `AdaptiveFlex` (stacked → 3-up)
- Content width capped with `maxContentWidth`

### Settings (`settings_screen.dart`)
- Center + `maxContentWidth`
- Appearance section: `AdaptiveFlex` for the 3-up layout on desktop

---

## RTL Guarantee

All new desktop layout code uses:
- `EdgeInsetsDirectional` instead of `EdgeInsets`
- `start` / `end` instead of `left` / `right`
- `PositionedDirectional` in any `Stack`
- `showAdaptivePanel` already slides from the correct side via `Directionality`

---

## Guardrails

- **Never delete a mobile branch** — every desktop path is additive (`if (context.isDesktop)` returns early before mobile code)
- **No new design tokens** — reuse `AppColors`, `AppSpacing`, `AppRadius`, `AppDims` exclusively
- **One nav state** — `NavigationBloc` is the sole source of truth for the active feature on both mobile and desktop
- **One cart state** — `PosBloc` owns the cart; `CartPanel` is rendered in both desktop column and mobile sheet from the same widget
- **Test widths** — 390 / 768 / 1024 / 1440; mobile must be byte-for-byte unchanged below 600px

---

## Files Created (new)

```
lib/core/responsive/
  breakpoints.dart
  responsive.dart
  layout_metrics.dart
  adaptive_sheet.dart
  adaptive_flex.dart

lib/features/main_screen/presentation/widgets/
  desktop_shell.dart
  desktop_navigation_rail.dart
```

## Files Modified (existing)

```
lib/features/main_screen/presentation/main_screen.dart        (isDesktop branch)
lib/features/pos/presentation/pos_screen.dart                 (productPane + Row/Stack branch)
lib/features/dashboard/presentation/...                       (pagePadding + grid cols)
lib/features/products/presentation/product_screen.dart        (grid cols + adaptive sheet)
lib/features/products/presentation/product_detail_screen.dart (adaptive sheet)
lib/features/inventory/presentation/inventory_screen.dart     (AdaptiveFlex + pagePadding)
lib/features/settings/presentation/settings_screen.dart       (maxContentWidth + adaptive sheet)
lib/features/business/presentation/widgets/...                (~4 sheet call sites)
lib/features/inventory/presentation/widgets/...               (~3 sheet call sites)
lib/features/customers/presentation/widgets/...               (1 sheet call site)
lib/features/returns/presentation/widgets/...                 (1 sheet call site)
lib/widgets/app_deactivate_bottom_sheet.dart                  (1 sheet call site)
lib/common/widgets/...                                        (~2 sheet call sites)
lib/features/pos/presentation/widgets/sale_receipt_sheet.dart (1 sheet call site)
lib/features/main_screen/presentation/widgets/location_chip.dart (1 sheet call site)
```
