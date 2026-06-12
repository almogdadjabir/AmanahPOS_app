# Desktop Navigation Rail — Remove "More" Overflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the desktop navigation rail's 6-destination cap and "More" slide-in drawer so that all permitted feature tabs (up to 7: Home, Products, Inventory, Sales History, Categories, Customers, Cashiers) render directly in `DesktopNavigationRail`, exactly as specified in `docs/superpowers/specs/2026-06-11-desktop-nav-remove-more.md`.

**Architecture:** Remove the `_kMaxRailDestinations` cap and the `railTabs`/`overflowTabs` split in `DesktopNavigationRail`, using the full `allTabs` list directly for both `destinations` and `_activeRailIndex`. Delete the now-unused `_MoreButton` widget. Remove the `drawer: const DesktopMoreDrawer()` wiring (and its import) from `DesktopShell`, then delete the now fully-unused `desktop_more_drawer.dart` file.

**Tech Stack:** Flutter/Dart, flutter_bloc (NavigationBloc), NavigationRail (Material).

**Hard constraint:** Mobile is unaffected — `DesktopNavigationRail`, `DesktopShell`, and `DesktopMoreDrawer` are desktop-only files with zero mobile references (verified via `grep` during design).

---

### Task 1: Remove the "More" cap, button, and drawer

**Files:**
- Modify: `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`
- Modify: `lib/features/main_screen/presentation/widgets/desktop_shell.dart`
- Delete: `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart`

- [ ] **Step 1: Remove the `_kMaxRailDestinations` constant**

In `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`, delete these lines (currently lines 14-16):

```dart
// Maximum destinations shown directly in the rail.
// Anything beyond this limit moves to the More drawer.
const _kMaxRailDestinations = 6;
```

- [ ] **Step 2: Use `allTabs` directly instead of splitting into `railTabs`/`overflowTabs`**

In the same file, inside `DesktopNavigationRail.build()`, find:

```dart
        final allTabs = _buildAllTabs(context, state.permissions);

        // Split: first N go in the rail, rest go to the More drawer.
        final railTabs = allTabs.take(_kMaxRailDestinations).toList();
        final overflowTabs = allTabs.skip(_kMaxRailDestinations).toList();

        final isPosActive = state.currentFeature == AppFeature.pos;
        final activeIdx = _activeRailIndex(railTabs, state.currentFeature);
        final colors = context.appColors;
```

Replace with:

```dart
        final allTabs = _buildAllTabs(context, state.permissions);

        final isPosActive = state.currentFeature == AppFeature.pos;
        final activeIdx = _activeRailIndex(allTabs, state.currentFeature);
        final colors = context.appColors;
```

- [ ] **Step 3: Update `onDestinationSelected` to index into `allTabs`**

In the same file, find:

```dart
          onDestinationSelected: (i) {
            final feature = railTabs[i].feature;
            if (feature != null) {
              context
                  .read<NavigationBloc>()
                  .add(NavigationFeatureSelected(feature));
            }
          },
```

Replace with:

```dart
          onDestinationSelected: (i) {
            final feature = allTabs[i].feature;
            if (feature != null) {
              context
                  .read<NavigationBloc>()
                  .add(NavigationFeatureSelected(feature));
            }
          },
```

- [ ] **Step 4: Remove the `_MoreButton` block from `trailing`**

In the same file, find:

```dart
          trailing: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Overflow features (only present once permitted tabs exceed
                // _kMaxRailDestinations).
                if (overflowTabs.isNotEmpty) ...[
                  _MoreButton(
                    extended: extended,
                    isOverflowActive: overflowTabs.any(
                      (t) => t.feature == state.currentFeature,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                _SettingsButton(extended: extended),
                const SizedBox(height: AppSpacing.md),
                _SellFab(
                  isActive: isPosActive,
                  extended: extended,
                  label: context.tr.navSell,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
```

Replace with:

```dart
          trailing: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SettingsButton(extended: extended),
                const SizedBox(height: AppSpacing.md),
                _SellFab(
                  isActive: isPosActive,
                  extended: extended,
                  label: context.tr.navSell,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
```

- [ ] **Step 5: Update `destinations` to iterate over `allTabs`**

In the same file, find:

```dart
          destinations: [
            for (final tab in railTabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: Text(tab.label),
              ),
          ],
```

Replace with:

```dart
          destinations: [
            for (final tab in allTabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: Text(tab.label),
              ),
          ],
```

- [ ] **Step 6: Rename `_activeRailIndex`'s parameter from `railTabs` to `tabs`**

In the same file, find:

```dart
  static int? _activeRailIndex(List<NavTab> railTabs, AppFeature? currentFeature) {
    if (currentFeature == AppFeature.pos) return null;
    for (int i = 0; i < railTabs.length; i++) {
      if (railTabs[i].feature == currentFeature) return i;
    }
    return null;
  }
```

Replace with:

```dart
  static int? _activeRailIndex(List<NavTab> tabs, AppFeature? currentFeature) {
    if (currentFeature == AppFeature.pos) return null;
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].feature == currentFeature) return i;
    }
    return null;
  }
```

- [ ] **Step 7: Delete the `_MoreButton` class**

In the same file, delete the entire section from the `// ── More button ──...` comment through the end of the `_MoreButton` class (currently lines 193-248):

```dart
// ── More button ───────────────────────────────────────────────────────────────

class _MoreButton extends StatelessWidget {
  final bool extended;
  final bool isOverflowActive;

  const _MoreButton({required this.extended, required this.isOverflowActive});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: extended ? 200 : 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isOverflowActive
              ? colors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.menuDots,
              size: 22,
              color: isOverflowActive ? colors.primary : colors.textSecondary,
            ),
            if (extended) ...[
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'More',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverflowActive
                        ? colors.primary
                        : colors.textSecondary,
                  ),
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

(Leave the `// ── Settings button ──...` section comment and `_SettingsButton` class that follow it untouched.)

- [ ] **Step 8: Remove the `DesktopMoreDrawer` import and `drawer:` wiring from `DesktopShell`**

In `lib/features/main_screen/presentation/widgets/desktop_shell.dart`, find:

```dart
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_more_drawer.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_navigation_rail.dart';
```

Replace with:

```dart
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_navigation_rail.dart';
```

Then find:

```dart
    return Scaffold(
      backgroundColor: colors.background,
      drawer: const DesktopMoreDrawer(),
      body: Row(
```

Replace with:

```dart
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
```

- [ ] **Step 9: Delete `desktop_more_drawer.dart`**

```bash
rm lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart
```

- [ ] **Step 10: Static analysis**

Run:
```bash
flutter analyze lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart lib/features/main_screen/presentation/widgets/desktop_shell.dart
```

Expected: `No issues found!`

- [ ] **Step 11: Confirm no dangling references to removed symbols**

Run:
```bash
grep -rn "DesktopMoreDrawer\|_MoreButton\|_kMaxRailDestinations\|railTabs\|overflowTabs" lib/
```

Expected: no output.

- [ ] **Step 12: Run the full test suite**

Run:
```bash
flutter test
```

Expected: same pass/fail counts as the pre-existing baseline (71 passed, 9 failed — the 9 are pre-existing failures unrelated to this area), no new regressions.

- [ ] **Step 13: Commit**

```bash
git add lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart lib/features/main_screen/presentation/widgets/desktop_shell.dart lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart
git commit -m "feat(nav): remove desktop nav rail 'More' overflow, show all tabs"
```

---

### Task 2: Manual verification

- [ ] **Step 1: Run the app on a desktop target**

```bash
flutter run -d macos
```

(Or `-d chrome` / `-d windows` / `-d linux`, whichever desktop target is configured.)

- [ ] **Step 2: Sign in as an Owner of a shop-type business**

This is the only role/business-type combination that previously produced 7 tabs (the case that triggered "More").

- [ ] **Step 3: Confirm all 7 destinations render directly in the rail**

In both collapsed (`extended: false`, default) and extended (toggle the hamburger in the top bar) states, confirm the rail shows, top to bottom: Home, Products, Inventory, Sales History, Categories, Customers, Cashiers — followed by Settings and the Sell button at the bottom. No "More" item appears.

- [ ] **Step 4: Confirm the drawer is gone**

Attempt to open a left-edge drawer (e.g. swipe gesture or any prior "More" affordance) — nothing should open. The `Scaffold` no longer has a `drawer`.

- [ ] **Step 5: Confirm tab selection still works**

Tap each of the 7 destinations (Home, Products, Inventory, Sales History, Categories, Customers, Cashiers) and confirm the rail highlights the correct destination and the main content area switches to match.

- [ ] **Step 6: Confirm a non-owner role is visually unchanged**

Sign in as a Cashier (max 5 tabs) and confirm the rail looks the same as before this change (it never showed "More").
