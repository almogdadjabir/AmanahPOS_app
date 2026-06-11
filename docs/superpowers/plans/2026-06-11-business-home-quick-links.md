# Business Home Quick Links Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "QUICK LINKS" row of 5 round pill chips (Categories, Customers, Inventory, Returns, Settings) to the desktop Business Home dashboard (`_DesktopWorkspace`), between the existing 2×2 module grid and the subscription strip, exactly as specified in `docs/superpowers/specs/2026-06-11-business-home-quick-links-design.md`.

**Architecture:** Extract a new reusable, hover-aware `WorkspaceQuickLinkPill` widget into its own file (mirroring the existing `WorkspaceActionCard` pattern), with a focused widget test. Then add a private `_QuickLinksSection` widget inside `single_business_workspace.dart` that assembles 5 of these pills in a `Wrap` under a `WorkspaceSectionHeader`, and insert that section into `_DesktopWorkspace`'s column. One new localization key (`bizQuickLinksLabel`) is added to both locales.

**Tech Stack:** Flutter/Dart, flutter_bloc (NavigationBloc), flutter_animate, solar_icons, flutter_localizations (gen-l10n).

**Hard constraint:** `_MobileWorkspace` in `lib/features/business/presentation/widgets/workspace/single_business_workspace.dart` must NOT be touched — no edits, not even whitespace.

---

### Task 1: Add `bizQuickLinksLabel` localization key (en + ar)

**Files:**
- Modify: `lib/l10n/app_en.arb:520`
- Modify: `lib/l10n/app_ar.arb:504`

- [ ] **Step 1: Add the English key**

In `lib/l10n/app_en.arb`, find line 520:

```json
  "bizManageLabel": "MANAGE",
```

Add a new key directly after it:

```json
  "bizManageLabel": "MANAGE",
  "bizQuickLinksLabel": "QUICK LINKS",
```

- [ ] **Step 2: Add the Arabic key**

In `lib/l10n/app_ar.arb`, find line 504:

```json
  "bizManageLabel": "الإدارة",
```

Add a new key directly after it:

```json
  "bizManageLabel": "الإدارة",
  "bizQuickLinksLabel": "روابط سريعة",
```

- [ ] **Step 3: Regenerate localization files**

Run:
```bash
flutter gen-l10n
```

Expected: command completes with no errors, and `lib/l10n/app_localizations_en.dart` and `lib/l10n/app_localizations_ar.dart` now each contain a `bizQuickLinksLabel` getter.

Verify:
```bash
grep -n "bizQuickLinksLabel" lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations.dart
```
Expected: a match in all three files.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ar.dart
git commit -m "feat(business): add bizQuickLinksLabel localization key"
```

---

### Task 2: Create `WorkspaceQuickLinkPill` widget (TDD)

**Files:**
- Create: `lib/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart`
- Test: `test/features/business/presentation/widgets/workspace/workspace_quick_link_pill_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/business/presentation/widgets/workspace/workspace_quick_link_pill_test.dart`:

```dart
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('WorkspaceQuickLinkPill renders icon and label', (tester) async {
    await tester.pumpWidget(wrap(WorkspaceQuickLinkPill(
      icon: SolarIconsOutline.layersMinimalistic,
      label: 'Categories',
      accentColor: AppColors.primary,
      onTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Categories'), findsOneWidget);
    expect(find.byIcon(SolarIconsOutline.layersMinimalistic), findsOneWidget);
  });

  testWidgets('WorkspaceQuickLinkPill calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(WorkspaceQuickLinkPill(
      icon: SolarIconsOutline.layersMinimalistic,
      label: 'Categories',
      accentColor: AppColors.primary,
      onTap: () => tapped = true,
    )));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(WorkspaceQuickLinkPill));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
flutter test test/features/business/presentation/widgets/workspace/workspace_quick_link_pill_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart'` (the file doesn't exist yet).

- [ ] **Step 3: Implement `WorkspaceQuickLinkPill`**

Create `lib/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart`:

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkspaceQuickLinkPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final int animDelay;
  final VoidCallback onTap;

  const WorkspaceQuickLinkPill({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    this.animDelay = 0,
    required this.onTap,
  });

  @override
  State<WorkspaceQuickLinkPill> createState() =>
      _WorkspaceQuickLinkPillState();
}

class _WorkspaceQuickLinkPillState extends State<WorkspaceQuickLinkPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = widget.accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(
              AppDims.s2,
              AppDims.s2,
              AppDims.s4,
              AppDims.s2,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? accent.withValues(alpha: isDark ? 0.10 : 0.06)
                  : colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _hovered
                    ? accent.withValues(alpha: 0.55)
                    : colors.border.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(widget.icon, color: accent, size: 14),
                ),
                const SizedBox(width: AppDims.s2),
                Text(
                  widget.label,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 320.ms,
          delay: Duration(milliseconds: widget.animDelay),
        )
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
flutter test test/features/business/presentation/widgets/workspace/workspace_quick_link_pill_test.dart
```

Expected: PASS — both tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart test/features/business/presentation/widgets/workspace/workspace_quick_link_pill_test.dart
git commit -m "feat(business): add WorkspaceQuickLinkPill widget"
```

---

### Task 3: Insert the Quick Links section into `_DesktopWorkspace`

**Files:**
- Modify: `lib/features/business/presentation/widgets/workspace/single_business_workspace.dart`

- [ ] **Step 1: Add new imports**

In `lib/features/business/presentation/widgets/workspace/single_business_workspace.dart`, the current imports (lines 1-20) are:

```dart
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/subscription_plan_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_action_card.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';
```

Add three new imports, keeping alphabetical-ish grouping with the existing `features/...` block. Replace the block from `import 'package:amana_pos/features/business/...workspace_action_card.dart';` through `import 'package:amana_pos/features/products/...product_bloc.dart';` with:

```dart
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_action_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
```

- [ ] **Step 2: Insert the Quick Links section into `_DesktopWorkspace.build()`**

In the same file, `_DesktopWorkspace.build()` currently ends its `Column.children` with:

```dart
            const SizedBox(height: AppDims.s3),
            _DesktopSubscriptionStrip(data: data)
                .animate()
                .fadeIn(duration: 350.ms, delay: 200.ms)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}
```

Replace that closing block with (adds the Quick Links section between the grid `Expanded` and the subscription strip):

```dart
            const SizedBox(height: AppDims.s3),
            const _QuickLinksSection(),
            const SizedBox(height: AppDims.s3),
            _DesktopSubscriptionStrip(data: data)
                .animate()
                .fadeIn(duration: 350.ms, delay: 200.ms)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop quick links section ───────────────────────────────────────────────

class _QuickLinksSection extends StatelessWidget {
  const _QuickLinksSection();

  @override
  Widget build(BuildContext context) {
    final navigationBloc = context.read<NavigationBloc>();
    final canAccessInventory =
        navigationBloc.state.permissions.canAccessInventory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceSectionHeader(title: context.tr.bizQuickLinksLabel),
        const SizedBox(height: AppDims.s3),
        Wrap(
          spacing: AppDims.s3,
          runSpacing: AppDims.s3,
          children: [
            WorkspaceQuickLinkPill(
              icon: SolarIconsOutline.layersMinimalistic,
              label: context.tr.settingsCategories,
              accentColor: AppColors.primary,
              animDelay: 300,
              onTap: () => navigationBloc.add(
                const NavigationFeatureSelected(AppFeature.categories),
              ),
            ),
            WorkspaceQuickLinkPill(
              icon: SolarIconsOutline.usersGroupTwoRounded,
              label: context.tr.settingsCustomers,
              accentColor: AppColors.info,
              animDelay: 360,
              onTap: () => navigationBloc.add(
                const NavigationFeatureSelected(AppFeature.customers),
              ),
            ),
            if (canAccessInventory)
              WorkspaceQuickLinkPill(
                icon: SolarIconsOutline.boxMinimalistic,
                label: context.tr.navInventory,
                accentColor: AppColors.warning,
                animDelay: 420,
                onTap: () => navigationBloc.add(
                  const NavigationFeatureSelected(AppFeature.inventory),
                ),
              ),
            WorkspaceQuickLinkPill(
              icon: SolarIconsOutline.roundArrowLeftUp,
              label: context.tr.settingsReturns,
              accentColor: AppColors.danger,
              animDelay: 480,
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteStrings.returnsScreen),
            ),
            WorkspaceQuickLinkPill(
              icon: SolarIconsOutline.settingsMinimalistic,
              label: context.tr.navSettings,
              accentColor: AppColors.slate400,
              animDelay: 540,
              onTap: () => Navigator.of(context)
                  .pushNamed(RouteStrings.settingsScreen),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify mobile is untouched**

Run:
```bash
git diff lib/features/business/presentation/widgets/workspace/single_business_workspace.dart | grep -A3 -B3 "_MobileWorkspace"
```

Expected: no output (no diff lines touching `_MobileWorkspace`).

- [ ] **Step 4: Static analysis**

Run:
```bash
flutter analyze lib/features/business/presentation/widgets/workspace/single_business_workspace.dart lib/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Run the full test suite**

Run:
```bash
flutter test
```

Expected: all tests pass (no regressions).

- [ ] **Step 6: Commit**

```bash
git add lib/features/business/presentation/widgets/workspace/single_business_workspace.dart
git commit -m "feat(business): add Quick Links section to desktop business home"
```

---

### Task 4: Manual verification

- [ ] **Step 1: Run the app on a desktop target**

```bash
flutter run -d macos
```

(Or `-d chrome` / `-d windows` / `-d linux`, whichever desktop target is configured.)

- [ ] **Step 2: Navigate to Business Home**

Sign in as an owner and open the Business tab (the screen showing the "Today" hero card and the Shops/Products/Cashiers/Reports 2×2 grid).

- [ ] **Step 3: Confirm the Quick Links section renders correctly**

- A "QUICK LINKS" header appears below the 2×2 grid, above the subscription strip.
- 5 pill chips are visible: Categories, Customers, Inventory, Returns, Settings — each with a colored circular icon badge and bold label.
- Hovering a pill highlights its border/background in the pill's accent color.
- Pills fade/slide in with a staggered delay continuing after the 2×2 grid's animation.

- [ ] **Step 4: Tap each pill and confirm navigation**

- **Categories** → switches the shell's main content to the Categories screen (nav rail highlight updates).
- **Customers** → switches to the Customers screen.
- **Inventory** → switches to the Inventory screen.
- **Returns** → pushes the Returns screen (back button returns to Business Home).
- **Settings** → pushes the Settings screen (back button returns to Business Home).

- [ ] **Step 5: Confirm Inventory pill is permission-gated**

For a business/account where `canAccessInventory` is `false` (e.g. a restaurant-type business), confirm:
- The Inventory pill is **not rendered**.
- The remaining 4 pills still wrap cleanly in the `Wrap`.

- [ ] **Step 6: Confirm mobile is unaffected**

Run on a mobile-sized window/device (`context.isDesktop == false`) and confirm the Business Home screen looks and behaves exactly as it did before this change — no Quick Links section, no layout shift.

- [ ] **Step 7: Confirm Arabic locale**

Switch the app language to Arabic and revisit Business Home — confirm the "روابط سريعة" header and pill labels render correctly in RTL layout.
