# Design: Enable/Disable Animations Setting (Low-End Device Support)

**Date:** 2026-06-14
**Status:** Approved (design); pending implementation plan
**Goal:** Let the app run smoothly on very low-end devices (≈1 GB RAM) by giving users a setting that disables animations across the app. When disabled, motion is removed entirely (instant), not merely shortened.

---

## Problem

The app uses ~209 animation references across ~95 files (route transitions, `AnimatedContainer`, `flutter_animate`, custom `AnimationController`s, looping effects). On a 1 GB-RAM device this motion costs frames and memory. There is currently **no** reduce-motion handling anywhere (`MediaQuery.disableAnimations` is unused).

We need a maintainable way to kill animations app-wide without scattering `if (enabled)` checks across 95 files.

## Decisions (locked)

| Decision                    | Choice                                                                                                       |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Default behavior            | **Auto-detect low RAM** (default off on low-end), with manual override                                       |
| Setting model               | **Tri-state selector**: Automatic / Always on / Always off (default = Automatic)                             |
| RAM threshold for "low-end" | **≤ 2 GB** total physical RAM                                                                                |
| Strictness when off         | **Kill everything (instant)** — transitions, decorative motion, and looping animations become instant/static |

## Non-Goals (YAGNI)

- Not migrating all 95 animation files in this pass. The central switch + global hooks + a handful of loud animations is the scope; the rest degrades gracefully and is swept incrementally.
- Not detecting CPU/GPU class — RAM only.
- Not exposing per-animation granularity to users.

---

## Architecture

### Central "Motion" switch (single source of truth)

Big apps use one motion flag readable from anywhere, **with or without `BuildContext`**. This app _requires_ a context-free flag because:

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

**Data flow is one-directional:** `ThemeBloc` owns the truth and pushes it into `Motion.animationsEnabled`. Everything else only _reads_ `Motion`. This is the layer that makes "kill everything instant" possible without per-call-site conditionals.

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

1. **Route transitions (biggest win).** In `AppRouter._buildRoute`: when `!Motion.on`, return a no-transition route (`PageRouteBuilder` with `transitionDuration: Duration.zero` and an identity `transitionsBuilder`; also skip the Cupertino swipe route). One edit covers every navigation.
2. **`flutter_animate` (49 call sites).** flutter_animate 4.5.2 exposes **no** global disable flag, and call sites use explicit durations (e.g. `.fadeIn(duration: 240.ms)`) that override `Animate.defaultDuration` — so there is no one-liner. Instead, add a drop-in extension `mAnimate()` (in the `motion` library) with the same signature as `animate()`. When `Motion.on` it delegates to `animate(...)` unchanged; when off it calls `animate(autoPlay: false, value: 1.0, ...)`, which renders the **end state** of the effect chain instantly (entrance effects like fadeIn/slideY resolve to the widget's natural appearance). Migrate the 49 `.animate(` call sites to `.mAnimate(` via mechanical find-replace plus an import. Because the wrapper is a true drop-in, this is one mechanical task, not 49.
3. **Manual `AnimationController`s + implicit animations.** Guard high-traffic ones with `Motion`. The looping `offline_hero` (1400 ms `repeat`) must be guarded explicitly — a `Duration.zero` repeat still spins, so when motion is off it must **not** start repeating and should rest centered (`_controller.value = 0.5`). The animated menu icon must `_ctrl.value = isOpen ? 1.0 : 0.0` (jump) instead of `forward()/reverse()` when motion is off.

Additionally: wrap the app root in `lib/app.dart`'s `builder` with a `MediaQuery` override forcing `disableAnimations: !Motion.on`. **Caveat (accurate):** `MediaQuery.disableAnimations` is only a passive _signal_ — `AnimationController` reads `SemanticsBinding`, not MediaQuery, and few framework widgets honor the flag. So this override is a low-cost "respect any framework widget that does check it" layer, **not** a global kill. The real kills are tiers 1–3.

**Scope honesty:** Tier 1 (routes) + Tier 2 (flutter_animate wrapper) land the bulk of the cost on day one. Tier 3 is a finite, enumerated set of widgets (offline hero, menu icon). Anything missed still works (it animates, just not instant) and can be swept later via the same `Motion.duration()` helper.

### Settings UI

In `lib/features/settings/presentation/settings_screen.dart` `_AppearanceSection` **and** the desktop two-pane view (`widgets/desktop_settings_view.dart`), add a tri-state selector below the theme picker, reusing the existing `BlocSelector<ThemeBloc, ThemeState>` + segmented-control pattern from `SettingsThemePicker`.

Options: **Automatic (based on device)**, **Always on**, **Always off**, with a one-line subtitle on Automatic such as _"Off on low-memory devices."_ New localization strings added to the `.arb` files for all supported locales.

---

## Components & Responsibilities

| Unit                                       | Responsibility                                                                       | Depends on                          |
| ------------------------------------------ | ------------------------------------------------------------------------------------ | ----------------------------------- |
| `Motion` (`lib/common/motion/motion.dart`) | Context-free global motion flag + `duration()` helper                                | nothing (leaf)                      |
| `DeviceMemoryProbe` (interface + impl)     | Report total physical RAM; mockable                                                  | `system_info_plus`                  |
| `ThemeBloc` (extended)                     | Own `AnimationPreference`, resolve to `animationsEnabled`, persist, push to `Motion` | `CacheStorage`, `DeviceMemoryProbe` |
| `ThemeState` (extended)                    | Carry `animationPreference` + resolved `animationsEnabled`                           | —                                   |
| `AppRouter._buildRoute` (edited)           | No-transition routes when `!Motion.on`                                               | `Motion`                            |
| `mAnimate()` extension (`motion` lib)      | Drop-in for `.animate()`; renders end-state instantly when `!Motion.on`              | `Motion`, `flutter_animate`         |
| Settings animation selector widget         | Render tri-state, dispatch event                                                     | `ThemeBloc`                         |
| `app.dart` builder (edited)                | `MediaQuery(disableAnimations: !Motion.on)` wrap                                     | `Motion`                            |
| Targeted widget migrations                 | Use `Motion.duration()` / guard loops                                                | `Motion`                            |

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
