# AmanaPOS mobile — UI revamp audit

Date: 2026-11-14. Scope: visual layer only (theme, shared widgets, screens). Business logic, blocs, repositories, routing and data stay untouched.

Goal: the mobile app, the web dashboard and the landing page look like **one brand** — the dashboard's "Nile Ledger" colours, the same press feel, the same Apple-standard calm (sentence case, generous spacing, one surface language, purposeful motion).

---

## 1. What exists today

| Area | Where | Notes |
|---|---|---|
| Raw palette | `lib/theme/app_colors.dart` | Tailwind slate + emerald `#0F766E` + amber `#F59E0B`, blue `#2563EB` for card payments. |
| Semantic tokens | `lib/theme/app_theme_colors.dart` | `ThemeExtension` with 29 fields, read via `context.appColors.x`. **Good foundation — keep the field names.** |
| ThemeData | `lib/theme/app_theme.dart` (528 lines) | Material 3, light + dark built from `_lightColors` / `_darkColors`. Dark values are hardcoded hex in here. |
| Type | `lib/theme/app_text_styles.dart` | `fontFamily: 'NunitoSans'` — **the font is not bundled** (no `fonts:` in `pubspec.yaml`, no TTF in the repo), so every screen silently falls back to the platform font. |
| Spacing / radius | `lib/theme/app_spacing.dart` | Two parallel scales: `AppSpacing/AppRadius` (53 uses) and `AppDims` (2,616 uses). UI-REVIEW UI-13 already flags this. |
| Buttons | `lib/widgets/app_button.dart` | Material + `InkWell` ripple, radius 12, no press-scale, `secondary` = amber. Feature-local copies: `PrimarySheetButton`, `PaymentButton`, `QtyButton`, submit buttons (UI-08). |
| Motion | `lib/common/motion/*` | `Motion.on` switch (user setting + low-RAM auto-off) and `.mAnimate()` wrapper over flutter_animate. **Good — every new animation must go through this.** 124 `mAnimate` uses, 17 raw `.animate(` that bypass the switch. |
| Responsive | `lib/core/responsive/*`, `docs/DESKTOP_HANDOFF.md` | `context.isDesktop`, adaptive sheet (bottom sheet on phone, side drawer on desktop). Desktop variants exist (`desktop_*` widgets). |
| Prior review | `UI-REVIEW.md` | 27 findings (duplicate sheets, error/empty views, shimmers, search bars, section headers, hardcoded strings). Still valid — fold them into this revamp. |

## 2. Measured drift (outside `lib/theme/`)

| Pattern | Count | Why it matters |
|---|---|---|
| `Color(0x…)` literals | **350 in 80 files** | Won't follow the new palette or dark mode. Worst: `stock_action_sheet.dart` (24), `sales_report_colors.dart` (22), `desktop_product_detail_drawer.dart` (15), `desktop_user_detail_drawer.dart` (14), `user_detail_screen.dart` (11), `feature_menu_sections.dart` (10), `premium_colors.dart` (9), POS product cards (8 each). |
| `Colors.black / Colors.white` | 272 | Hard black/white is the "black block in dark mode" problem. |
| `AppColors.*` used directly | 224 | Bypasses the theme extension → ignores dark mode. |
| Raw `fontSize:` | 137 | Off the type scale. |
| `BoxShadow(` | 87 | Mixed shadow styles; dashboard uses hairline + soft lift in light, **no shadows in dark**. |
| `…Gradient(` | 51 | Decorative gradients; dashboard allows one (the teal hero tile). |
| `InkWell(` / `GestureDetector(` | 112 / 77 | Android ripple everywhere; no shared press-scale feel. |
| `Icons.*` vs `SolarIcons` | 231 / 683 | Two icon families (UI-14). |
| `.toUpperCase()` | 35 | ALL-CAPS labels; target is sentence case. |
| Raw `.animate(` | 17 | Ignores the user's "animations off" setting. |

## 3. Gap vs. the dashboard ("Nile Ledger")

| Topic | Mobile today | Target (dashboard) |
|---|---|---|
| Light background | slate-50 `#F8FAFC` (cool blue-grey) | warm paper `#F6F4EF` |
| Dark background | slate-950 `#020617` (near-black) + `#0B1220` | deep green-grey `#0B1211` / surface `#121B1A` — **never black** |
| Brand (dark) | `#2DD4BF` | `#4CC2B0` |
| Secondary | amber accent used for decoration | no decorative amber; amber = **cash** only |
| Card / Bankak | blue `#2563EB` | **digital** indigo `#5B55D6` (dark `#8E89F2`) |
| Status reds/greens | Tailwind red-600 / green-600 | `danger #B3261E`, `ok #0E6B4E` (+ tints) |
| Surfaces | white cards with shadows | `surface` cards; widgets on `surface-muted`, radius 24, hairline instead of shadow |
| Highlight tile | various gradients | one hero: teal gradient (light) / `#1F3D39 → brand-tint` (dark) |
| Font | NunitoSans (not loaded) | Geist + IBM Plex Sans Arabic |
| Labels | some ALL CAPS | sentence case |
| Buttons | ripple, radius 12 | pill/rounded 12–14, **press scale .97**, 120ms, no ripple; text buttons for row actions |
| Segmented controls | Material chips/toggles | sliding thumb (Apple sheet curve `cubic(.32,.72,0,1)`) |
| Sheets | two scaffolds (UI-05) | one sheet: grabber, 24 radius, title row with text "Done/Cancel" |
| Numbers | mixed | tabular figures, LTR-isolated in Arabic |

## 4. Token map (keep `AppThemeColors` field names → zero call-site churn)

| Field | Light | Dark |
|---|---|---|
| background | `#F6F4EF` | `#0B1211` |
| surface | `#FFFFFF` | `#121B1A` |
| surfaceSoft (= surface-muted) | `#EEEBE4` | `#1B2725` |
| border (= line) | `#E5E1D8` | `#24312F` |
| textPrimary (ink) | `#1C1A17` | `#EEF1EF` |
| textSecondary (ink-2) | `#58534A` | `#A7B3AF` |
| textHint (ink-3) | `#716B60` | `#7F8D89` |
| disabled (line-strong) | `#958E80` | `#5C6E6A` |
| primary (brand) | `#0F766E` | `#4CC2B0` |
| primaryContainer (brand-tint) | `#E8F5F2` | `#1A312E` |
| onPrimary | `#FFFFFF` | `#04201D` |
| secondary → cash | `#B7791F` | `#E8B04A` |
| secondaryContainer → cash-tint | `#FBF1DC` | `#2B220F` |
| onSecondary → cash-ink | `#7A4E05` | `#F2C46B` |
| success (ok) / container | `#0E6B4E` / `#E5F3EB` | `#5FCB98` / `#12291F` |
| danger / container | `#B3261E` / `#FBE9E7` | `#F2827A` / `#2E1614` |
| warning (warn) / container | `#9A4508` / `#FCEDE0` | `#F0A060` / `#2E1D10` |
| info / container | `#2D5B88` / `#E7EEF6` | `#8DB4DD` / `#15212E` |
| sale | = primary | = primary |
| refund | = danger | = danger |
| cash | `#B7791F` | `#E8B04A` |
| card → digital (Bankak) | `#5B55D6` | `#8E89F2` |
| stockLow | = warning | = warning |
| profit | = success | = success |
| shadow | `#1C1A17` @ 8% | transparent (no shadows in dark) |

**New fields to add:** `surfaceRaised` (`#FFFFFF` / `#182322`), `borderStrong` (`#958E80` / `#5C6E6A`), `primaryStrong` (`#0B5D56` / `#6FD3C3`), `digitalTint` (`#EEEEFC` / `#1E1D3A`), `digitalInk` (`#3730A3` / `#B4B1FA`), `cashTint`, `cashInk`, `premium` (`#A8822F` / `#E7C273`) + `premiumTint` (`#FBF3E1` / `#2E2408`), `chartTrack` (brand @ 14%), `heroGradient` (light `#0F766E → #0B5D56`, dark `#1F3D39 → #1A312E`), `heroInk` (white / ink).

Radii: 6 / 8 / 12 / 16 / 24 / pill. Motion: fast 120ms, base 180ms, slow 280ms; curves `ease (.2,0,0,1)`, `soft (.16,1,.3,1)`, `sheet (.32,.72,0,1)`; press scale .97.

## 5. Suggested screen order (by daily use)

1. Foundation: tokens, ThemeData, type, `AppButton` + press feel, sheet, segmented, list rows, empty/error/skeleton (also closes UI-01…UI-13).
2. POS / Sell (`pos`, `cart`) — the screen cashiers live in.
3. Main shell (`main_screen`: bottom nav + Sell FAB, app bar, search).
4. Login, registration, PIN, splash.
5. Dashboard (home widgets — match the web dashboard widgets 1:1).
6. Products + categories.
7. Inventory (incl. premium).
8. Sales history + reports + returns.
9. Customers, users, devices.
10. Settings, business, notifications, sync, feature menu.
11. Desktop variants (`desktop_*`) pass.
