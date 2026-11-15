# AmanaPOS mobile — UI revamp to the Nile Ledger design system (UI only)

You are in `/Users/almogdadjabir/StudioProjects/amana_pos` (Flutter, BLoC, GetIt).
Read first, in this order: `docs/ui-revamp/AUDIT.md` (the audit — your main brief), `docs/conventions.md`, `docs/README.md`, `docs/DESKTOP_HANDOFF.md`, `UI-REVIEW.md` (findings UI-01…UI-27 to fold in).

## Goal
Make the app look and feel like the same brand as the AmanaPOS web dashboard and landing page: the dashboard's "Nile Ledger" colours, the same press feel on buttons, Apple-standard calm (sentence case, generous spacing, one surface language, purposeful motion), light + dark, English + Arabic (RTL). **Same flows, same usability, same features — only the visuals change.**

## The working loop (most important rule)
**HTML first, real app second — for everything, including the foundation.**

1. Build an **HTML sample** of the next step (see "Order" below). Standalone single file, inline CSS + JS, phone frame 390×844 (plus a 1280px desktop frame when the screen has a `desktop_*` variant), toggles for **light / dark / Arabic RTL**, real strings from `lib/l10n/app_en.arb` / `app_ar.arb`, real-looking data. Show the current screen's structure — same sections, same actions, same flow — only restyled.
2. Screenshot it yourself (headless Chrome/Playwright if available) in light, dark and Arabic, fix anything off, then give me the **full absolute path**.
3. **Stop and wait.**
   - If I ask for changes → change **only the HTML**, re-screenshot, send the path again, wait again. Repeat until I approve.
   - When I say **"approve"** → implement exactly that in Flutter. Don't add things the sample didn't show.
4. After implementing: run the checks (below), give a short report, propose the next step, and **stop**.

Never edit Dart code for a step whose HTML hasn't been approved.

## Order
0. **Design system sample** — one HTML page showing: colour tokens (light/dark swatches), type scale (EN + AR), `AppButton` variants and sizes with the press effect, pressable card + grouped list rows, sliding segmented control, text field, chips/badges, bottom sheet (open/close animation), confirm sheet, empty / error / skeleton states, a stat tile + the teal hero tile, a small bar chart + ring. After approval, implement it as the Flutter foundation (tokens, ThemeData, type, shared widgets) — no screen changes yet.
1. POS / Sell + cart (incl. payment + success)
2. Main shell — bottom nav + Sell FAB, app bar, search
3. Login, registration, PIN, splash
4. Dashboard / home widgets (match the web dashboard widgets)
5. Products + categories
6. Inventory (incl. premium)
7. Sales history, reports, returns
8. Customers, users, devices
9. Settings, business, notifications, sync, feature menu
10. Desktop variants pass

## Hard rules
- **UI only.** Do not touch blocs, events, states, repositories, use cases, services, DI, routing logic, API/DB code, or any behaviour. If a visual change seems to need a logic change, stop and ask me.
- Keep widget public APIs (constructor params, callbacks) the same so call sites keep compiling. Keep the `AppThemeColors` field names; change values and add new fields (token map in the audit, section 4).
- Every colour comes from `context.appColors.*`. No `Color(0x…)`, `Colors.black/white`, or direct `AppColors.*` in feature code after a screen is done. Hex only in `lib/theme/`.
- **Dark mode is never black**: background `#0B1211`, surfaces `#121B1A` / `#1B2725`. No shadows in dark — hairline borders instead.
- Amber is only for **cash**; Bankak/card is **digital indigo**. No decorative amber, no decorative gradients — the only gradient is the teal hero tile.
- Sentence case everywhere (remove `.toUpperCase()` labels). Numbers use tabular figures and stay LTR inside Arabic text.
- Directional layout with `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`. Directional icons mirror in RTL.
- Every animation goes through `Motion` / `.mAnimate()` (respects the user's "animations off" + low-RAM auto). Replace the 17 raw `.animate(` calls as you reach them.
- No new packages. Fonts are assets, not packages — **ask me before adding font files** (target: Geist + IBM Plex Sans Arabic, OFL, from the official Google Fonts repos). If I decline, use the platform font (SF on iOS, Roboto on Android) and delete the dead `NunitoSans` reference. The HTML samples should use the same fonts we'll ship.
- Follow `docs/conventions.md` (header comments, no verbose AI comments, `buildWhen`, private `_Widget` classes in the same file).
- **Git:** `development` has staged launcher-icon changes and 24 unpushed commits — ask me how to handle them, then create `feat/ui-revamp-nile-ledger` from `development`. Never commit to `main`/`development`. Don't commit, push or open a PR unless I ask.

## The feel (match the dashboard)
- **Buttons:** primary = filled brand, radius 12 (pill for compact actions), 48/56 heights, **press scale 0.97 over 120ms with ease (.2,0,0,1), no ripple**, loading spinner inside, disabled = 40% opacity. Variants: primary, secondary (surface-muted fill, ink text), outline (hairline), ghost/text, danger, link (text-only row action). One `AppButton` — merge `PrimarySheetButton` and feature submit buttons into it (UI-08/09).
- **Press feel everywhere:** one shared `Pressable` widget (scale + subtle opacity, haptic `selectionClick` on toggles) replacing bare `InkWell`/`GestureDetector` on tappable cards, rows and tiles.
- **Surfaces:** page `background`; cards `surface`, radius 16; widgets/stat tiles on `surfaceSoft`, radius 24; hairline `border` instead of shadows. Soft, low shadow only for floating things (sheets, FAB) in light mode.
- **Hero tile:** teal gradient (light) / `#1F3D39 → #1A312E` (dark) with `heroInk` text — at most once per screen.
- **Segmented controls:** sliding thumb, Apple sheet curve `Cubic(.32,.72,0,1)`, 260ms.
- **Sheets:** one shared sheet (merge `AppBottomSheet` + `ProductSheetShell`, UI-05): grabber, radius 24, title row with text actions ("Cancel"/"Done"), keyboard-safe. Destructive confirms use one shared confirm sheet (UI-01).
- **Lists:** inset grouped rows like iOS Settings (rounded group, hairline separators inset past the icon, chevron at end, tinted 30px icon tiles).
- **Empty / error / skeleton:** one shared widget each (UI-02/03/04), calm copy, one action.
- **Charts:** match the web widgets — teal bars with dimmed non-peak bars, `chartTrack` tracks, rounded caps, ring with a round cap that sweeps in, big readout number that changes when you scrub.
- **Motion:** sheet curve for sheets/drawers, soft fades + 8–12px rises on content load (staggered 40ms, only the first ~8 list items), count-ups on totals, cart line insert/remove with size+fade, a payment-success check that draws in. Nothing loops idly.

## Checks after each Flutter implementation
- `flutter analyze` clean, `flutter test` green. Update widget-test finders only where text/structure changed visually — never weaken logic assertions.
- Grep proves the finished screen has no `Color(0x`, `Colors.black/white`, `AppColors.`, `toUpperCase()`, raw `.animate(`.
- Add a golden test (light / dark / ar) for the screen's main widget where practical, or run on a simulator and screenshot. Compare against the approved HTML and list any differences.
- Report: what changed, what I should look at, anything not verified.

## Token use
Keep messages short. Read only the files for the step you're on — don't load the whole `lib/` tree.

## Start now
Ask me the two questions (git state, fonts). Then build the **step 0 design system HTML sample**, send me its path, and stop.
