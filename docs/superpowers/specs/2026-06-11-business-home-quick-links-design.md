# Desktop Business Home — Quick Links

**Date:** 2026-06-11
**Status:** Approved for planning

## Goal

Turn the desktop "Business Home" (`SingleBusinessWorkspace` →
`_DesktopWorkspace`, the screen shown for `AppFeature.business`) into a real
entry point that reaches every owner-facing area, not just the current four
(Shops, Products, Cashiers, Reports). Add a "Quick Links" row giving
one-click access to Categories, Customers, Inventory, Returns, and Settings,
styled to match the existing premium look (hover-aware cards, soft borders,
fade/slide-in animations).

## Non-goals

- Mobile (`_MobileWorkspace`) is **not changed** — visually or functionally.
- The existing hero "Today" card, 2×2 primary module grid, and subscription
  strip are not restructured — Quick Links is purely additive, inserted
  between the grid row and the subscription strip.
- No new permissions — every link uses an existing permission/route that's
  already reachable elsewhere (nav rail, more drawer, settings).

## 1. Placement & Composition

`_DesktopWorkspace.build()` column becomes:

1. *(unchanged)* `Expanded` row: hero "Today" card + `_DesktopModuleGrid`
2. **NEW**: `SizedBox(height: AppDims.s3)` + Quick Links section
3. *(unchanged)* `SizedBox(height: AppDims.s3)` + `_DesktopSubscriptionStrip`

The Quick Links section is a `Column` with:
- `WorkspaceSectionHeader(title: context.tr.bizQuickLinksLabel)` (reuse the
  existing widget — same one used in mobile's "MANAGE" header and Sales
  History's date group headers).
- `SizedBox(height: AppDims.s3)`
- A `Wrap` of `_QuickLinkPill` widgets (`spacing: AppDims.s3`,
  `runSpacing: AppDims.s3`) so chips reflow if the window is narrow rather
  than overflowing.

## 2. Quick Link Pills

New widget `_QuickLinkPill` (private to `single_business_workspace.dart`,
co-located near `_DesktopModuleCard` since it's desktop-only and small):

- Stateful (hover tracking via `MouseRegion`, like `_DesktopModuleCard` /
  `DesktopManageTile`).
- Shape: fully rounded pill (`BorderRadius.circular(999)`), border +
  background following the same hover pattern as `DesktopManageTile`
  (`colors.surface` / accent-tinted on hover, `colors.border` /
  accent-tinted border).
- Content: `Row` — 28px circular icon badge (accent-tinted background +
  border, icon centered) + `SizedBox(width: AppDims.s2)` + label
  (`AppTextStyles.bs200`, `fontWeight: w800`).
- Padding: `EdgeInsets.fromLTRB(AppDims.s2, AppDims.s2, AppDims.s4, AppDims.s2)`
  (tighter on the icon side, like the mockup's "icon hugs the edge" look).
- Animation: same `fadeIn` + `slideY` entrance as the existing module cards,
  staggered `animDelay` continuing the sequence (300, 360, 420, 480, 540ms).

### Pill definitions (in order)

| Label (l10n key) | Icon | Accent | `onTap` |
|---|---|---|---|
| `context.tr.settingsCategories` | `SolarIconsOutline.layersMinimalistic` | `AppColors.primary` | `context.read<NavigationBloc>().add(const NavigationFeatureSelected(AppFeature.categories))` |
| `context.tr.settingsCustomers` | `SolarIconsOutline.usersGroupTwoRounded` | `AppColors.info` | `context.read<NavigationBloc>().add(const NavigationFeatureSelected(AppFeature.customers))` |
| `context.tr.navInventory` | `SolarIconsOutline.boxMinimalistic` | `AppColors.warning` | `context.read<NavigationBloc>().add(const NavigationFeatureSelected(AppFeature.inventory))` — **only included when `context.read<NavigationBloc>().state.permissions.canAccessInventory`** |
| `context.tr.settingsReturns` | `SolarIconsOutline.roundArrowLeftUp` | `AppColors.danger` | `Navigator.of(context).pushNamed(RouteStrings.returnsScreen)` |
| `context.tr.navSettings` | `SolarIconsOutline.settingsMinimalistic` | `AppColors.slate400` | `Navigator.of(context).pushNamed(RouteStrings.settingsScreen)` |

Note on navigation: unlike `selectMainFeature()` (used from drawers/sheets,
which also calls `Navigator.pop()` to dismiss the container), these pills
dispatch `NavigationFeatureSelected` directly — `_DesktopWorkspace` is the
shell's body content, not something pushed/dismissible, so no pop is needed.

## 3. Imports needed

`single_business_workspace.dart` will need new imports:
- `package:amana_pos/features/main_screen/data/app_feature.dart`
- `package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart`
- `package:amana_pos/widgets/workspace_section_header.dart` (already imported)

`AppColors` is already imported.

## 4. Localization

Add one new key to `app_en.arb` and `app_ar.arb`:

```json
"bizQuickLinksLabel": "QUICK LINKS"
```//ar: "روابط سريعة" (or equivalent — final wording owned by translator review)

All other labels reuse existing keys (`settingsCategories`,
`settingsCustomers`, `navInventory`, `settingsReturns`, `navSettings`),
already present in both locale files.

## 5. Testing / Verification

- Manual desktop run: confirm the row renders below the 2×2 grid, above the
  subscription strip, with correct icons/colors/hover states.
- Tap each pill:
  - Categories / Customers / Inventory → switches the shell's main content
    via `NavigationBloc` (rail highlight updates accordingly).
  - Returns / Settings → pushes the existing routed screens.
- Toggle a restaurant-type business (or mock `canAccessInventory == false`)
  and confirm the Inventory pill is omitted and the `Wrap` reflows cleanly
  with 4 chips.
- Confirm mobile (`_MobileWorkspace`) is pixel-identical to before (no diff
  in that class).
