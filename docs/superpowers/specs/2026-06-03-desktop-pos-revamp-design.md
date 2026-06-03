# Desktop POS Revamp — Design Spec

**Date:** 2026-06-03
**Scope:** Desktop-only UI/UX improvements to the POS screen. Mobile is not touched.

---

## Problem

The current desktop POS (`PosScreen` desktop branch) looks like a mobile app displayed on a big screen:
- Cart panel uses a top-rounded sheet shape (`BorderRadius.vertical(top: Radius.circular(34))`) — a mobile bottom-sheet pattern
- Cart header has a drag-handle pill and a collapse button — both mobile-only affordances
- `CategoryBar` is a horizontal scroll strip — mobile pattern, wastes vertical space on desktop
- `CashierShiftCard` sits above the search bar, taking vertical space away from products
- Product grid uses wide tile spacing (176px tile target) — results in only 2–3 columns on desktop

---

## Goals

1. Make the desktop POS feel like a native desktop application
2. Show more products at once (4–5 columns)
3. Use the full vertical height of the screen
4. Keep the mobile experience 100% unchanged

---

## Non-Goals

- Changing any mobile UI
- Redesigning the checkout flow, receipt sheet, or payment selector
- Changing BLoC state management or data layer
- Modifying `PosProductCard`, `ExpandedCart`, `CategoryBar`, or `CashierShiftCard` widgets directly

---

## Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  DesktopShell TopBar  (unchanged)                                │
├──────────────────────────────────────────────────────────────────┤
│  Nav Rail  │  Category Sidebar  │  Search Toolbar               │
│  (56px)    │  (160px)           ├───────────────────────────────┤
│            │  [Stats compact]   │  Product Grid (4–5 cols)      │
│            │  ───────────────   │                               │
│            │  All Items ●       │                               │
│            │  Beverages         │                               │
│            │  Food              │                               │
│            │  Snacks            │                               │
│            │  Electronics       │                               │
│            │  …                 │                               │
│            │                    │                               │
│            │                    │──────────────────────────────┤│
│            │                    │   [Cart Panel — 380px]        │
│            │                    │   Flat header, no pill        │
│            │                    │   Items list                  │
│            │                    │   Payment selector            │
│            │                    │   Totals + Checkout btn       │
└────────────┴────────────────────┴──────────────────────────────┘
```

### Column widths
| Column | Width | Notes |
|---|---|---|
| Nav Rail | 56px (collapsed) / 248px (expanded) | Existing `DesktopNavigationRail`, unchanged |
| Category Sidebar | 160px fixed | New desktop-only widget |
| Product Grid | Remaining flex space | 4–5 columns at typical desktop widths |
| Cart Panel | 380px fixed | Replaces current 392px with desktop chrome |

---

## Components

### 1. `DesktopCategorySidebar` (new widget)

**File:** `lib/features/pos/presentation/widgets/desktop_category_sidebar.dart`

- Replaces `CategoryBar` in the desktop POS layout only
- Fixed width `160px`, background `colors.surface`, right border `colors.border`
- Header: uppercase label "CATEGORIES" in `colors.textHint`, `AppTextStyles.sm100`
- Items: `ListView` of tappable rows
  - Layout: 6px dot indicator + category name text
  - Active state: 2px `colors.primary` left border + `colors.primary.withOpacity(0.08)` background + `colors.primary` text
  - Inactive state: `colors.textSecondary` text, no border/background tint
- "All Items" as first item, maps to `selectedCategoryId == null`
- Scrollable via `ListView` with `BouncingScrollPhysics`
- Dispatches `PosCategoryChanged` on tap (same as `CategoryBar`)

**Compact stats block** (above category list, separated by divider):
- Shows: cashier/owner name + shift sales amount + sales count
- Data source: same `DashboardSummaryBloc` + `AuthBloc` as `CashierShiftCard`
- No sparkline on desktop (too narrow)
- Layout: 2 rows — name row + amount + count row
- Only shown on desktop (widget lives in desktop-only file)

### 2. `DesktopCartPanel` (new widget)

**File:** `lib/features/cart/presentation/desktop_cart_panel.dart`

Wraps the existing cart content (items list, payment selector, totals, checkout button) with desktop-appropriate chrome. **Does not modify `ExpandedCart`.**

Desktop cart header:
- Row: "Order" title (left, `AppTextStyles.bs500`, `fontWeight: w900`) + item-count badge + clear button (right)
- Flat top edge — `DecoratedBox` with no border radius (or `BorderRadius.zero`)
- Background `colors.surface`
- Height `56px`
- No drag-handle pill
- No collapse button

Cart body: reuses existing `CartLine`, `PaymentSelector`, `TotalsSection`, `PaymentButton` widgets unchanged.

Receipt listener: same `BlocListener<PosBloc>` as `ExpandedCart` — shows `SaleReceiptSheet` on success.

### 3. `PosScreen` desktop branch (modified)

**File:** `lib/features/pos/presentation/pos_screen.dart`

The `if (context.isDesktop)` branch is rewritten. Current code:

```dart
// Desktop: persistent side-by-side layout
if (context.isDesktop) {
  return Row(
    children: [
      Expanded(child: productPane),
      VerticalDivider(...),
      SizedBox(width: 392, child: ExpandedCart(...)),
    ],
  );
}
```

New code structure (PosScreen renders inside DesktopShell's Expanded area, so no nav rail here):

```dart
if (context.isDesktop) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Category sidebar (160px) — includes compact stats at top
      DesktopCategorySidebar(),
      VerticalDivider(width: 1, thickness: 1, color: colors.border),
      // Product column: search toolbar + grid
      Expanded(
        child: Column(
          children: [
            _DesktopSearchToolbar(searchCtrl: _searchCtrl),
            Divider(height: 1, thickness: 1, color: colors.border),
            Expanded(child: _desktopProductGrid()),
          ],
        ),
      ),
      VerticalDivider(width: 1, thickness: 1, color: colors.border),
      // Cart panel (380px)
      SizedBox(
        width: 380,
        child: DesktopCartPanel(onCheckout: _handleCheckout),
      ),
    ],
  );
}
```

The `productPane` variable (which includes `CashierShiftCard`, `PosSearchSection`, `CategoryBar`, and the product grid) is used only by the **mobile** branch. The desktop branch builds its own layout from parts.

### 4. `_DesktopSearchToolbar` (private widget in `pos_screen.dart`)

- Height `44px`, background `colors.surface`, bottom border divider
- Contains `PosSearchSection` widget (same widget, same controller)
- Spans only the product grid column (not sidebar or cart)

### 5. Product grid column count (modified call site)

In the desktop product grid, change:
```dart
final cols = ctx.gridColumnsFor(constraints.maxWidth, tile: 176);
```
to:
```dart
final cols = ctx.gridColumnsFor(constraints.maxWidth, tile: 140);
```

This yields 4–5 columns on desktop at 700–900px center column width. Mobile is unaffected because it uses the mobile `productPane` branch which keeps `tile: 176`.

---

## Mobile Safety Checklist

| Widget | Mobile usage | Desktop change | Risk |
|---|---|---|---|
| `PosProductCard` | Grid items | None | None |
| `CategoryBar` | Horizontal scroll strip | Not called on desktop | None |
| `ExpandedCart` | Mobile cart sheet | Not called on desktop | None |
| `CashierShiftCard` | Above search, mobile | Not called on desktop | None |
| `PosSearchSection` | Mobile product pane | Repositioned on desktop only | None |
| `ProductGrid` | Mobile 2-col grid | Tile size arg changes in desktop call | None |
| `DesktopShell` | Desktop shell | Not touched | None |
| `DesktopTopBar` | Desktop top bar | Not touched | None |
| `DesktopNavigationRail` | Desktop nav rail | Not touched | None |

---

## Files Changed

| File | Change |
|---|---|
| `lib/features/pos/presentation/pos_screen.dart` | Rewrite desktop branch |
| `lib/features/pos/presentation/widgets/desktop_category_sidebar.dart` | **New** |
| `lib/features/cart/presentation/desktop_cart_panel.dart` | **New** |

All other files: **unchanged.**
