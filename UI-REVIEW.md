---
status: findings
files_reviewed: 145
findings:
  critical: 0
  warning: 18
  info: 9
  total: 27
---

# UI Consistency Review

## Design System Inventory

### What Exists (Shared Widgets)

| Widget | Location | Description | Actually Used? |
|---|---|---|---|
| `AppButton` | `lib/widgets/app_button.dart` | Primary button with 4 variants (primary, secondary, outline, ghost) and 3 sizes | Rarely — most features use raw `FilledButton` / `ElevatedButton` instead |
| `AppDeactivateBottomSheet` | `lib/widgets/app_deactivate_bottom_sheet.dart` | Confirmation sheet with danger icon, title, description, cancel + confirm row | Partially — used by business and users; NOT used by category, product, or customer delete |
| `BackButton` | `lib/widgets/back_button.dart` | Pill-shaped back button with `DirectionalIcon` | Not observed in any feature app bar; detail app bars inline their own `IconButton` |
| `AppFormField` | `lib/widgets/form_field.dart` | Shared `TextFormField` with prefix icon, border states, error style | Used in settings and business sheets; NOT used by customer, users, returns features |
| `FieldLabel` | `lib/widgets/field_label.dart` | Label row with optional asterisk for required fields | Used in settings, business, category sheets; NOT seen in customer or user sheets |
| `Shimmer` | `lib/widgets/shimmer.dart` | Static coloured box as a shimmer placeholder (no animation) | Used only in `InventoryLoadingView`; all other skeleton files define their own `_Shimmer` private class |
| `WorkspaceSectionHeader` | `lib/widgets/workspace_section_header.dart` | Title + fading line rule | Used in settings (`SettingSectionHeader` wraps it); NOT used by feature_menu `SectionLabel` |
| `OptionalDivider` | `lib/widgets/optional_divider.dart` | "OPTIONAL" divider row | Usage not observed in reviewed files |
| `DirectionalIcon` | `lib/widgets/directional_icon.dart` | RTL-aware icon wrapper | Consistently used |
| `BrandLogo` / `AmanaLogo` | `lib/widgets/` | Logo widgets | Used in relevant screens |
| `PhoneNumberField` | `lib/widgets/phone_number_field.dart` | Phone input field | Not observed reused — customer, user, business sheets use `AppFormField` directly |
| `PageDots` | `lib/widgets/page_dots.dart` | Onboarding dots | Feature-specific |
| `AppBottomSheet` | `lib/features/settings/presentation/widgets/app_bottom_sheet.dart` | Sheet scaffold with handle, icon header, title/subtitle, close button, scrollable child | Used only inside the **settings** feature |
| `ProductSheetShell` | `lib/features/products/presentation/widgets/product_sheet_shell.dart` | Sheet scaffold with handle, title, close button | Used only inside the **products** feature |
| `PrimarySheetButton` | `lib/features/settings/presentation/widgets/primary_sheet_button.dart` | Full-width `FilledButton` with loading spinner | Used only inside the **settings** feature |

### Shared Theme

`AppColors`, `AppSpacing`/`AppRadius`/`AppPadding`/`AppGap`/`AppDims`, `AppTextStyles`, `AppThemeColors` are all well-structured. `AppThemeColors` is accessed consistently via `context.appColors`. `AppDims` duplicates the scale already in `AppSpacing`/`AppRadius` — both systems exist in parallel without clear guidance on which to prefer (`AppDims.rMd` vs `AppRadius.md`).

---

## Findings by Category

---

### UI-01 [Warning]: Six Delete/Confirm Sheets Reimplemented Instead of Using AppDeactivateBottomSheet

**Severity:** Warning
**Category:** Delete Dialogs

**Files affected:**
- `lib/features/category/presentation/widgets/delete_category_sheet.dart`
- `lib/features/products/presentation/widgets/delete_product_sheet.dart`
- `lib/features/customers/presentation/widgets/delete_customer_sheet.dart`
- `lib/features/settings/presentation/widgets/settings_logout_dialog.dart`
- `lib/widgets/app_deactivate_bottom_sheet.dart` (exists but underused)
- `lib/features/business/presentation/widgets/deactivate_business_sheet.dart` (correct)
- `lib/features/users/presentation/widgets/deactivate_user_sheet.dart` (correct)

**What's duplicated:**
Every delete / deactivate confirmation flow needs the same skeleton: a drag handle, a circular danger icon badge, a title, a description paragraph, a cancel `OutlinedButton`, and a red `FilledButton` with loading state. The business and user sheets correctly delegate to `AppDeactivateBottomSheet`. The category, product, and customer sheets each rebuild this entire scaffold from scratch — private `_SheetHandle`, `_DangerIcon`, and `_DeleteActions` classes with pixel-identical structure. `SettingsLogoutDialog` also reimplements the same two-button confirmation pattern, just inside a `Dialog` widget instead of a bottom sheet, yet the icon badge, spacing, and button pair are structurally the same.

`delete_category_sheet.dart` also skips `MediaQuery.viewInsetsOf` keyboard inset adjustment that `delete_product_sheet.dart` includes, causing inconsistent keyboard-avoidance behavior across the same conceptual pattern.

**Suggested refactor:**
`AppDeactivateBottomSheet` already has all required parameters (`icon`, `confirmColor`, `cancelText`, `confirmText`, `isLoading`, `onConfirm`). Route `showDeleteCategorySheet`, `showDeleteProductSheet`, and `showDeleteCustomerSheet` through it exactly the same way `deactivate_business_sheet.dart` does. For the logout dialog, either add a `showAsDialog` flag to `AppDeactivateBottomSheet` or extract a separate `AppConfirmDialog` that shares the two-button row logic.

```dart
// Before (delete_category_sheet.dart) — inline scaffold
showModalBottomSheet(...)
  → DecoratedBox → Padding → Column
    → _SheetHandle, _DangerIcon, Text, Text, _DeleteActions

// After — delegate to shared widget
AppDeactivateBottomSheet.show(
  context: context,
  child: AppDeactivateBottomSheet(
    title: tr.deleteCategoryTitle,
    description: tr.deleteCategoryMessage(displayName),
    icon: SolarIconsOutline.trashBinTrash,
    confirmColor: colors.danger,
    isLoading: isLoading,
    onConfirm: () { ... },
  ),
);
```

---

### UI-02 [Warning]: Seven Error Views Are Structurally Identical Inline Clones

**Severity:** Warning
**Category:** Error Views

**Files affected:**
- `lib/features/business/presentation/widgets/business_error_view.dart`
- `lib/features/users/presentation/widgets/user_error_view.dart`
- `lib/features/category/presentation/widgets/category_error_view.dart`
- `lib/features/inventory/presentation/widgets/inventory_error_view.dart`
- `lib/features/notification/presentation/widgets/notification_error_view.dart`
- `lib/features/sales_history/presentation/widgets/sale_error_view.dart`
- `lib/features/products/presentation/widgets/product_error_view.dart`
- `lib/features/products/presentation/widgets/products_category_error_view.dart`

**What's duplicated:**
All eight error views share the exact same structure: `Center > Padding > Column(mainAxisSize.min) > [Icon, SizedBox, Text("Something went wrong"), optional message Text, SizedBox, OutlinedButton.icon("Retry")]`. Visual differences are minor: some use `Icons.cloud_off_rounded`, others use `Icons.wifi_off_rounded`; `sale_error_view.dart` uses a `FilledButton` instead of `OutlinedButton`; padding varies between `AppDims.s5`, `AppDims.s6`, and `AppDims.s8`. Each file is tightly coupled to its own BLoC for the retry callback, which is the only true per-feature variation. `products_category_error_view.dart` additionally uses a raw `TextStyle(fontFamily: 'NunitoSans', ...)` instead of `AppTextStyles`.

**Suggested refactor:**
Create `lib/common/widgets/error_view.dart` with a `AppErrorView` widget accepting `message`, `onRetry`, and optionally `icon`. Each feature passes its own retry callback:

```dart
class AppErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;
  const AppErrorView({
    this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });
  // ... shared layout
}
```

---

### UI-03 [Warning]: Seven Empty-State Views Are Structurally Similar With No Shared Base

**Severity:** Warning
**Category:** Empty States

**Files affected:**
- `lib/features/business/presentation/widgets/business_empty_view.dart`
- `lib/features/users/presentation/widgets/user_empty_view.dart`
- `lib/features/inventory/presentation/widgets/inventory_empty_view.dart`
- `lib/features/notification/presentation/widgets/notification_empty_view.dart`
- `lib/features/sales_history/presentation/widgets/sale_empty_state.dart`
- `lib/features/main_screen/presentation/widgets/products_empty.dart`
- `lib/features/cart/presentation/products_empty.dart`

**What's duplicated:**
All six simpler empty states follow the same layout: a circular icon container, a title `Text`, a subtitle `Text`, and an optional CTA button. The icon container pattern is copied three different ways: `Container(BoxDecoration(shape: BoxShape.circle))`, `DecoratedBox(BoxDecoration(shape: BoxShape.circle))`, and plain `Icon()`. Icon sizes vary between 36-38px with no token. The two `products_empty.dart` files (one in `main_screen`, one in `cart`) share the same purpose — "no products found" — but are completely separate implementations with different icon choices, text styles (one uses raw `TextStyle(fontFamily: 'NunitoSans')`, the other uses `AppTextStyles`), and different layouts.

`ProductEmptyView` is intentionally more elaborate (animated catalog grid) and does not need to be unified, but the five simpler ones should share a base.

**Suggested refactor:**
Create `lib/common/widgets/empty_view.dart`:

```dart
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  const AppEmptyView({...});
}
```

Consolidate the two `products_empty.dart` into a single widget, placed at a shared path like `lib/common/widgets/products_not_found_view.dart`, and delete the `main_screen` copy that uses bare `TextStyle`.

---

### UI-04 [Warning]: Five Skeleton/Loading Widgets Each Define Their Own Private _Shimmer Class

**Severity:** Warning
**Category:** Loading States

**Files affected:**
- `lib/features/business/presentation/widgets/business_card_skeleton.dart`
- `lib/features/users/presentation/widgets/user_card_skeleton.dart`
- `lib/features/products/presentation/widgets/product_grid_skeleton.dart`
- `lib/features/sales_history/presentation/widgets/sale_shimmer.dart`
- `lib/features/notification/presentation/widgets/notification_skeleton.dart`

**What's duplicated:**
`business_card_skeleton.dart`, `user_card_skeleton.dart`, and `product_grid_skeleton.dart` each define a private `_Shimmer` class with identical code:

```dart
class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: context.appColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
```

This is byte-for-byte the same as the public `Shimmer` widget in `lib/widgets/shimmer.dart`, which already has exactly those three parameters. The shared widget exists but is being ignored. `sale_shimmer.dart` rolls its own animated shimmer using `AnimationController` + `AnimatedBuilder`. `notification_skeleton.dart` uses `flutter_animate`'s `.shimmer()` extension. All three implementations produce different visual results — no consistent shimmer style.

**Suggested refactor:**
Replace every private `_Shimmer` class with the public `lib/widgets/shimmer.dart` import. Add a shimmer animation wrapper to the shared `Shimmer` widget (or a companion `AnimatedShimmer`) so all loading states produce the same sweep animation rather than three different effects.

---

### UI-05 [Warning]: Two Competing Bottom Sheet Scaffold Patterns (AppBottomSheet vs ProductSheetShell) — Neither Is App-Wide

**Severity:** Warning
**Category:** Bottom Sheets

**Files affected:**
- `lib/features/settings/presentation/widgets/app_bottom_sheet.dart`
- `lib/features/products/presentation/widgets/product_sheet_shell.dart`
- `lib/features/business/presentation/widgets/add_business_sheet.dart`
- `lib/features/business/presentation/widgets/shop/add_shop_sheet.dart`
- `lib/features/category/presentation/widgets/add_category_sheet.dart`
- `lib/features/users/presentation/widgets/add_user_sheet.dart`
- `lib/features/users/presentation/widgets/edit_user_sheet.dart`
- `lib/features/customers/presentation/widgets/customer_form_sheet.dart`

**What's duplicated:**
The app has two legitimate sheet scaffold widgets — `AppBottomSheet` (settings-feature-scoped) and `ProductSheetShell` (product-feature-scoped) — plus many sheets that roll their own. Both share the same core structure: `Padding(viewInsets) > DecoratedBox(surface, top radius 24) > Column [drag handle, title row with close button, Flexible(SingleChildScrollView(child))]`. The drag handle itself is duplicated in at least five places as an inline `DecoratedBox(color: colors.border, radius: 999) + SizedBox(width: 36/38, height: 4)`. Add/edit sheets for business, shop, and users build this structure from scratch rather than delegating to either existing scaffold.

**Suggested refactor:**
Move `AppBottomSheet` (or a renamed version) to `lib/common/widgets/app_bottom_sheet.dart`. All form sheets — add/edit business, shop, category, users, customers — should use it. The drag handle inline code should be removed entirely since `BottomSheetThemeData` in `app_theme.dart` already configures `dragHandleColor` and `dragHandleSize` — rely on Flutter's native drag handle via `showModalBottomSheet(showDragHandle: true, ...)`.

---

### UI-06 [Warning]: Three Separate Search Bar Implementations With No Shared Component

**Severity:** Warning
**Category:** Search

**Files affected:**
- `lib/features/main_screen/presentation/widgets/search_row.dart`
- `lib/features/pos/presentation/widgets/pos_search_section.dart`
- `lib/features/returns/presentation/widgets/custom_search_field.dart`

**What's duplicated:**
Three search inputs, all serving the same purpose (product/text search), are fully independent implementations. `search_row.dart` (main screen) uses a `Container` wrapping a `TextField` with raw `TextStyle(fontFamily: 'NunitoSans', ...)` and `Icons.search_rounded` / `Icons.qr_code_scanner_rounded` from Material. `pos_search_section.dart` uses `InputDecoration` with Solar icons and a custom animated scanner button. `custom_search_field.dart` (returns) uses a `Stack`-based layout to manually position prefix/suffix icons and hardcodes `AppColors.danger` as the focused border color (inconsistent with the rest of the app's `colors.primary` focus style). All three produce different visual results for the same interaction.

**Suggested refactor:**
Create `lib/common/widgets/app_search_field.dart` with parameters for `controller`, `onChanged`, `hint`, and optional `onScanTap`. The scanner button from `pos_search_section.dart` is the highest-quality implementation and should be extracted. `custom_search_field.dart`'s danger-color focus border is a visual inconsistency that goes away when replaced.

---

### UI-07 [Warning]: Four Section Header Widgets Doing the Same Job

**Severity:** Warning
**Category:** Section Headers

**Files affected:**
- `lib/widgets/workspace_section_header.dart`
- `lib/features/settings/presentation/widgets/settings_section_label.dart`
- `lib/features/settings/presentation/widgets/setting_section_header.dart`
- `lib/features/feature_menu/widgets/section_label.dart`

**What's duplicated:**
`WorkspaceSectionHeader` renders a title + fading decorative rule. `SettingsSectionLabel` renders an uppercase letter-spaced label string (identical visual intent to `SectionLabel` in `feature_menu`). `SectionLabel` in `feature_menu` calls `.toUpperCase()` and uses `letterSpacing: 1.2` — the same as `SettingsSectionLabel`'s `letterSpacing: 1.2`. The only difference is hardcoded padding in `SectionLabel` vs none in `SettingsSectionLabel`. `SettingSectionHeader` wraps `WorkspaceSectionHeader` and adds a subtitle — this is reasonable composition, but the two upstream label widgets (`SettingsSectionLabel` and `SectionLabel`) should be one.

**Suggested refactor:**
Merge `SettingsSectionLabel` and `SectionLabel` into the existing `WorkspaceSectionHeader` by adding an optional `showRule` parameter (default `true`; set `false` for the label-only variant). Delete both feature-local classes.

---

### UI-08 [Warning]: PrimarySheetButton and Each Feature's Submit Button Are Four Versions of the Same Component

**Severity:** Warning
**Category:** Buttons

**Files affected:**
- `lib/features/settings/presentation/widgets/primary_sheet_button.dart`
- `lib/features/category/presentation/widgets/category_sheet_widgets.dart` (`CategorySubmitButton`)
- `lib/features/customers/presentation/widgets/customer_sheet_widgets.dart` (`CustomerSubmitButton`)
- `lib/features/users/presentation/widgets/user_sheet_widgets.dart` (`UserSubmitButton`)
- `lib/widgets/app_button.dart` (`AppButton` — the canonical button)

**What's duplicated:**
Four "submit" button widgets all render a full-width `FilledButton` (height 50–52px) with a loading `CircularProgressIndicator` spinner and a text label. `PrimarySheetButton` and `CategorySubmitButton` are the most similar — both are 50px tall, `backgroundColor: colors.primary`, `disabledBackgroundColor: colors.border`, `borderRadius: AppDims.rMd`, `CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)`. `CustomerSubmitButton` is identical except 50px. `UserSubmitButton` adds an icon next to the label. All four also independently observe their respective BLoC's `submitStatus` in slightly different ways. Meanwhile, `AppButton` already has `isLoading: true` handling and a `AppButton.wide` constructor, but none of these use it.

**Suggested refactor:**
Add a `danger` variant to `AppButton` (or keep the existing `primary` variant and let callers pass `isLoading`). Replace `PrimarySheetButton`, `CategorySubmitButton`, and `CustomerSubmitButton` with `AppButton.wide(isLoading: isLoading, ...)`. `UserSubmitButton`'s icon variant can use `AppButton.wide(prefixIcon: Icon(icon), ...)`.

---

### UI-09 [Warning]: AppButton Missing a Danger/Destructive Variant (Hardcoded Red Everywhere)

**Severity:** Warning
**Category:** Buttons

**Files affected:**
- `lib/features/category/presentation/widgets/delete_category_sheet.dart` (line 246: `const Color(0xFFDC2626)`)
- `lib/features/products/presentation/widgets/delete_product_sheet.dart` (line 218: `const Color(0xFFDC2626)`)
- `lib/features/customers/presentation/widgets/delete_customer_sheet.dart` (line 140: `const Color(0xFFDC2626)`)
- `lib/features/settings/presentation/widgets/settings_logout_dialog.dart` (line 10: `const Color(0xFFEF4444)`)
- `lib/features/inventory/presentation/widgets/stock_card.dart` (line 28: `const Color(0xFFDC2626)`)

**What's duplicated:**
The danger color `0xFFDC2626` is already defined as `AppColors.danger` and exposed as `context.appColors.danger`. Yet five files hardcode it as a literal `Color(0xFFDC2626)`. `settings_logout_dialog.dart` uses a slightly different hex `0xFFEF4444`, creating a visual inconsistency — the logout red does not match the delete red. `AppButton` has no `danger` variant, which forces all deletion UIs to inline their own `FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626))`.

**Suggested refactor:**
Add `AppButtonVariant.danger` to `AppButton`. Replace all five inline red `FilledButton` instances with `AppButton(variant: AppButtonVariant.danger, ...)`. Standardize on `colors.danger` (not literal hex) for the color token.

---

### UI-10 [Warning]: Two Identical Loading Grids Named products_loading_grid.dart in Different Features

**Severity:** Warning
**Category:** Loading States

**Files affected:**
- `lib/features/pos/presentation/widgets/products_loading_grid.dart`
- `lib/features/cart/presentation/products_loading_grid.dart`

**What's duplicated:**
Two files share the same name and are in different feature directories. Without reading both in detail they may differ in grid delegate configuration, but the class name collision and file path symmetry (`pos/widgets/` and `cart/`) strongly suggests this is a copy-paste that diverged. Even if slightly different, both exist to show a loading grid of product placeholders — the same visual intent as `ProductLoadingView` in the products feature, creating a third loading grid variant.

**Suggested refactor:**
Consolidate into one `lib/common/widgets/product_grid_loading.dart` parameterized by crossAxisCount or aspect ratio, and have all three callers reference it.

---

### UI-11 [Warning]: Two App Bars (InventoryAppBar, ProductsAppBar) Are Near-Identical SliverAppBars

**Severity:** Warning
**Category:** App Bars

**Files affected:**
- `lib/features/inventory/presentation/widgets/inventory_app_bar.dart`
- `lib/features/products/presentation/widgets/products_app_bar.dart`

**What's duplicated:**
Both are `SliverAppBar` with `automaticallyImplyLeading: false`, `pinned: true`, `elevation: 0`, `backgroundColor: colors.background`, `surfaceTintColor: Colors.transparent`, a title using `AppTextStyles.bs600` with `fontWeight: FontWeight.w900`, and a `TextButton.icon` action using `SolarIconsOutline.addCircle`. The only differences are: the title string, the action label string, and the fact that `products_app_bar.dart` adds a layout-toggle icon button. This is enough variation to keep them separate, but the common base configuration (7 identical properties) could be extracted into a factory helper or a shared `FeatureSliverAppBar` widget.

**Suggested refactor:**
Create `lib/common/widgets/feature_sliver_app_bar.dart` with `title`, `actionLabel`, `actionIcon`, `onAction`, and optional `additionalActions`. Both features pass their specific strings and callbacks.

---

### UI-12 [Warning]: ThemePickerSheet and LanguagePickerSheet Share an Option-Row Pattern That Is Duplicated

**Severity:** Warning
**Category:** Bottom Sheets / Cards

**Files affected:**
- `lib/features/settings/presentation/widgets/theme_picker_sheet.dart` (`_ThemeOption`)
- `lib/features/settings/presentation/widgets/language_picker_sheet.dart` (`_LangOption`)

**What's duplicated:**
`_ThemeOption` and `_LangOption` are structurally identical selection row cards: `AnimatedContainer` with `borderRadius: AppDims.rLg`, selected/unselected border color, a left icon badge (46×46), a title+subtitle `Column`, and a 22×22 animated radio circle on the trailing end. The animation (`.animate().fadeIn().slideY()`) is also shared. The only differences are the data type (`ScreenMode` vs language code string) and the icon badge content (an `Icon` vs a `Text` character). This is ~90 lines of near-identical code in two files in the same feature.

**Suggested refactor:**
Extract a `_PickerOptionRow` private widget (or a shared `SelectableOptionTile` in settings widgets) that accepts `isSelected`, `title`, `subtitle`, `leading` widget, `onTap`, and `delay`. Both pickers compose it with their respective leading widgets.

---

### UI-13 [Warning]: Duplicate Spacing Scale — AppDims vs AppSpacing/AppRadius Both Define the Same Values

**Severity:** Warning
**Category:** Design System

**Files affected:**
- `lib/theme/app_spacing.dart` (defines `AppSpacing`, `AppRadius`, `AppPadding`, `AppGap`, and also `AppDims`)

**What's duplicated:**
`AppDims` is defined in the same file as `AppSpacing` and `AppRadius` and duplicates the same scale. `AppDims.s4 = 16` is the same value as `AppSpacing.md = 16`. `AppDims.rMd = 14` equals `AppRadius.md = 14`. Files inconsistently use either system: `app_deactivate_bottom_sheet.dart` uses `AppDims.rXl`, while `app_theme.dart` uses `AppRadius.xl`. Both resolve to `24`, so there is no visual bug, but the duplicated token namespace makes the codebase harder to maintain and creates confusion about which system is canonical.

**Suggested refactor:**
Deprecate `AppDims` spacing constants (s0–s8, rXs–rXxl) and route all usages to `AppSpacing`/`AppRadius`. Keep `AppDims.appBarHeight`, `AppDims.cartPeekHeight`, and `AppDims.fast/medium/slow` as those are not duplicated. A global find-and-replace migration is tractable.

---

### UI-14 [Warning]: Icon Sets Are Mixed — Material Icons and Solar Icons Used Interchangeably With No Policy

**Severity:** Warning
**Category:** Design System

**Files affected:**
- `lib/features/business/presentation/widgets/detail_app_bar.dart` (lines 22–36: `Icons.arrow_back_rounded`, `Icons.edit_outlined`, `Icons.block_rounded`)
- `lib/features/inventory/presentation/widgets/stock_card.dart` (lines 66–72: `Icons.remove_shopping_cart_outlined`, `Icons.warning_amber_rounded`, `Icons.inventory_2_outlined`, `Icons.storefront_outlined`, `Icons.tune_rounded`)
- `lib/features/sales_history/presentation/widgets/sale_app_bar.dart` (line 34: `Icons.receipt_long_rounded`, `Icons.refresh_rounded`)
- `lib/features/sync/presentation/widgets/sync_app_bar.dart` (line 139: `Icons.warning_amber_rounded`, `Icons.sync_rounded`)
- All error views (use `Icons.cloud_off_rounded` / `Icons.wifi_off_rounded` from Material)

**What's duplicated:**
The app uses `solar_icons` (`SolarIconsOutline.*`) as its primary icon library, but many files fall back to `Icons.*` from Material — especially in older or less-refined areas. This creates visual inconsistency: Solar icons have a distinct outline style and weight that clashes with Material's filled/outlined variants. The `BackButton` widget uses `SolarIconsOutline.altArrowLeft` correctly; `detail_app_bar.dart` uses `Icons.arrow_back_rounded` for the same purpose.

**Suggested refactor:**
Adopt Solar icons as the single icon library. Replace all `Icons.*` usages with their Solar equivalents. Key mappings: `Icons.cloud_off_rounded` → `SolarIconsOutline.cloudCross`, `Icons.refresh_rounded` → `SolarIconsOutline.refresh`, `Icons.arrow_back_rounded` → `SolarIconsOutline.altArrowLeft` (via `DirectionalIcon`).

---

### UI-15 [Warning]: BackButton Widget Exists But Is Never Used — Feature App Bars Inline Their Own

**Severity:** Warning
**Category:** App Bars

**Files affected:**
- `lib/widgets/back_button.dart` (defined, apparently unused)
- `lib/features/business/presentation/widgets/detail_app_bar.dart` (line 22: inline `IconButton(Icons.arrow_back_rounded)`)
- `lib/features/business/presentation/widgets/shop/shop_app_bar.dart` (line 31–36: inline `IconButton(DirectionalIcon(SolarIconsOutline.arrowLeft))`)
- `lib/features/sync/presentation/widgets/sync_app_bar.dart` (line 29: inline `IconButton(Icons.arrow_back_rounded)`)

**What's duplicated:**
The shared `BackButton` widget is a 54×54 pill-shaped button with border, `DirectionalIcon`, and tap-to-pop behavior. Three feature app bars duplicate the "back" action with inline `IconButton` calls using different icon choices and no border styling. The shared widget exists specifically to standardize this pattern but is not adopted.

**Suggested refactor:**
Replace all inline back `IconButton` instances in `SliverAppBar.leading` with the shared `BackButton` widget, or if the size (54px) is too large for a sliver app bar leading, adjust `BackButton` to accept a `size` parameter.

---

### UI-16 [Warning]: OptionalDivider Uses Hardcoded English String "OPTIONAL" — Not Localized

**Severity:** Warning
**Category:** Forms

**Files affected:**
- `lib/widgets/optional_divider.dart` (line 19: `'OPTIONAL'` hardcoded)

**What's duplicated / inconsistent:**
`OptionalDivider` is a shared widget that hardcodes the English string `'OPTIONAL'` with uppercase forced in code. When the app locale is Arabic this string will still appear in English and direction will be wrong. All other user-visible strings in reviewed files use `context.tr.*` from the localization system.

**Suggested refactor:**
Add a `label` parameter to `OptionalDivider` defaulting to `context.tr.optional` (add the key to the ARB files if missing). Remove the hardcoded uppercase — let the localized string handle casing per locale, consistent with how `WorkspaceSectionHeader` handles the `toUpperCase()` locale-check.

---

### UI-17 [Info]: SaleAppBar Hardcodes Raw Font Size and Letter Spacing Instead of Using AppTextStyles

**Severity:** Info
**Category:** Design System

**Files affected:**
- `lib/features/sales_history/presentation/widgets/sale_app_bar.dart` (lines 43–48)

**What's duplicated:**
`sale_app_bar.dart` builds its title text with `AppTextStyles.sm100(context).copyWith(fontSize: 10, letterSpacing: 1.0, ...)` — overriding the font size that `sm100` already sets to 10. The style is also built with a mixture of a `.copyWith` on a style that then gets overwritten. Minor issue but inconsistent with the rest of the codebase.

**Suggested refactor:**
Use `AppTextStyles.sm100(context).copyWith(color: ..., fontWeight: ..., letterSpacing: ...)` without the redundant `fontSize` override.

---

### UI-18 [Info]: SearchRow (main_screen) Uses Raw TextStyle Instead of AppTextStyles

**Severity:** Info
**Category:** Design System

**Files affected:**
- `lib/features/main_screen/presentation/widgets/search_row.dart` (lines 41–44, 46–49)

**What's duplicated:**
`search_row.dart` creates text styles as `TextStyle(fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w500, ...)` directly. This is the only reviewed file (besides `products_category_error_view.dart`) that hardcodes the `NunitoSans` font family string rather than using `AppTextStyles.*`. If the font family changes, this file would be missed.

**Suggested refactor:**
Replace both raw `TextStyle` instances with `AppTextStyles.sm300(context).copyWith(...)` or the appropriate scale entry.

---

### UI-19 [Info]: products_empty.dart (main_screen) Uses Raw TextStyle and Magic Padding Value

**Severity:** Info
**Category:** Design System

**Files affected:**
- `lib/features/main_screen/presentation/widgets/products_empty.dart` (lines 24–32)

**What's duplicated:**
This file uses `EdgeInsets.all(40)` — a magic number not in `AppSpacing` or `AppDims` — and raw `TextStyle(fontFamily: 'NunitoSans', ...)` for both title and subtitle. It also renders `'No products found'` as a hardcoded English string rather than `context.tr.*`. The equivalent `cart/presentation/products_empty.dart` is already localized and uses `AppTextStyles`.

**Suggested refactor:**
Replace with the cart version's approach: `AppTextStyles`, `context.tr`, and `AppDims.s5` padding. Then consolidate both files into one shared widget (see UI-03).

---

### UI-20 [Info]: BusinessEmptyView Uses Hardcoded English Strings

**Severity:** Info
**Category:** Empty States

**Files affected:**
- `lib/features/business/presentation/widgets/business_empty_view.dart` (lines 31–42, 58)

**What's duplicated:**
`BusinessEmptyView` hardcodes `'No businesses yet'`, `'Create your first business to get started.'`, and `'Add Business'` as English string literals. All other reviewed empty state views (users, inventory, sales) use `context.tr.*`.

**Suggested refactor:**
Move these strings into the ARB localization files and reference via `context.tr.*`.

---

### UI-21 [Info]: InventoryAppBar Hardcodes English "Stock" and "Add Stock" Strings

**Severity:** Info
**Category:** App Bars

**Files affected:**
- `lib/features/inventory/presentation/widgets/inventory_app_bar.dart` (lines 28, 39)

**What's duplicated:**
`'Stock'` and `'Add Stock'` are hardcoded English strings. `products_app_bar.dart` uses `context.tr.catAppBarProducts` and `context.tr.addProduct` correctly.

**Suggested refactor:**
Add inventory title and action strings to the ARB files and reference via `context.tr.*`.

---

### UI-22 [Info]: StockCard Uses Raw Color Literals Instead of AppColors / AppThemeColors

**Severity:** Info
**Category:** Design System

**Files affected:**
- `lib/features/inventory/presentation/widgets/stock_card.dart` (lines 28–30)

**What's duplicated:**
`statusColor` is assigned from `const Color(0xFFDC2626)`, `const Color(0xFFEA580C)`, and `const Color(0xFF16A34A)` — which are exactly `AppColors.danger`, `AppColors.stockLow`, and `AppColors.success`. These tokens exist in `AppThemeColors` and would adapt correctly in dark theme, whereas the hardcoded literals do not change with theme.

**Suggested refactor:**
Replace with `colors.danger`, `colors.stockLow`, and `colors.success` from `context.appColors`.

---

### UI-23 [Info]: AppBottomSheet Lives in Settings Feature — Should Be Promoted to Common

**Severity:** Info
**Category:** Bottom Sheets

**Files affected:**
- `lib/features/settings/presentation/widgets/app_bottom_sheet.dart`

**What's duplicated:**
`AppBottomSheet` is a high-quality, reusable sheet scaffold but is scoped to `lib/features/settings/`. The category and users features each build their own sheet shells (`ProductSheetShell`, inline variants) rather than reusing this widget because it is not discoverable as a shared component.

**Suggested refactor:**
Move to `lib/common/widgets/app_bottom_sheet.dart` without logic changes. Update the settings feature imports accordingly.

---

### UI-24 [Info]: PrimarySheetButton Lives in Settings Feature — Should Be Promoted to Common

**Severity:** Info
**Category:** Buttons

**Files affected:**
- `lib/features/settings/presentation/widgets/primary_sheet_button.dart`

**What's duplicated:**
Same discoverability problem as `AppBottomSheet`. It is a useful widget that three other features recreate as `CategorySubmitButton`, `CustomerSubmitButton`, `UserSubmitButton`.

**Suggested refactor:**
Move to `lib/common/widgets/` or consolidate into `AppButton.wide(isLoading: ...)` (see UI-08).

---

### UI-25 [Info]: SaleErrorView Deviates From the Other Error Views' Button Style (FilledButton vs OutlinedButton)

**Severity:** Info
**Category:** Error Views

**Files affected:**
- `lib/features/sales_history/presentation/widgets/sale_error_view.dart` (line 35: `FilledButton.icon`)
- All other error views: `OutlinedButton.icon`

**What's duplicated:**
Six of the seven error views use `OutlinedButton.icon` for retry. `sale_error_view.dart` uses `FilledButton.icon` with `backgroundColor: AppColors.primary`. This creates a visual inconsistency — the retry button looks different in the sales screen vs every other screen. Additionally, `sale_error_view.dart` wraps its icon in a colored `Container` box (unique to it) and references `AppColors` (static) rather than `colors.danger` (themed).

**Suggested refactor:**
Standardize retry to `OutlinedButton.icon` across all error views (consistent with the majority), or make it a parameter of the shared `AppErrorView` proposed in UI-02.

---

### UI-26 [Info]: SettingsLogoutDialog Uses a Different Danger Red Than AppColors.danger

**Severity:** Info
**Category:** Delete Dialogs

**Files affected:**
- `lib/features/settings/presentation/widgets/settings_logout_dialog.dart` (line 10: `const Color(0xFFEF4444)`)
- All delete sheets: `const Color(0xFFDC2626)` = `AppColors.danger`

**What's duplicated:**
The logout dialog uses `0xFFEF4444` (a slightly lighter red — Tailwind `red-500`) while every delete sheet uses `0xFFDC2626` (Tailwind `red-600`). Both should use `context.appColors.danger` which is already defined as `0xFFDC2626` and adapts to dark theme.

**Suggested refactor:**
Replace `const Color _dangerColor = Color(0xFFEF4444)` with `context.appColors.danger`.

---

### UI-27 [Info]: PosProductCard Hardcodes Currency Symbol "SDG" in _formatPrice

**Severity:** Info
**Category:** Design System / Localization

**Files affected:**
- `lib/features/pos/presentation/widgets/pos_product_card.dart` (lines 223–237)

**What's duplicated:**
`_formatPrice` in `PosProductCard` appends `' SDG'` as a hardcoded string, while `product_grid_card.dart` and `product_list_card.dart` use a `_formatPrice` that outputs just the number without a currency suffix. The POS card thus shows `"12 SDG"` while the product catalog shows `"12"` for the same product — inconsistent currency display. This is a localization/design system gap rather than a bug.

**Suggested refactor:**
Extract a shared `formatPrice(dynamic value, {bool showCurrency = false})` utility function or use a `NumberFormat` from `intl` with a locale-aware currency formatter.

---

## Refactor Priority

| Priority | Finding | Description | Files Affected | Effort |
|---|---|---|---|---|
| 1 | UI-01 | Delete/deactivate sheets not using AppDeactivateBottomSheet | 5 | Low |
| 2 | UI-02 | 8 error views — no shared base | 8 | Low |
| 3 | UI-04 | 5 skeleton files duplicate _Shimmer instead of using lib/widgets/shimmer.dart | 5 | Low |
| 4 | UI-08 | 4 submit button variants — AppButton exists but unused | 4 | Low |
| 5 | UI-03 | 7 empty state views — no shared base | 7 | Medium |
| 6 | UI-05 | Sheet scaffold duplicated across 8+ sheets | 8+ | Medium |
| 7 | UI-09 | Danger color hardcoded in 5 places — AppButton missing danger variant | 5 | Low |
| 8 | UI-13 | AppDims duplicates AppSpacing/AppRadius | All files | Medium |
| 9 | UI-06 | 3 search bars — no shared component | 3 | Medium |
| 10 | UI-14 | Mixed icon sets (Material + Solar) | 10+ | Medium |
| 11 | UI-07 | 4 section header widgets doing the same job | 4 | Low |
| 12 | UI-12 | ThemePickerSheet and LanguagePickerSheet duplicate option-row pattern | 2 | Low |
| 13 | UI-15 | BackButton widget exists but unused | 4 | Low |
| 14 | UI-10 | Two products_loading_grid.dart files | 2 | Low |
| 15 | UI-11 | InventoryAppBar and ProductsAppBar near-identical | 2 | Low |
| 16 | UI-16 | OptionalDivider hardcodes "OPTIONAL" (not localized) | 1 | Low |
| 17 | UI-22 | StockCard uses raw color literals instead of theme tokens | 1 | Low |
| 18 | UI-20/21 | Hardcoded English strings in BusinessEmptyView, InventoryAppBar | 2 | Low |

---

## Summary

The app has a solid design system foundation: `AppThemeColors`, `AppTextStyles`, `AppColors`, and `AppSpacing`/`AppRadius` are all well-structured and consistently referenced via `context.appColors`. However, **the shared widget layer is being systematically bypassed** at the feature level.

The five most impactful problems are:

1. **Error views** (8 files) and **delete/confirm dialogs** (5 files) are the most clear-cut duplications — the shared widgets for both patterns already exist (`AppDeactivateBottomSheet`, and the proposed `AppErrorView`) and the feature-local versions are byte-for-byte structural copies with only the retry callback and BLoC type varying.

2. **Skeleton loading widgets** each define a private `_Shimmer` class that is identical to the public `lib/widgets/shimmer.dart` widget, which was created to avoid exactly this. The shared widget is being ignored by the four files that need it most.

3. **Two sheet scaffold patterns** (`AppBottomSheet` and `ProductSheetShell`) both exist but are feature-scoped, causing most other features to roll a third variant inline. The `BottomSheetThemeData` in `app_theme.dart` already handles the drag handle natively — most of the inline handle code is redundant.

4. **`AppButton` is the least-used button in the app.** Four separate "submit button" widgets exist in feature-local `*_sheet_widgets.dart` files, and the `AppButton` `danger` variant gap forces every deletion UI to hardcode `Color(0xFFDC2626)` inline (5 occurrences, with `settings_logout_dialog.dart` using a slightly different red).

5. **`AppDims`** duplicates `AppSpacing`/`AppRadius` in the same file — both token namespaces are used inconsistently across the codebase.

The highest-ROI fix is consolidating the error views and delete dialogs (findings UI-01, UI-02), which alone removes ~15 near-identical files with minimal risk. The shimmer fix (UI-04) is the next easiest win — it requires only replacing private `_Shimmer` class definitions with an import of the already-existing shared widget.

---

_Reviewed: 2026-06-02_
_Reviewer: Claude (UI Consistency Audit)_
_Depth: deep_
