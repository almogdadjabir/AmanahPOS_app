# Design: Enable/Disable Animations Setting (Low-End Device Support)

**Date:** 2026-06-14
**Status:** Approved (design); pending implementation plan
**Goal:** Let the app run smoothly on very low-end devices (≈1 GB RAM) by giving users a setting that disables animations across the app. When disabled, motion is removed entirely (instant), not merely shortened.

---

## Problem

The app uses ~209 animation references across ~95 files (route transitions, `AnimatedContainer`, `flutter_animate`, custom `AnimationController`s, looping effects). On a 1 GB-RAM device this motion costs frames and memory. There is currently **no** reduce-motion handling anywhere (`MediaQuery.disableAnimations` is unused).

We need a maintainable way to kill animations app-wide without scattering `if (enabled)` checks across 95 files.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Default behavior | **Auto-detect low RAM** (default off on low-end), with manual override |
| Setting model | **Tri-state selector**: Automatic / Always on / Always off (default = Automatic) |
| RAM threshold for "low-end" | **≤ 2 GB** total physical RAM |
| Strictness when off | **Kill everything (instant)** — transitions, decorative motion, and looping animations become instant/static |

## Non-Goals (YAGNI)

- Not migrating all 95 animation files in this pass. The central switch + global hooks + a handful of loud animations is the scope; the rest degrades gracefully and is swept incrementally.
- Not detecting CPU/GPU class — RAM only.
- Not exposing per-animation granularity to users.

---

## Architecture

### Central "Motion" switch (single source of truth)

Big apps use one motion flag readable from anywhere, **with or without `BuildContext`**. This app *requires* a context-free flag because:

- `lib/config/router/app_router.dart` is a `static` instance with no `BuildContext` and builds custom `PageRouteBuilder` routes (so a `PageTransitionsTheme` alone would not cover route transitions).
- `flutter_animate` `.animate()` calls and many widgets run without easy context access.

New file `lib/common/motion/motion.dart`:

```dart
class Motion {
  static final ValueNotifier<bool> animationsEnabled = ValueNotifier(true);
  static bool get on => animationsEnabled.value;
  static Duration duration(Duration full) => on ? full : Duration.zero;
}
```

**Data flow is one-directional:** `ThemeBloc` owns the truth and pushes it into `Motion.animationsEnabled`. Everything else only *reads* `Motion`. This is the layer that makes "kill everything instant" possible without per-call-site conditionals.

### Three states + RAM detection

`ThemeBloc` gains an enum `AnimationPreference { auto, alwaysOn, alwaysOff }`, persisted in `CacheStorage` under a new `Constants.animationPreference` key (default `auto`).

Resolution (run once at startup, inside the existing `_loadAccessibilitySettings`):

- `alwaysOn` → animations on
- `alwaysOff` → animations off
- `auto` → read total device RAM via the **`system_info_plus`** package (new dependency); **off if RAM ≤ 2 GB**, else on.

The RAM probe is placed behind a small injected interface (e.g. `DeviceMemoryProbe`) so it can be mocked in tests and so the native call never runs in unit tests. The resolved value may be cached to avoid re-querying every launch.

`ThemeState` gains:
- `AnimationPreference animationPreference`
- `bool animationsEnabled` (the resolved value)

On change, `ThemeBloc`: persists the preference, recomputes `animationsEnabled`, emits new state, and sets `Motion.animationsEnabled.value`.

### What gets disabled (the "instant" behavior)

Three tiers by cost/impact:

1. **Route transitions (biggest win).** In `AppRouter._buildRoute`: when `!Motion.on`, return a no-transition route (`PageRouteBuilder` with `transitionDuration: Duration.zero` and no `SlideTransition`; also skip the Cupertino swipe route). One edit covers every navigation.
2. **`flutter_animate` (49 files).** Set the package's global disable/duration hook once at startup from `Motion`, so `.animate().fadeIn()` etc. become instant app-wide without editing each call site. The exact global hook exposed by the installed `flutter_animate: ^4.5.2` will be confirmed during planning.
3. **Manual `AnimationController`s + implicit animations.** Migrate high-traffic ones to read `Motion.duration(...)`. The looping `offline_hero` (1400 ms `repeat`) must be guarded explicitly — a `Duration.zero` repeat still spins, so it should simply not start repeating when motion is off. Same for the animated menu icon and high-frequency `AnimatedContainer`s.

Additionally: wrap the app root in `lib/app.dart`'s `builder` with a `MediaQuery` override forcing `disableAnimations: !Motion.on`, so Flutter's own built-ins (Hero, default Material transitions, switches) respect the setting too — the OS-accessibility-equivalent layer.

**Scope honesty:** Tiers 1–2 plus the `MediaQuery` override land ~90% of the cost on day one. Tier 3 is a finite, enumerated set of widgets. Anything missed still works (it animates, just not instant) and can be swept later via the same `Motion.duration()` helper.

### Settings UI

In `lib/features/settings/presentation/settings_screen.dart` `_AppearanceSection` **and** the desktop two-pane view (`widgets/desktop_settings_view.dart`), add a tri-state selector below the theme picker, reusing the existing `BlocSelector<ThemeBloc, ThemeState>` + segmented-control pattern from `SettingsThemePicker`.

Options: **Automatic (based on device)**, **Always on**, **Always off**, with a one-line subtitle on Automatic such as *"Off on low-memory devices."* New localization strings added to the `.arb` files for all supported locales.

---

## Components & Responsibilities

| Unit | Responsibility | Depends on |
|---|---|---|
| `Motion` (`lib/common/motion/motion.dart`) | Context-free global motion flag + `duration()` helper | nothing (leaf) |
| `DeviceMemoryProbe` (interface + impl) | Report total physical RAM; mockable | `system_info_plus` |
| `ThemeBloc` (extended) | Own `AnimationPreference`, resolve to `animationsEnabled`, persist, push to `Motion` | `CacheStorage`, `DeviceMemoryProbe` |
| `ThemeState` (extended) | Carry `animationPreference` + resolved `animationsEnabled` | — |
| `AppRouter._buildRoute` (edited) | No-transition routes when `!Motion.on` | `Motion` |
| `flutter_animate` global hook (startup) | Disable package animations when `!Motion.on` | `Motion` |
| Settings animation selector widget | Render tri-state, dispatch event | `ThemeBloc` |
| `app.dart` builder (edited) | `MediaQuery(disableAnimations: !Motion.on)` wrap | `Motion` |
| Targeted widget migrations | Use `Motion.duration()` / guard loops | `Motion` |

---

## Error Handling

- **RAM probe failure / unsupported platform:** if `system_info_plus` throws or returns null, treat as "not low-end" (animations on) so the app never errors out, and log once. Conservative default avoids accidentally degrading high-end devices.
- **Missing/corrupt persisted preference:** fall back to `auto`.
- **Desktop:** RAM detection still resolves, but desktop is not the target; `auto` on desktop will generally resolve to "on" given typical RAM.

## Testing

- **Unit (`ThemeBloc`):** each `AnimationPreference` resolves correctly; `auto` flips at the 2 GB boundary (mock `DeviceMemoryProbe` at 2 GB / just under / just over); `Motion.animationsEnabled` updates on every transition; probe failure resolves to "on".
- **Widget (settings selector):** renders three options, reflects current state, dispatches the correct event on tap.
- No real native RAM call in tests (probe is injected/mocked).

## Persistence

- New `Constants.animationPreference` string key in `lib/config/constants.dart`, stored via `CacheStorage` (SharedPreferences-backed), consistent with existing `appTheme` / `isDarkTheme` keys.

## New Dependency

- `system_info_plus` (cross-platform total physical RAM: Android `ActivityManager.totalMem`, iOS `ProcessInfo.physicalMemory`). Exact version pinned during planning.

---

## Rollout / Order of Implementation (high level)

1. `Motion` + `DeviceMemoryProbe` + dependency.
2. Extend `ThemeBloc` / `ThemeState` / `Constants`; wire `Motion` updates; unit tests.
3. Route transitions (`_buildRoute`) + `app.dart` `MediaQuery` override.
4. `flutter_animate` global hook.
5. Settings UI (mobile + desktop) + localization; widget test.
6. Targeted Tier-3 widget migrations (offline hero loop, menu icon, hot `AnimatedContainer`s).
