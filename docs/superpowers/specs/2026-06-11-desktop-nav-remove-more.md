# Desktop Navigation Rail — Remove "More" Overflow

**Date:** 2026-06-11
**Status:** Approved for planning

## Goal

The desktop navigation rail (`DesktopNavigationRail`) currently caps itself at
6 destinations and pushes anything beyond that into a slide-in "More" drawer
(`DesktopMoreDrawer`). There is plenty of vertical space in the rail to show
every permitted destination directly. Remove the cap, the "More" button, and
the drawer — all permitted feature tabs render directly in the rail at all
times.

## Non-goals

- Mobile is **not changed** — `DesktopNavigationRail`, `DesktopMoreDrawer`,
  and `DesktopShell` are desktop-only files with no mobile references.
- No scroll handling is added for the rail's destination list. The rail
  currently fits comfortably in normal desktop window heights with all 7
  possible tabs + Settings + Sell button; this is a deliberate "keep it
  simple" choice (confirmed during design).
- No changes to `_buildAllTabs`'s tab list, ordering, icons, or permission
  checks — only the cap/overflow mechanism is removed.
- No localization changes — the "More"/"MORE" strings being removed were
  hardcoded English literals, not l10n keys.

## Current State

`_kMaxRailDestinations = 6` is defined identically in both:
- `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`
- `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart`

`_buildAllTabs(context, perms)` (duplicated identically in both files) builds
up to 7 `NavTab`s in priority order: Business (Home), Products, Inventory,
Sales History, Categories, Customers, Users (Cashiers).

In `DesktopNavigationRail.build()`:
```dart
final railTabs = allTabs.take(_kMaxRailDestinations).toList();
final overflowTabs = allTabs.skip(_kMaxRailDestinations).toList();
```
`railTabs` feeds `NavigationRail.destinations` and `_activeRailIndex`.
`overflowTabs` (non-empty only for Owner accounts with all permissions, where
`allTabs.length == 7`) controls whether `_MoreButton` renders in `trailing`.

`_MoreButton` (private widget, `desktop_navigation_rail.dart:195-248`) calls
`Scaffold.of(context).openDrawer()` to open `DesktopMoreDrawer`.

`DesktopShell` (`desktop_shell.dart`) wires `drawer: const DesktopMoreDrawer()`
on its `Scaffold`. This is the only consumer of `DesktopMoreDrawer`.

`DesktopMoreDrawer` (`desktop_more_drawer.dart`, 312 lines) renders the
overflow tabs under a "MORE" section header, plus a footer. Nothing else in
the codebase references `DesktopMoreDrawer`, `_MoreButton`, or
`_kMaxRailDestinations`.

## Changes

### 1. `desktop_navigation_rail.dart`

- Delete the `_kMaxRailDestinations` constant and its doc comment.
- Replace the `railTabs`/`overflowTabs` split with a single list:
  ```dart
  final allTabs = _buildAllTabs(context, state.permissions);
  ```
  Use `allTabs` directly wherever `railTabs` was used (the `destinations:`
  list and `_activeRailIndex(allTabs, state.currentFeature)`).
- In `trailing`, delete the `if (overflowTabs.isNotEmpty) ...[ _MoreButton(...), SizedBox(...) ]` block entirely. `trailing` becomes:
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
- Delete the entire `_MoreButton` class (`desktop_navigation_rail.dart:195-248`,
  including its `// ── More button ──...` section comment).
- `_activeRailIndex`'s signature/body stay the same — only the argument
  passed to it changes (from `railTabs` to `allTabs`).

### 2. `desktop_shell.dart`

- Remove the `drawer: const DesktopMoreDrawer()` line from the `Scaffold`.
- Remove the now-unused import:
  `import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_more_drawer.dart';`

### 3. Delete `desktop_more_drawer.dart`

- Delete `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart`
  in its entirety (`DesktopMoreDrawer`, `_DrawerSection`, `_DrawerFeatureTile`,
  `_DrawerTile` — all private/unused elsewhere).

## Testing / Verification

- `flutter analyze` on the 2 modified files — expect `No issues found!`
  (confirms no dangling references to `DesktopMoreDrawer`, `_MoreButton`,
  `_kMaxRailDestinations`, or unused imports).
- `flutter test` — full suite, confirm no new regressions vs. baseline
  (existing 9 pre-existing failures unrelated to this area).
- Manual desktop run: sign in as an Owner (the only role that previously hit
  7 tabs / triggered "More"). Confirm:
  - All 7 destinations (Home, Products, Inventory, Sales History, Categories,
    Customers, Cashiers) render directly in the rail, in both collapsed and
    extended (`extended: true`) states.
  - No "More" button appears; the rail's `Scaffold` no longer has a drawer
    (swiping from the left edge / any drawer gesture does nothing).
  - Settings button and Sell FAB remain at the bottom of the rail, unchanged.
  - Tapping each of the 7 destinations switches `currentFeature` and
    highlights correctly (`_activeRailIndex` still works against the full
    `allTabs` list).
- Confirm mobile is unaffected (no diff touches mobile-only files; these
  classes have no mobile references to begin with).
