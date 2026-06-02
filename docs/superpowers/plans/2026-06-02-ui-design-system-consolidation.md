# UI Design System Consolidation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate 27 instances of duplicated UI components across the codebase by wiring screens to existing shared widgets and extracting new ones, without changing any business logic or screen behavior.

**Architecture:** Work in three sweeps — (1) zero-risk mechanical replacements (shimmer, raw colors), (2) new shared widgets + wiring (AppErrorView, AppEmptyView, AppButton.danger, delete sheets), (3) component promotion and design-system hygiene. Each task is independently commit-able and leaves the app in a working state.

**Tech Stack:** Flutter/Dart, BLoC, solar_icons, amana_pos localization via `context.tr.*`, theme via `context.appColors`

---

## SWEEP 1 — Mechanical Quick Wins (zero new files)

---

### Task 1: Replace private `_Shimmer` classes with shared `Shimmer` widget

**Why:** Three skeleton files each define a private `_Shimmer` class byte-for-byte identical to `lib/widgets/shimmer.dart`. The shared widget exists and is being ignored.

**Files:**
- Modify: `lib/features/business/presentation/widgets/business_card_skeleton.dart`
- Modify: `lib/features/users/presentation/widgets/user_card_skeleton.dart`
- Modify: `lib/features/products/presentation/widgets/product_grid_skeleton.dart`

- [ ] **Step 1: Update `business_card_skeleton.dart`**

Replace the entire file content with:

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

class BusinessCardSkeleton extends StatelessWidget {
  const BusinessCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDims.s3),
          const Shimmer(width: 56, height: 56, radius: AppDims.rSm),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: 140, height: 14, radius: 4),
                SizedBox(height: 8),
                Shimmer(width: 90, height: 11, radius: 4),
                SizedBox(height: 6),
                Shimmer(width: 110, height: 10, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update `user_card_skeleton.dart`**

Replace the entire file content with:

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: const [
          Shimmer(width: 44, height: 44, radius: 999),
          SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 130, height: 13, radius: 4),
                SizedBox(height: 7),
                Shimmer(width: 80, height: 11, radius: 4),
              ],
            ),
          ),
          Shimmer(width: 52, height: 22, radius: 999),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update `product_grid_skeleton.dart`**

Remove the private `_Shimmer` class at the bottom and add the import. Replace the entire file:

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDims.rMd)),
              child: Container(color: context.appColors.border),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDims.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: double.infinity, height: 12, radius: 4),
                SizedBox(height: 6),
                Shimmer(width: 60, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: const [
          Shimmer(width: 56, height: 56, radius: AppDims.rSm),
          SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 140, height: 13, radius: 4),
                SizedBox(height: 7),
                Shimmer(width: 70, height: 13, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run `flutter analyze` — expect no errors**

```bash
cd /Users/almogdadjabir/StudioProjects/amana_pos && flutter analyze lib/features/business/presentation/widgets/business_card_skeleton.dart lib/features/users/presentation/widgets/user_card_skeleton.dart lib/features/products/presentation/widgets/product_grid_skeleton.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/business/presentation/widgets/business_card_skeleton.dart \
        lib/features/users/presentation/widgets/user_card_skeleton.dart \
        lib/features/products/presentation/widgets/product_grid_skeleton.dart
git commit -m "refactor(ui): replace private _Shimmer classes with shared Shimmer widget"
```

---

### Task 2: Replace hardcoded danger color literals with `colors.danger`

**Why:** `Color(0xFFDC2626)` appears in 4 files and `Color(0xFFEF4444)` (a different red) in 1 — all should use `context.appColors.danger` so dark-theme and rebrands work automatically. `StockCard` also hardcodes `stockLow` and `success`.

**Files:**
- Modify: `lib/features/category/presentation/widgets/delete_category_sheet.dart`
- Modify: `lib/features/products/presentation/widgets/delete_product_sheet.dart`
- Modify: `lib/features/customers/presentation/widgets/delete_customer_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_logout_dialog.dart`
- Modify: `lib/features/inventory/presentation/widgets/stock_card.dart`

- [ ] **Step 1: Fix `delete_category_sheet.dart`**

Find the `_DangerIcon` class (around line 154). The line:
```dart
const dangerColor = Color(0xFFDC2626);
```
Replace with reading from theme. Change `_DangerIcon` from `const` constructor to a regular one since it now needs context:

```dart
class _DangerIcon extends StatelessWidget {
  const _DangerIcon();

  @override
  Widget build(BuildContext context) {
    final dangerColor = context.appColors.danger;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dangerColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          SolarIconsOutline.trashBinTrash,
          size: 30,
          color: dangerColor,
        ),
      ),
    );
  }
}
```

Also in `_DeleteActions` find the `FilledButton.styleFrom`:
```dart
backgroundColor: const Color(0xFFDC2626),
```
Replace with:
```dart
backgroundColor: context.appColors.danger,
```

- [ ] **Step 2: Fix `delete_product_sheet.dart`**

Find `_DeleteIcon` class and the `_DeleteActions` `FilledButton.styleFrom`. Apply same changes:

In `_DeleteIcon.build`:
```dart
// Remove: const dangerColor = Color(0xFFDC2626);
// Add at top of build():
final dangerColor = context.appColors.danger;
```

In `_DeleteActions` `FilledButton.styleFrom`:
```dart
backgroundColor: context.appColors.danger,
```

- [ ] **Step 3: Fix `delete_customer_sheet.dart`**

Inside `_DeleteCustomerSheet.build`, find the `Container` for the icon and the `FilledButton.styleFrom`. Replace:
```dart
// Container decoration:
color: const Color(0xFFDC2626).withValues(alpha: 0.10),
// Icon color:
color: const Color(0xFFDC2626),
// FilledButton:
backgroundColor: const Color(0xFFDC2626),
```
With:
```dart
final dangerColor = context.appColors.danger;
// Container decoration:
color: dangerColor.withValues(alpha: 0.10),
// Icon color:
color: dangerColor,
// FilledButton:
backgroundColor: dangerColor,
```

- [ ] **Step 4: Fix `settings_logout_dialog.dart`**

Remove the static constant:
```dart
// DELETE THIS LINE:
static const Color _dangerColor = Color(0xFFEF4444);
```

In `build`, add at top:
```dart
final dangerColor = colors.danger;
```

Replace all `_dangerColor` usages (4 total) with `dangerColor`.

- [ ] **Step 5: Fix `stock_card.dart`**

Find the `statusColor` assignment (around lines 28–30). Replace:
```dart
// BEFORE:
final statusColor = switch (/* status */) {
  ... => const Color(0xFFDC2626),
  ... => const Color(0xFFEA580C),
  ... => const Color(0xFF16A34A),
  ...
};
```
With:
```dart
final colors = context.appColors;
final statusColor = switch (/* same condition */) {
  ... => colors.danger,
  ... => colors.stockLow,
  ... => colors.success,
  ...
};
```

Note: Read the actual switch condition from the file — only replace the color literals, not the condition logic.

- [ ] **Step 6: Run `flutter analyze` on changed files — expect no errors**

```bash
flutter analyze \
  lib/features/category/presentation/widgets/delete_category_sheet.dart \
  lib/features/products/presentation/widgets/delete_product_sheet.dart \
  lib/features/customers/presentation/widgets/delete_customer_sheet.dart \
  lib/features/settings/presentation/widgets/settings_logout_dialog.dart \
  lib/features/inventory/presentation/widgets/stock_card.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/category/presentation/widgets/delete_category_sheet.dart \
        lib/features/products/presentation/widgets/delete_product_sheet.dart \
        lib/features/customers/presentation/widgets/delete_customer_sheet.dart \
        lib/features/settings/presentation/widgets/settings_logout_dialog.dart \
        lib/features/inventory/presentation/widgets/stock_card.dart
git commit -m "refactor(ui): replace hardcoded danger/status color literals with theme tokens"
```

---

### Task 3: Fix `OptionalDivider` hardcoded "OPTIONAL" string

**Why:** The shared `OptionalDivider` widget hardcodes the English word "OPTIONAL". When locale is Arabic this string stays English.

**Files:**
- Modify: `lib/widgets/optional_divider.dart`

- [ ] **Step 1: Update `optional_divider.dart` to accept a label parameter**

Read the current file first to confirm its structure, then replace:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OptionalDivider extends StatelessWidget {
  final String? label;

  const OptionalDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = label ?? context.tr.optional;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: AppTextStyles.sm100(context).copyWith(
              color: colors.textHint,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }
}
```

Note: If `context.tr.optional` key does not exist, add it to the ARB files (`lib/l10n/app_en.arb` → `"optional": "OPTIONAL"`, `lib/l10n/app_ar.arb` → `"optional": "اختياري"`).

- [ ] **Step 2: Run `flutter analyze lib/widgets/optional_divider.dart` — expect no errors**

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/optional_divider.dart
git commit -m "fix(l10n): localize OptionalDivider label via context.tr.optional"
```

---

## SWEEP 2 — New shared widgets + wiring

---

### Task 4: Add `danger` variant to `AppButton`

**Why:** `AppButton` has no danger variant, forcing deletion UIs to hardcode `FilledButton(backgroundColor: colors.danger)`. After this task the delete sheet refactor (Task 6) can use `AppButton(variant: AppButtonVariant.danger)`.

**Files:**
- Modify: `lib/widgets/app_button.dart`

- [ ] **Step 1: Add `danger` to `AppButtonVariant` and handle it in the switch**

Open `lib/widgets/app_button.dart`. Change the enum:

```dart
enum AppButtonVariant { primary, secondary, outline, ghost, danger }
```

In the `build` method, extend the `(bgColor, fgColor, borderColor)` switch:

```dart
AppButtonVariant.danger => (
  isDisabled
      ? theme.colorScheme.error.withValues(alpha: 0.4)
      : theme.colorScheme.error,
  Colors.white,
  Colors.transparent,
),
```

The `error` color in `app_theme.dart` should be wired to `AppColors.danger`. Verify this is the case; if `theme.colorScheme.error` is not `AppColors.danger`, use `Theme.of(context).extension<AppThemeColors>()?.danger` pattern or simply pass the color differently. The safest approach that matches the rest of the codebase:

```dart
AppButtonVariant.danger => (
  isDisabled
      ? context_appColors_danger.withValues(alpha: 0.4)
      : context_appColors_danger,
  Colors.white,
  Colors.transparent,
),
```

But `build` is where colors come from `theme`. Since `danger` is not in `colorScheme`, restructure slightly: read `context.appColors` at the top of `build` and use it for the danger case only:

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colors = context.appColors;          // ADD THIS
  final isDisabled = onPressed == null || isLoading;

  // ... size switch unchanged ...

  final (bgColor, fgColor, borderColor) = switch (variant) {
    AppButtonVariant.primary => (
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      theme.colorScheme.onPrimary,
      Colors.transparent,
    ),
    AppButtonVariant.secondary => (
      isDisabled ? theme.colorScheme.secondary.withValues(alpha: 0.4) : theme.colorScheme.secondary,
      theme.colorScheme.onSecondary,
      Colors.transparent,
    ),
    AppButtonVariant.outline => (
      Colors.transparent,
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
    ),
    AppButtonVariant.ghost => (
      Colors.transparent,
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      Colors.transparent,
    ),
    AppButtonVariant.danger => (          // NEW
      isDisabled ? colors.danger.withValues(alpha: 0.4) : colors.danger,
      Colors.white,
      Colors.transparent,
    ),
  };

  // ... rest of build unchanged ...
}
```

Also add the import at the top if not already present:
```dart
import 'package:amana_pos/theme/app_theme_colors.dart';
```

- [ ] **Step 2: Run `flutter analyze lib/widgets/app_button.dart` — expect no errors**

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/app_button.dart
git commit -m "feat(ui): add danger variant to AppButton"
```

---

### Task 5: Create shared `AppErrorView` widget

**Why:** 8 error views are structural copies. This task creates the shared base; Task 6 wires all of them.

**Files:**
- Create: `lib/common/widgets/error_view.dart`

- [ ] **Step 1: Create `lib/common/widgets/error_view.dart`**

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class AppErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    required this.onRetry,
    this.message,
    this.icon = SolarIconsOutline.cloudCross,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textHint),
            const SizedBox(height: AppDims.s3),
            Text(
              tr.somethingWentWrong,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDims.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(SolarIconsOutline.refresh, size: 16),
              label: Text(
                tr.retry,
                style: AppTextStyles.bs400(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note: `context.tr.somethingWentWrong` key confirmed to exist in the codebase. `context.tr.retry` key confirmed to exist. If `SolarIconsOutline.cloudCross` is not the exact name in the version installed, use `SolarIconsOutline.cloud` — check `solar_icons` package exports if analyzer errors.

- [ ] **Step 2: Run `flutter analyze lib/common/widgets/error_view.dart` — expect no errors**

- [ ] **Step 3: Commit**

```bash
git add lib/common/widgets/error_view.dart
git commit -m "feat(ui): add shared AppErrorView widget"
```

---

### Task 6: Wire all 8 error views to `AppErrorView`

**Why:** Every feature error view is now a thin wrapper over `AppErrorView`. The only per-feature code is the BLoC retry event.

**Files:**
- Modify: `lib/features/business/presentation/widgets/business_error_view.dart`
- Modify: `lib/features/users/presentation/widgets/user_error_view.dart`
- Modify: `lib/features/category/presentation/widgets/category_error_view.dart`
- Modify: `lib/features/inventory/presentation/widgets/inventory_error_view.dart`
- Modify: `lib/features/notification/presentation/widgets/notification_error_view.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_error_view.dart`
- Modify: `lib/features/products/presentation/widgets/product_error_view.dart`
- Modify: `lib/features/products/presentation/widgets/products_category_error_view.dart`

- [ ] **Step 1: Replace `business_error_view.dart`**

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessErrorView extends StatelessWidget {
  final String? message;
  const BusinessErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<BusinessBloc>().add(OnBusinessInitial()),
    );
  }
}
```

- [ ] **Step 2: Replace `user_error_view.dart`**

Read the file first to confirm the BLoC event name, then:

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserErrorView extends StatelessWidget {
  final String? message;
  const UserErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<UserBloc>().add(const OnUsersInitial()),
    );
  }
}
```

Note: Confirm BLoC class name (`UserBloc` or `UsersBloc`) and event name by reading the file before replacing.

- [ ] **Step 3: Replace `category_error_view.dart`**

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryErrorView extends StatelessWidget {
  final String? message;
  const CategoryErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<CategoryBloc>().add(const OnCategoryInitial()),
    );
  }
}
```

- [ ] **Step 4: Replace `inventory_error_view.dart`**

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryErrorView extends StatelessWidget {
  final String? message;
  const InventoryErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<InventoryBloc>().add(const OnInventoryInitial()),
    );
  }
}
```

- [ ] **Step 5: Replace `notification_error_view.dart`**

Read the file to confirm BLoC class + event name, then apply the same pattern:

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationErrorView extends StatelessWidget {
  final String? message;
  const NotificationErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<NotificationBloc>().add(const OnNotificationsInitial()),
    );
  }
}
```

- [ ] **Step 6: Replace `sale_error_view.dart`**

`SaleErrorView` currently takes `onRetry` as a parameter (it's already the correct design). Replace with:

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:flutter/material.dart';

class SaleErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const SaleErrorView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(message: message, onRetry: onRetry);
  }
}
```

- [ ] **Step 7: Replace `product_error_view.dart`**

Read the file to confirm BLoC event, then:

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductErrorView extends StatelessWidget {
  final String? message;
  const ProductErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<ProductBloc>().add(const OnProductInitial()),
    );
  }
}
```

- [ ] **Step 8: Replace `products_category_error_view.dart`**

Read the file. It may use a different event or callback pattern. Apply the pattern:

```dart
import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:flutter/material.dart';

class ProductsCategoryErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const ProductsCategoryErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(onRetry: onRetry);
  }
}
```

Note: If the original takes `onRetry` as parameter, keep that interface. If it reads from BLoC, keep that pattern instead.

- [ ] **Step 9: Run `flutter analyze` — expect no errors**

```bash
flutter analyze lib/features/business/presentation/widgets/business_error_view.dart \
  lib/features/users/presentation/widgets/user_error_view.dart \
  lib/features/category/presentation/widgets/category_error_view.dart \
  lib/features/inventory/presentation/widgets/inventory_error_view.dart \
  lib/features/notification/presentation/widgets/notification_error_view.dart \
  lib/features/sales_history/presentation/widgets/sale_error_view.dart \
  lib/features/products/presentation/widgets/product_error_view.dart \
  lib/features/products/presentation/widgets/products_category_error_view.dart
```

Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add lib/features/business/presentation/widgets/business_error_view.dart \
        lib/features/users/presentation/widgets/user_error_view.dart \
        lib/features/category/presentation/widgets/category_error_view.dart \
        lib/features/inventory/presentation/widgets/inventory_error_view.dart \
        lib/features/notification/presentation/widgets/notification_error_view.dart \
        lib/features/sales_history/presentation/widgets/sale_error_view.dart \
        lib/features/products/presentation/widgets/product_error_view.dart \
        lib/features/products/presentation/widgets/products_category_error_view.dart
git commit -m "refactor(ui): wire all error views to shared AppErrorView"
```

---

### Task 7: Create `AppEmptyView` and consolidate `ProductsEmpty` duplicates

**Why:** 6 empty state views share the same icon+title+subtitle+CTA structure with no shared base. Two `products_empty.dart` files exist for the same purpose (one well-written, one not).

**Files:**
- Create: `lib/common/widgets/empty_view.dart`
- Create: `lib/common/widgets/products_not_found_view.dart`

- [ ] **Step 1: Create `lib/common/widgets/empty_view.dart`**

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppDims.s6),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: Icon(icon, size: 38, color: colors.primary),
                ),
              ),
              const SizedBox(height: AppDims.s4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs700(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: AppDims.s5),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                    ),
                    icon: ctaIcon != null
                        ? Icon(ctaIcon, size: 19, color: Colors.white)
                        : const SizedBox.shrink(),
                    label: Text(
                      ctaLabel!,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/common/widgets/products_not_found_view.dart`**

This is the cart's `ProductsEmpty` promoted to common (cart version is the well-written one with localization):

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductsNotFoundView extends StatelessWidget {
  final String query;

  const ProductsNotFoundView({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trimmedQuery = query.trim();
    final hasQuery = trimmedQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s5),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SolarIconsOutline.inboxArchive,
                size: 46,
                color: colors.textHint,
              ),
              const SizedBox(height: AppDims.s3),
              Text(
                context.tr.noProductsFound,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs500(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppDims.s1),
              Text(
                hasQuery
                    ? context.tr.nothingMatchesQuery(trimmedQuery)
                    : context.tr.tryAnotherCategoryOrAddProducts,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze lib/common/widgets/` — expect no errors**

- [ ] **Step 4: Commit**

```bash
git add lib/common/widgets/empty_view.dart lib/common/widgets/products_not_found_view.dart
git commit -m "feat(ui): add shared AppEmptyView and ProductsNotFoundView widgets"
```

---

### Task 8: Wire all empty-state views to `AppEmptyView` and fix `ProductsEmpty`

**Why:** 6 empty views and 2 `ProductsEmpty` duplicates now have shared bases to delegate to.

**Files:**
- Modify: `lib/features/business/presentation/widgets/business_empty_view.dart`
- Modify: `lib/features/users/presentation/widgets/user_empty_view.dart`
- Modify: `lib/features/inventory/presentation/widgets/inventory_empty_view.dart`
- Modify: `lib/features/notification/presentation/widgets/notification_empty_view.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_empty_state.dart`
- Modify: `lib/features/cart/presentation/products_empty.dart`
- Modify: `lib/features/main_screen/presentation/widgets/products_empty.dart`

- [ ] **Step 1: Replace `business_empty_view.dart`**

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/business/presentation/business_screen.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class BusinessEmptyView extends StatelessWidget {
  const BusinessEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.buildings2,
      title: tr.noBusinessesYet,
      subtitle: tr.createYourFirstBusiness,
      ctaLabel: tr.addBusiness,
      ctaIcon: SolarIconsOutline.addCircle,
      onCta: () => Navigator.of(context).pushNamed(RouteStrings.addBusiness),
    );
  }
}
```

Note: Read the existing file to confirm: the exact BLoC dispatch or navigation call for "Add Business", and which localization keys already exist vs need to be added (`noBusinessesYet`, `createYourFirstBusiness`, `addBusiness`). If the existing file hardcodes English strings, add those to the ARB files.

- [ ] **Step 2: Replace `user_empty_view.dart`**

Read the file (already done — it calls `showAddUserSheet(context)`). Replace with:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class UserEmptyView extends StatelessWidget {
  const UserEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.usersGroupRounded,
      title: tr.noCashiersYet,
      subtitle: tr.noCashiersYetDescription,
      ctaLabel: tr.addCashier,
      ctaIcon: SolarIconsOutline.userPlus,
      onCta: () => showAddUserSheet(context),
    );
  }
}
```

- [ ] **Step 3: Replace `inventory_empty_view.dart`**

Read the file to confirm its structure and CTA behavior, then:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class InventoryEmptyView extends StatelessWidget {
  final VoidCallback? onAddStock;
  const InventoryEmptyView({super.key, this.onAddStock});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.box,
      title: tr.noStockYet,
      subtitle: tr.addStockToGetStarted,
      ctaLabel: onAddStock != null ? tr.addStock : null,
      ctaIcon: SolarIconsOutline.addCircle,
      onCta: onAddStock,
    );
  }
}
```

Note: Adjust localization keys to match what exists. If `onAddStock` is not in the original, remove that parameter.

- [ ] **Step 4: Replace `notification_empty_view.dart`**

Read the file to confirm its structure, then apply the same pattern:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class NotificationEmptyView extends StatelessWidget {
  const NotificationEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.bell,
      title: tr.noNotificationsYet,
      subtitle: tr.noNotificationsYetDescription,
    );
  }
}
```

- [ ] **Step 5: Replace `sale_empty_state.dart`**

Read the file to confirm structure, then:

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleEmptyState extends StatelessWidget {
  const SaleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.cart3,
      title: tr.noSalesYet,
      subtitle: tr.noSalesYetDescription,
    );
  }
}
```

- [ ] **Step 6: Update `cart/presentation/products_empty.dart` to delegate to `ProductsNotFoundView`**

The cart version is the good one and is now the canonical source. Update it to use `ProductsNotFoundView`:

```dart
import 'package:amana_pos/common/widgets/products_not_found_view.dart';
import 'package:flutter/material.dart';

class ProductsEmpty extends StatelessWidget {
  const ProductsEmpty({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return ProductsNotFoundView(query: query);
  }
}
```

- [ ] **Step 7: Update `main_screen/presentation/widgets/products_empty.dart`**

The main_screen version is the bad one (hardcoded strings, raw TextStyle). Replace with:

```dart
import 'package:amana_pos/common/widgets/products_not_found_view.dart';
import 'package:flutter/material.dart';

class ProductsEmpty extends StatelessWidget {
  final String? query;
  const ProductsEmpty({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    return ProductsNotFoundView(query: query ?? '');
  }
}
```

- [ ] **Step 8: Run `flutter analyze` — expect no errors**

```bash
flutter analyze \
  lib/features/business/presentation/widgets/business_empty_view.dart \
  lib/features/users/presentation/widgets/user_empty_view.dart \
  lib/features/inventory/presentation/widgets/inventory_empty_view.dart \
  lib/features/notification/presentation/widgets/notification_empty_view.dart \
  lib/features/sales_history/presentation/widgets/sale_empty_state.dart \
  lib/features/cart/presentation/products_empty.dart \
  lib/features/main_screen/presentation/widgets/products_empty.dart
```

- [ ] **Step 9: Commit**

```bash
git add lib/features/business/presentation/widgets/business_empty_view.dart \
        lib/features/users/presentation/widgets/user_empty_view.dart \
        lib/features/inventory/presentation/widgets/inventory_empty_view.dart \
        lib/features/notification/presentation/widgets/notification_empty_view.dart \
        lib/features/sales_history/presentation/widgets/sale_empty_state.dart \
        lib/features/cart/presentation/products_empty.dart \
        lib/features/main_screen/presentation/widgets/products_empty.dart
git commit -m "refactor(ui): wire all empty views to shared AppEmptyView / ProductsNotFoundView"
```

---

### Task 9: Wire delete sheets to `AppDeactivateBottomSheet`

**Why:** Category, Product, and Customer delete sheets each rebuild the full deactivation scaffold instead of using the existing shared widget.

**Files:**
- Modify: `lib/features/category/presentation/widgets/delete_category_sheet.dart`
- Modify: `lib/features/products/presentation/widgets/delete_product_sheet.dart`
- Modify: `lib/features/customers/presentation/widgets/delete_customer_sheet.dart`

For each sheet, the pattern is:
1. The `showXxx` function calls `AppDeactivateBottomSheet.show(...)` instead of raw `showModalBottomSheet`
2. The private sheet widget is replaced by a thin `BlocListener` + `BlocSelector` that feeds into `AppDeactivateBottomSheet`

- [ ] **Step 1: Replace `delete_category_sheet.dart`**

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteCategorySheet(BuildContext context, {required CategoryData category}) {
  final categoryBloc = context.read<CategoryBloc>();
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: categoryBloc,
      child: _DeleteCategorySheet(category: category),
    ),
  );
}

class _DeleteCategorySheet extends StatelessWidget {
  final CategoryData category;
  const _DeleteCategorySheet({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final categoryName = category.name?.trim();
    final displayName = categoryName?.isNotEmpty == true ? categoryName! : tr.category;

    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(message: tr.categoryDeletedSuccessfully, isInfo: true);
          return;
        }
        if (state.submitStatus == CategorySubmitStatus.failure) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: state.submitError ?? tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<CategoryBloc, CategoryState, bool>(
        selector: (state) => state.submitStatus == CategorySubmitStatus.loading,
        builder: (context, isLoading) => AppDeactivateBottomSheet(
          title: tr.deleteCategoryTitle,
          description: tr.deleteCategoryMessage(displayName),
          icon: SolarIconsOutline.trashBinTrash,
          confirmText: tr.delete,
          confirmColor: colors.danger,
          isLoading: isLoading,
          onConfirm: () {
            final categoryId = category.id?.trim();
            if (categoryId == null || categoryId.isEmpty) {
              GlobalSnackBar.show(message: tr.invalidCategory, isError: true);
              return;
            }
            context.read<CategoryBloc>().add(OnDeleteCategory(categoryId: categoryId));
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Replace `delete_product_sheet.dart`**

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteProductSheet(BuildContext context, {required ProductData product}) {
  final productBloc = context.read<ProductBloc>();
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: productBloc,
      child: _DeleteProductSheet(product: product),
    ),
  );
}

class _DeleteProductSheet extends StatelessWidget {
  final ProductData product;
  const _DeleteProductSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final productName = product.name?.trim();
    final displayName = productName?.isNotEmpty == true ? productName! : tr.thisProduct;

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(message: tr.productDeletedSuccessfully, isInfo: true);
          return;
        }
        if (state.submitStatus == ProductSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<ProductBloc, ProductState, bool>(
        selector: (state) => state.submitStatus == ProductSubmitStatus.loading,
        builder: (context, isLoading) => AppDeactivateBottomSheet(
          title: tr.deleteProductTitle,
          description: tr.deleteProductMessage(displayName),
          icon: SolarIconsOutline.trashBinTrash,
          confirmText: tr.delete,
          confirmColor: colors.danger,
          isLoading: isLoading,
          onConfirm: () {
            final productId = product.id;
            if (productId == null || productId.isEmpty) {
              GlobalSnackBar.show(message: tr.invalidProduct, isError: true);
              return;
            }
            context.read<ProductBloc>().add(OnDeleteProduct(productId: productId));
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `delete_customer_sheet.dart`**

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteCustomerSheet(BuildContext context, {required CustomerData customer}) {
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: context.read<CustomersBloc>(),
      child: _DeleteCustomerSheet(customer: customer),
    ),
  );
}

class _DeleteCustomerSheet extends StatelessWidget {
  final CustomerData customer;
  const _DeleteCustomerSheet({required this.customer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocListener<CustomersBloc, CustomersState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CustomerSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: tr.customerDeletedSuccessfully, isInfo: true);
          return;
        }
        if (state.submitStatus == CustomerSubmitStatus.failure) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: state.submitError ?? tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<CustomersBloc, CustomersState, bool>(
        selector: (state) => state.submitStatus == CustomerSubmitStatus.loading,
        builder: (context, isLoading) => AppDeactivateBottomSheet(
          title: tr.deleteCustomerTitle,
          description: tr.deleteCustomerConfirm(customer.name ?? tr.customers),
          icon: SolarIconsOutline.trashBinTrash,
          confirmText: tr.delete,
          confirmColor: colors.danger,
          isLoading: isLoading,
          onConfirm: () {
            final customerId = customer.id;
            if (customerId == null) {
              GlobalSnackBar.show(message: tr.invalidCustomer, isError: true);
              return;
            }
            context.read<CustomersBloc>().add(OnDeleteCustomer(customerId: customerId));
          },
        ),
      ),
    );
  }
}
```

Note: `customerDeletedSuccessfully` key — check if it exists in ARB or use the snackbar message string already used in the old customer screen.

- [ ] **Step 4: Run `flutter analyze` on all three files — expect no errors**

- [ ] **Step 5: Commit**

```bash
git add lib/features/category/presentation/widgets/delete_category_sheet.dart \
        lib/features/products/presentation/widgets/delete_product_sheet.dart \
        lib/features/customers/presentation/widgets/delete_customer_sheet.dart
git commit -m "refactor(ui): wire delete sheets to shared AppDeactivateBottomSheet"
```

---

### Task 10: Collapse feature submit buttons to use `AppButton.wide`

**Why:** `PrimarySheetButton`, `CategorySubmitButton`, `CustomerSubmitButton`, and `UserSubmitButton` all rebuild the same full-width loading `FilledButton`. `AppButton.wide` with `isLoading: true` covers all of them.

**Files:**
- Modify: `lib/features/settings/presentation/widgets/primary_sheet_button.dart`
- Modify: `lib/features/category/presentation/widgets/category_sheet_widgets.dart`
- Modify: `lib/features/customers/presentation/widgets/customer_sheet_widgets.dart`
- Modify: `lib/features/users/presentation/widgets/user_sheet_widgets.dart`

- [ ] **Step 1: Update `primary_sheet_button.dart`**

Replace `PrimarySheetButton.build` to delegate to `AppButton.wide` (keep the class so callers don't break):

```dart
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';

class PrimarySheetButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const PrimarySheetButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.wide(
      label: label,
      isLoading: isLoading,
      onPressed: isLoading ? null : onPressed,
    );
  }
}
```

- [ ] **Step 2: Update `CategorySubmitButton` in `category_sheet_widgets.dart`**

Replace the `CategorySubmitButton` class (leave `CategoryFormValidators` unchanged):

```dart
class CategorySubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const CategorySubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryBloc, CategoryState, bool>(
      selector: (state) => state.submitStatus == CategorySubmitStatus.loading,
      builder: (context, isLoading) {
        final canAct = enabled && !isLoading;
        return AppButton.wide(
          label: label,
          isLoading: isLoading,
          onPressed: canAct ? onPressed : null,
        );
      },
    );
  }
}
```

Add the import at the top:
```dart
import 'package:amana_pos/widgets/app_button.dart';
```

- [ ] **Step 3: Update `CustomerSubmitButton` in `customer_sheet_widgets.dart`**

Replace the `CustomerSubmitButton` class (leave `CustomerFormValidators` unchanged):

```dart
class CustomerSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const CustomerSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CustomersBloc, CustomersState, bool>(
      selector: (state) => state.submitStatus == CustomerSubmitStatus.loading,
      builder: (context, isLoading) => AppButton.wide(
        label: label,
        isLoading: isLoading,
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
```

Add import: `import 'package:amana_pos/widgets/app_button.dart';`

- [ ] **Step 4: Update `UserSubmitButton` in `user_sheet_widgets.dart`**

Replace `UserSubmitButton` class (leave `RolePicker` and private classes unchanged):

```dart
class UserSubmitButton extends StatelessWidget {
  const UserSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon = SolarIconsOutline.userPlus,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, bool>(
      selector: (state) => state.submitStatus == UserSubmitStatus.loading,
      builder: (context, isLoading) {
        final canAct = enabled && !isLoading && onPressed != null;
        return AppButton.wide(
          label: label,
          isLoading: isLoading,
          onPressed: canAct ? onPressed : null,
          prefixIcon: Icon(icon, size: 19, color: Colors.white),
        );
      },
    );
  }
}
```

Add import: `import 'package:amana_pos/widgets/app_button.dart';`

- [ ] **Step 5: Run `flutter analyze` on all 4 files — expect no errors**

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/widgets/primary_sheet_button.dart \
        lib/features/category/presentation/widgets/category_sheet_widgets.dart \
        lib/features/customers/presentation/widgets/customer_sheet_widgets.dart \
        lib/features/users/presentation/widgets/user_sheet_widgets.dart
git commit -m "refactor(ui): collapse feature submit buttons to use AppButton.wide"
```

---

## SWEEP 3 — Promote, consolidate, and design-system hygiene

---

### Task 11: Promote `AppBottomSheet` to `lib/common/widgets/`

**Why:** `AppBottomSheet` is a high-quality sheet scaffold living in the settings feature, making it undiscoverable to other features. Moving it to `common/widgets/` is the fix.

**Files:**
- Create: `lib/common/widgets/app_bottom_sheet.dart` (copy of settings version)
- Modify: `lib/features/settings/presentation/widgets/app_bottom_sheet.dart` (re-export)
- Modify: All settings files importing the old path

- [ ] **Step 1: Copy `app_bottom_sheet.dart` to common**

Copy the full content of `lib/features/settings/presentation/widgets/app_bottom_sheet.dart` to `lib/common/widgets/app_bottom_sheet.dart` — content is identical.

Run:
```bash
cp lib/features/settings/presentation/widgets/app_bottom_sheet.dart \
   lib/common/widgets/app_bottom_sheet.dart
```

Update the import path in the new file if needed (package imports are already absolute so it should be fine).

- [ ] **Step 2: Replace settings version with a re-export**

Replace `lib/features/settings/presentation/widgets/app_bottom_sheet.dart` content with:

```dart
// Re-exported from common for backwards compatibility.
export 'package:amana_pos/common/widgets/app_bottom_sheet.dart';
```

This ensures existing settings imports continue to work with no changes.

- [ ] **Step 3: Run `flutter analyze lib/common/widgets/app_bottom_sheet.dart` — expect no errors**

- [ ] **Step 4: Commit**

```bash
git add lib/common/widgets/app_bottom_sheet.dart \
        lib/features/settings/presentation/widgets/app_bottom_sheet.dart
git commit -m "refactor(ui): promote AppBottomSheet to common/widgets"
```

---

### Task 12: Merge duplicate section header widgets

**Why:** `SettingsSectionLabel` (settings) and `SectionLabel` (feature_menu) are structurally identical — both render an uppercase letter-spaced label. Consolidate to one shared location.

**Files:**
- Create: `lib/common/widgets/section_label.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_section_label.dart` (re-export)
- Modify: `lib/features/feature_menu/widgets/section_label.dart` (re-export)

- [ ] **Step 1: Read both files to confirm they are equivalent**

```bash
cat lib/features/settings/presentation/widgets/settings_section_label.dart
cat lib/features/feature_menu/widgets/section_label.dart
```

Confirm both: render a `Text` with `toUpperCase()`, `letterSpacing: 1.2`, `textSecondary` color. Note any differences.

- [ ] **Step 2: Create `lib/common/widgets/section_label.dart`**

Write the canonical version using the better of the two implementations (feature_menu version tends to be more minimal):

```dart
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      label.toUpperCase(),
      style: AppTextStyles.sm100(context).copyWith(
        color: colors.textHint,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
```

- [ ] **Step 3: Re-export from both original locations**

`lib/features/settings/presentation/widgets/settings_section_label.dart`:
```dart
export 'package:amana_pos/common/widgets/section_label.dart';
```

`lib/features/feature_menu/widgets/section_label.dart`:
```dart
export 'package:amana_pos/common/widgets/section_label.dart';
```

- [ ] **Step 4: Run `flutter analyze` — expect no errors**

- [ ] **Step 5: Commit**

```bash
git add lib/common/widgets/section_label.dart \
        lib/features/settings/presentation/widgets/settings_section_label.dart \
        lib/features/feature_menu/widgets/section_label.dart
git commit -m "refactor(ui): merge SettingsSectionLabel and SectionLabel into common SectionLabel"
```

---

### Task 13: Use shared `BackButton` in feature detail app bars

**Why:** `lib/widgets/back_button.dart` exists as the canonical back button but is unused. Three feature app bars build inline `IconButton` back buttons with different styling.

**Files:**
- Modify: `lib/features/business/presentation/widgets/detail_app_bar.dart`
- Modify: `lib/features/business/presentation/widgets/shop/shop_app_bar.dart`
- Modify: `lib/features/sync/presentation/widgets/sync_app_bar.dart`

- [ ] **Step 1: Read `lib/widgets/back_button.dart` to understand its API**

Note its constructor parameters and size. If it's 54px and too large for a sliver leading, check how to override.

- [ ] **Step 2: Update `detail_app_bar.dart`**

Find the leading `IconButton` (around line 22). Add import:
```dart
import 'package:amana_pos/widgets/back_button.dart' as app_widgets;
```

Replace the inline `IconButton(Icons.arrow_back_rounded, ...)` with:
```dart
leading: const app_widgets.AppBackButton(),
```

(or whatever the class is named in the file — read first to confirm)

- [ ] **Step 3: Update `shop_app_bar.dart`**

Apply the same change: replace inline `IconButton(DirectionalIcon(SolarIconsOutline.arrowLeft))` with the shared `BackButton` widget.

- [ ] **Step 4: Update `sync_app_bar.dart`**

Apply the same change: replace inline `IconButton(Icons.arrow_back_rounded)` with the shared `BackButton` widget.

- [ ] **Step 5: Run `flutter analyze` on the 3 files — expect no errors**

- [ ] **Step 6: Commit**

```bash
git add lib/features/business/presentation/widgets/detail_app_bar.dart \
        lib/features/business/presentation/widgets/shop/shop_app_bar.dart \
        lib/features/sync/presentation/widgets/sync_app_bar.dart
git commit -m "refactor(ui): use shared BackButton widget in detail app bars"
```

---

### Task 14: Consolidate duplicate `products_loading_grid.dart`

**Why:** Two files in `pos/` and `cart/` have the same name and serve the same visual purpose.

**Files:**
- Read both files first to confirm differences
- Create: `lib/common/widgets/product_grid_loading.dart` (if differences exist, parameterize them)
- Modify: `lib/features/pos/presentation/widgets/products_loading_grid.dart`
- Modify: `lib/features/cart/presentation/products_loading_grid.dart`

- [ ] **Step 1: Read both files and note differences**

```bash
cat lib/features/pos/presentation/widgets/products_loading_grid.dart
cat lib/features/cart/presentation/products_loading_grid.dart
```

Note: grid delegate config (crossAxisCount, aspect ratio), any spacing differences.

- [ ] **Step 2: Create `lib/common/widgets/product_grid_loading.dart`**

Write a version parameterized by the differences found in Step 1:

```dart
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductGridLoading extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final int itemCount;

  const ProductGridLoading({
    super.key,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: AppDims.s2,
      crossAxisSpacing: AppDims.s2,
      children: List.generate(
        itemCount,
        (_) => Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDims.rMd)),
                  child: Container(color: context.appColors.border),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDims.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Shimmer(width: double.infinity, height: 12, radius: 4),
                    SizedBox(height: 6),
                    Shimmer(width: 60, height: 12, radius: 4),
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
```

Adjust the grid structure (Sliver vs regular GridView) and parameters to match what the actual files use — read first.

- [ ] **Step 3: Update both feature files to delegate to the common one**

Each becomes a thin wrapper that matches its existing public API.

- [ ] **Step 4: Run `flutter analyze` — expect no errors**

- [ ] **Step 5: Commit**

```bash
git add lib/common/widgets/product_grid_loading.dart \
        lib/features/pos/presentation/widgets/products_loading_grid.dart \
        lib/features/cart/presentation/products_loading_grid.dart
git commit -m "refactor(ui): consolidate duplicate products_loading_grid into common widget"
```

---

### Task 15: Extract `FeatureSliverAppBar` for Inventory and Products

**Why:** `InventoryAppBar` and `ProductsAppBar` share 7 identical `SliverAppBar` properties, differing only in title text, action text, and whether a layout-toggle icon button exists.

**Files:**
- Create: `lib/common/widgets/feature_sliver_app_bar.dart`
- Modify: `lib/features/inventory/presentation/widgets/inventory_app_bar.dart`
- Modify: `lib/features/products/presentation/widgets/products_app_bar.dart`

- [ ] **Step 1: Read both app bar files to confirm the shared structure**

```bash
cat lib/features/inventory/presentation/widgets/inventory_app_bar.dart
cat lib/features/products/presentation/widgets/products_app_bar.dart
```

Note all differences beyond title/action label.

- [ ] **Step 2: Create `lib/common/widgets/feature_sliver_app_bar.dart`**

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class FeatureSliverAppBar extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> additionalActions;

  const FeatureSliverAppBar({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(SolarIconsOutline.addCircle, size: 18, color: colors.primary),
            label: Text(
              actionLabel!,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ),
        ...additionalActions,
        const SizedBox(width: AppDims.s1),
      ],
    );
  }
}
```

- [ ] **Step 3: Update `inventory_app_bar.dart`**

```dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/feature_sliver_app_bar.dart';
import 'package:flutter/material.dart';

class InventoryAppBar extends StatelessWidget {
  final VoidCallback onAddStock;
  final Future<void> Function() onRefresh;

  const InventoryAppBar({super.key, required this.onAddStock, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return FeatureSliverAppBar(
      title: tr.stock,
      actionLabel: tr.addStock,
      onAction: onAddStock,
    );
  }
}
```

Note: `tr.stock` and `tr.addStock` keys — check ARB files, add if missing.

- [ ] **Step 4: Update `products_app_bar.dart`**

Read the file to see its exact structure and layout-toggle button, then delegate to `FeatureSliverAppBar` with `additionalActions: [layoutToggleButton]`.

- [ ] **Step 5: Run `flutter analyze` — expect no errors**

- [ ] **Step 6: Commit**

```bash
git add lib/common/widgets/feature_sliver_app_bar.dart \
        lib/features/inventory/presentation/widgets/inventory_app_bar.dart \
        lib/features/products/presentation/widgets/products_app_bar.dart
git commit -m "feat(ui): extract FeatureSliverAppBar; wire inventory and products app bars"
```

---

### Task 16: Create shared `AppSearchField`

**Why:** Three search implementations (`search_row.dart`, `pos_search_section.dart`, `custom_search_field.dart`) produce different visuals for the same interaction.

**Files:**
- Create: `lib/common/widgets/app_search_field.dart`
- Modify: `lib/features/main_screen/presentation/widgets/search_row.dart`
- Modify: `lib/features/returns/presentation/widgets/custom_search_field.dart`

Note: `pos_search_section.dart` has a scanner button with complex animated state — keep it using `AppSearchField` internally but preserve its scanner widget wrapper.

- [ ] **Step 1: Read all three files**

```bash
cat lib/features/main_screen/presentation/widgets/search_row.dart
cat lib/features/pos/presentation/widgets/pos_search_section.dart
cat lib/features/returns/presentation/widgets/custom_search_field.dart
```

Note each field's: controller/onChanged API, hint text, prefix/suffix icons, style.

- [ ] **Step 2: Create `lib/common/widgets/app_search_field.dart`**

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final Widget? suffixWidget;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hint,
    this.suffixWidget,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDims.s3),
          Icon(SolarIconsOutline.magnifer, size: 18, color: colors.textHint),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.bs300(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (suffixWidget != null) suffixWidget!,
          const SizedBox(width: AppDims.s2),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update `search_row.dart` to use `AppSearchField`**

Remove the raw `TextStyle(fontFamily: 'NunitoSans', ...)` and inline `Container/TextField` construction. Replace with `AppSearchField(...)`, passing the existing controller, onChanged, and hint.

- [ ] **Step 4: Update `custom_search_field.dart` to use `AppSearchField`**

The Stack-based layout and `AppColors.danger` focused border in this file goes away. Replace with `AppSearchField(...)`.

- [ ] **Step 5: Run `flutter analyze` — expect no errors**

- [ ] **Step 6: Commit**

```bash
git add lib/common/widgets/app_search_field.dart \
        lib/features/main_screen/presentation/widgets/search_row.dart \
        lib/features/returns/presentation/widgets/custom_search_field.dart
git commit -m "feat(ui): add AppSearchField; wire search_row and custom_search_field"
```

---

### Task 17: Fix localization gaps in `InventoryAppBar` and `BusinessEmptyView`

**Why:** These two files hardcode English strings while the rest of the codebase uses `context.tr.*`.

**Files:**
- Modify: `lib/features/inventory/presentation/widgets/inventory_app_bar.dart` (already handled in Task 15)
- Modify: `lib/features/business/presentation/widgets/business_empty_view.dart` (already handled in Task 8)
- Modify: `lib/l10n/app_en.arb` (if keys need to be added)
- Modify: `lib/l10n/app_ar.arb` (if keys need to be added)

- [ ] **Step 1: Check ARB files for missing keys**

```bash
grep -n "noBusinessesYet\|createYourFirstBusiness\|addBusiness\|stock\b\|addStock\|noStockYet\|addStockToGetStarted" lib/l10n/app_en.arb
```

- [ ] **Step 2: Add any missing keys to ARB files**

For each missing key, add to `lib/l10n/app_en.arb`:
```json
"noBusinessesYet": "No businesses yet",
"createYourFirstBusiness": "Create your first business to get started.",
"addBusiness": "Add Business",
"stock": "Stock",
"addStock": "Add Stock",
"noStockYet": "No stock yet",
"addStockToGetStarted": "Add stock to get started."
```

And to `lib/l10n/app_ar.arb` with Arabic translations.

- [ ] **Step 3: Run `flutter gen-l10n` to regenerate localization files**

```bash
flutter gen-l10n
```

Expected: Completes without errors.

- [ ] **Step 4: Commit ARB changes**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add missing keys for business empty view and inventory app bar"
```

---

### Task 18: Replace Material `Icons.*` with Solar icons

**Why:** The app uses Solar icons as its icon library but ~10 files fall back to `Icons.*` from Material, creating visual inconsistency.

**Files:**
- Modify: `lib/features/business/presentation/widgets/detail_app_bar.dart`
- Modify: `lib/features/inventory/presentation/widgets/stock_card.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_app_bar.dart`
- Modify: `lib/features/sync/presentation/widgets/sync_app_bar.dart`
- Modify: `lib/common/widgets/error_view.dart` (use Solar icon, already done in Task 5)

Key icon mappings (confirm package exports before using):
- `Icons.cloud_off_rounded` → `SolarIconsOutline.cloudCross`
- `Icons.refresh_rounded` → `SolarIconsOutline.refresh`
- `Icons.arrow_back_rounded` → `SolarIconsOutline.altArrowLeft` (via `DirectionalIcon`)
- `Icons.edit_outlined` → `SolarIconsOutline.pen2`
- `Icons.block_rounded` → `SolarIconsOutline.forbiddenCircle`
- `Icons.receipt_long_rounded` → `SolarIconsOutline.receipt`
- `Icons.warning_amber_rounded` → `SolarIconsOutline.dangerTriangle`
- `Icons.sync_rounded` → `SolarIconsOutline.refresh`
- `Icons.inventory_2_outlined` → `SolarIconsOutline.box`
- `Icons.storefront_outlined` → `SolarIconsOutline.shop`
- `Icons.tune_rounded` → `SolarIconsOutline.settings`
- `Icons.remove_shopping_cart_outlined` → `SolarIconsOutline.cartCross`
- `Icons.wifi_off_rounded` → `SolarIconsOutline.wifiSquare` (or `SolarIconsOutline.cloudCross`)
- `Icons.logout_rounded` → `SolarIconsOutline.logout` (for settings_logout_dialog.dart)

- [ ] **Step 1: Read each file and replace Material icon usages**

For `detail_app_bar.dart`:
- Replace `Icons.arrow_back_rounded` in leading `IconButton` with `SolarIconsOutline.altArrowLeft` wrapped in `DirectionalIcon` — or use the shared `BackButton` (already done in Task 13)
- Replace `Icons.edit_outlined` → `SolarIconsOutline.pen2`
- Replace `Icons.block_rounded` → `SolarIconsOutline.forbiddenCircle`

For `stock_card.dart`:
- Replace the 5 `Icons.*` references with Solar equivalents from the mapping above

For `sale_app_bar.dart`:
- Replace `Icons.receipt_long_rounded` → `SolarIconsOutline.receipt`
- Replace `Icons.refresh_rounded` → `SolarIconsOutline.refresh`

For `sync_app_bar.dart`:
- Replace `Icons.warning_amber_rounded` → `SolarIconsOutline.dangerTriangle`
- Replace `Icons.sync_rounded` → `SolarIconsOutline.refresh`
- Replace `Icons.arrow_back_rounded` → already done in Task 13

- [ ] **Step 2: Run `flutter analyze` — expect no errors**

- [ ] **Step 3: Commit**

```bash
git add lib/features/business/presentation/widgets/detail_app_bar.dart \
        lib/features/inventory/presentation/widgets/stock_card.dart \
        lib/features/sales_history/presentation/widgets/sale_app_bar.dart \
        lib/features/sync/presentation/widgets/sync_app_bar.dart
git commit -m "refactor(ui): replace Material Icons.* with Solar icons in remaining files"
```

---

### Task 19: Fix raw `TextStyle` and `AppDims`/`AppSpacing` dual scale in remaining files

**Why:** `search_row.dart` (handled in Task 16) and `products_empty.dart` (handled in Tasks 7/8) used raw `TextStyle(fontFamily: 'NunitoSans', ...)`. These are already fixed. This task cleans up the remaining `SaleAppBar` and `AppDims` dual-scale issue.

**Files:**
- Modify: `lib/features/sales_history/presentation/widgets/sale_app_bar.dart`

For `AppDims` vs `AppSpacing` dual scale (UI-13): this is a codebase-wide migration with no behavioral change. **Defer** full migration — it's a global find-replace best done in a dedicated commit. Document it as tech debt in `UI-REVIEW.md` instead.

- [ ] **Step 1: Fix redundant `fontSize` override in `sale_app_bar.dart`**

Read the file. Find the title `Text` style (around line 43–48). Change from:
```dart
style: AppTextStyles.sm100(context).copyWith(fontSize: 10, letterSpacing: 1.0, ...)
```
To:
```dart
style: AppTextStyles.sm100(context).copyWith(letterSpacing: 1.0, ...)
```
(Remove the redundant `fontSize: 10` — `sm100` already sets it to 10.)

- [ ] **Step 2: Run `flutter analyze lib/features/sales_history/presentation/widgets/sale_app_bar.dart` — expect no errors**

- [ ] **Step 3: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/sale_app_bar.dart
git commit -m "fix(ui): remove redundant fontSize override in SaleAppBar title style"
```

---

### Task 20: Extract `_PickerOptionRow` in Theme and Language pickers

**Why:** `ThemePickerSheet._ThemeOption` and `LanguagePickerSheet._LangOption` are ~90 lines of near-identical selection row cards.

**Files:**
- Modify: `lib/features/settings/presentation/widgets/theme_picker_sheet.dart`
- Modify: `lib/features/settings/presentation/widgets/language_picker_sheet.dart`

- [ ] **Step 1: Read both picker files**

```bash
cat lib/features/settings/presentation/widgets/theme_picker_sheet.dart
cat lib/features/settings/presentation/widgets/language_picker_sheet.dart
```

Note: both should have an `AnimatedContainer` card with selected/unselected border, leading icon badge, title+subtitle column, and a trailing radio circle.

- [ ] **Step 2: Extract `_PickerOptionRow` as a private widget in `theme_picker_sheet.dart`**

Add a shared private widget at the bottom of `theme_picker_sheet.dart`:

```dart
class _PickerOptionRow extends StatelessWidget {
  final bool isSelected;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionRow({
    required this.isSelected,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withValues(alpha: 0.06) : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 46, height: 46, child: leading),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        )),
                    Text(subtitle,
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textSecondary,
                        )),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Adjust structure to exactly match what's in the file (read it first). The goal is that `_ThemeOption` and `_LangOption` both shrink to thin wrappers calling `_PickerOptionRow`.

- [ ] **Step 3: Refactor `_ThemeOption` to use `_PickerOptionRow`**

`_ThemeOption` becomes:
```dart
class _ThemeOption extends StatelessWidget {
  final ScreenMode mode;
  final bool selected;
  final VoidCallback onTap;
  // ...
  @override
  Widget build(BuildContext context) => _PickerOptionRow(
    isSelected: selected,
    leading: /* icon badge from the mode */,
    title: /* mode title */,
    subtitle: /* mode subtitle */,
    onTap: onTap,
  );
}
```

- [ ] **Step 4: Copy `_PickerOptionRow` to `language_picker_sheet.dart` and refactor `_LangOption`**

(Private widget — can't import from another file. Copy the class definition.)

Refactor `_LangOption` to call `_PickerOptionRow` the same way.

- [ ] **Step 5: Run `flutter analyze` on both files — expect no errors**

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/widgets/theme_picker_sheet.dart \
        lib/features/settings/presentation/widgets/language_picker_sheet.dart
git commit -m "refactor(ui): extract _PickerOptionRow in theme and language picker sheets"
```

---

### Task 21: Add currency format utility (UI-27)

**Why:** `pos_product_card.dart` appends `' SDG'` as a hardcoded string while other product cards show no currency suffix — inconsistent display for the same price field.

**Files:**
- Read: `lib/features/pos/presentation/widgets/pos_product_card.dart`
- Read: `lib/features/products/presentation/widgets/product_grid_card.dart`

Decide: Does the app want currency shown or not? Check the product grid card format — if it shows no currency, remove the SDG suffix from POS card too. If SDG should be shown everywhere, add it to product cards too.

- [ ] **Step 1: Read `_formatPrice` in `pos_product_card.dart` and `product_grid_card.dart`**

```bash
grep -n "_formatPrice\|SDG" lib/features/pos/presentation/widgets/pos_product_card.dart
grep -n "_formatPrice\|SDG" lib/features/products/presentation/widgets/product_grid_card.dart
```

- [ ] **Step 2: Standardize — remove hardcoded `' SDG'` from POS card**

In `pos_product_card.dart`, in `_formatPrice`:
```dart
// BEFORE:
static String _formatPrice(dynamic value) {
  // ... formats number and appends ' SDG'
  return '$formatted SDG';
}

// AFTER (match product_grid_card behavior):
static String _formatPrice(dynamic value) {
  // ... same number formatting, no currency suffix
  return formatted;
}
```

Note: Only make this change if it matches the product grid card behavior. If the product grid card also shows SDG, leave both as-is and just note the inconsistency is intentional.

- [ ] **Step 3: Run `flutter analyze lib/features/pos/presentation/widgets/pos_product_card.dart` — expect no errors**

- [ ] **Step 4: Commit**

```bash
git add lib/features/pos/presentation/widgets/pos_product_card.dart
git commit -m "fix(ui): standardize price display format in POS product card"
```

---

## Final verification

After all tasks are complete:

- [ ] **Run `flutter analyze lib/`**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Run `flutter build apk --debug` (or `flutter run` on device/simulator)**

Verify: app launches, all screens display, no missing icon errors, dark theme applies correctly to danger-colored elements.

---

## Appendix: Deferred items

These items from the UI-REVIEW are real issues but deferred for a separate pass:

- **UI-13 (AppDims duplicate scale)**: Full global find-replace of `AppDims.s*` → `AppSpacing.*` and `AppDims.r*` → `AppRadius.*`. Safe to do anytime but touches 100+ files.
- **Sale shimmer animation** and **notification shimmer** (`sale_shimmer.dart`, `notification_skeleton.dart`): Use different animation approaches (AnimationController vs flutter_animate). Standardize shimmer animation style as a separate pass after animation library choice is confirmed.
