# Disable-Animations Setting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tri-state "Animations" setting (Automatic / Always on / Always off) that, on low-RAM devices, defaults to off and removes animations across the app instantly.

**Architecture:** A single context-free `Motion` switch (a `ValueNotifier<bool>`) is the source of truth that the router, a `flutter_animate` wrapper, and individual widgets read. `ThemeBloc` owns the user's `AnimationPreference`, resolves it (consulting a mockable `DeviceMemoryProbe` for the `auto` case against a 2 GB threshold), persists it, and pushes the resolved boolean into `Motion`.

**Tech Stack:** Flutter, flutter_bloc, flutter_animate 4.5.2, system_info_plus (new), bloc_test + mocktail for tests.

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `pubspec.yaml` | Add `system_info_plus` | Modify |
| `lib/common/motion/motion.dart` | Context-free global motion flag + `duration()` helper | Create |
| `lib/common/motion/motion_resolver.dart` | Pure `resolveAnimationsEnabled()` + threshold constant | Create |
| `lib/common/motion/device_memory_probe.dart` | `DeviceMemoryProbe` interface + `SystemMemoryProbe` impl | Create |
| `lib/common/motion/motion_animate.dart` | `mAnimate()` drop-in extension over flutter_animate | Create |
| `lib/config/enum.dart` | `AnimationPreference` enum | Modify |
| `lib/config/constants.dart` | `animationPreference` storage key | Modify |
| `lib/common/services/local/local_storage.dart` | Add key to `_fastKeys` | Modify |
| `lib/common/theme_bloc/theme_bloc.dart` | Own/resolve/persist preference; push to `Motion` | Modify |
| `lib/common/theme_bloc/theme_event.dart` | New events | Modify |
| `lib/common/theme_bloc/theme_state.dart` | New fields | Modify |
| `lib/config/providers/providers.dart` | Inject `SystemMemoryProbe` into `ThemeBloc` | Modify |
| `lib/config/router/app_router.dart` | Instant route when motion off | Modify |
| `lib/app.dart` | `MediaQuery(disableAnimations:)` wrap | Modify |
| `lib/core/offline/presentation/widgets/offline_hero.dart` | Don't loop when motion off | Modify |
| `lib/features/main_screen/presentation/widgets/animated_menu_icon.dart` | Jump instead of animate when motion off | Modify |
| `lib/features/settings/presentation/widgets/settings_animation_picker.dart` | Tri-state selector widget | Create |
| `lib/features/settings/presentation/settings_screen.dart` | Add selector to mobile `_AppearanceSection` | Modify |
| `lib/features/settings/presentation/widgets/desktop_settings_view.dart` | Add selector to desktop appearance | Modify |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` | New strings | Modify |
| `test/common/motion/motion_resolver_test.dart` | Resolver unit tests | Create |
| `test/common/motion/motion_test.dart` | `Motion` unit tests | Create |
| `test/common/theme_bloc/theme_bloc_animations_test.dart` | Bloc behavior tests | Create |
| `test/features/settings/widgets/settings_animation_picker_test.dart` | Widget test | Create |

---

## Task 1: Add `system_info_plus` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:` (next to the other packages, e.g. after `shared_preferences: ^2.3.1`), add:

```yaml
  system_info_plus: ^0.0.6
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: completes with "Got dependencies!" and `system_info_plus` resolved.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add system_info_plus for device RAM detection"
```

---

## Task 2: `Motion` global switch

**Files:**
- Create: `lib/common/motion/motion.dart`
- Test: `test/common/motion/motion_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/common/motion/motion_test.dart
import 'package:amana_pos/common/motion/motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => Motion.animationsEnabled.value = true);

  test('on reflects the notifier value', () {
    Motion.animationsEnabled.value = false;
    expect(Motion.on, isFalse);
    Motion.animationsEnabled.value = true;
    expect(Motion.on, isTrue);
  });

  test('duration returns full when on and zero when off', () {
    const full = Duration(milliseconds: 300);
    Motion.animationsEnabled.value = true;
    expect(Motion.duration(full), full);
    Motion.animationsEnabled.value = false;
    expect(Motion.duration(full), Duration.zero);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/common/motion/motion_test.dart`
Expected: FAIL — `Motion` not found / target of URI doesn't exist.

- [ ] **Step 3: Create the implementation**

```dart
// lib/common/motion/motion.dart
import 'package:flutter/foundation.dart';

/// App-wide motion switch. Context-free so it can be read from the static
/// router, flutter_animate call sites, and widgets alike. Owned by ThemeBloc.
class Motion {
  Motion._();

  static final ValueNotifier<bool> animationsEnabled = ValueNotifier<bool>(true);

  static bool get on => animationsEnabled.value;

  static set on(bool value) => animationsEnabled.value = value;

  /// [full] when motion is on, [Duration.zero] when off.
  static Duration duration(Duration full) => on ? full : Duration.zero;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/common/motion/motion_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/common/motion/motion.dart test/common/motion/motion_test.dart
git commit -m "feat(motion): add context-free Motion switch"
```

---

## Task 3: Preference resolver (pure logic) + enum

**Files:**
- Modify: `lib/config/enum.dart`
- Create: `lib/common/motion/motion_resolver.dart`
- Test: `test/common/motion/motion_resolver_test.dart`

- [ ] **Step 1: Add the enum**

Append to `lib/config/enum.dart`:

```dart
enum AnimationPreference { auto, alwaysOn, alwaysOff }
```

- [ ] **Step 2: Write the failing test**

```dart
// test/common/motion/motion_resolver_test.dart
import 'package:amana_pos/common/motion/motion_resolver.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAnimationsEnabled', () {
    test('alwaysOn -> true regardless of memory', () {
      expect(resolveAnimationsEnabled(AnimationPreference.alwaysOn, 512), isTrue);
    });

    test('alwaysOff -> false regardless of memory', () {
      expect(resolveAnimationsEnabled(AnimationPreference.alwaysOff, 8192), isFalse);
    });

    test('auto -> off at or below 2 GB threshold', () {
      expect(resolveAnimationsEnabled(AnimationPreference.auto, 1024), isFalse);
      expect(resolveAnimationsEnabled(AnimationPreference.auto, 2048), isFalse);
    });

    test('auto -> on above 2 GB threshold', () {
      expect(resolveAnimationsEnabled(AnimationPreference.auto, 3072), isTrue);
    });

    test('auto with unknown memory -> on (conservative)', () {
      expect(resolveAnimationsEnabled(AnimationPreference.auto, null), isTrue);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/common/motion/motion_resolver_test.dart`
Expected: FAIL — `resolveAnimationsEnabled` not defined.

- [ ] **Step 4: Create the implementation**

```dart
// lib/common/motion/motion_resolver.dart
import 'package:amana_pos/config/enum.dart';

/// Devices with total RAM at or below this (MB) are treated as low-end.
const int kLowEndMemoryThresholdMb = 2048;

/// Resolves a user preference into an effective on/off value.
/// For [AnimationPreference.auto], unknown memory resolves to ON so a good
/// device is never accidentally degraded.
bool resolveAnimationsEnabled(AnimationPreference pref, int? totalMemoryMb) {
  switch (pref) {
    case AnimationPreference.alwaysOn:
      return true;
    case AnimationPreference.alwaysOff:
      return false;
    case AnimationPreference.auto:
      if (totalMemoryMb == null) return true;
      return totalMemoryMb > kLowEndMemoryThresholdMb;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/common/motion/motion_resolver_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/config/enum.dart lib/common/motion/motion_resolver.dart test/common/motion/motion_resolver_test.dart
git commit -m "feat(motion): add AnimationPreference enum and resolver"
```

---

## Task 4: Device memory probe

**Files:**
- Create: `lib/common/motion/device_memory_probe.dart`

> No unit test for the concrete probe (it calls the platform). It is isolated behind an interface so the bloc tests mock it. Keeping the native symbol in one tiny file means any API tweak at execution time is contained here.

- [ ] **Step 1: Create the interface + implementation**

```dart
// lib/common/motion/device_memory_probe.dart
import 'package:system_info_plus/system_info_plus.dart';

/// Reports total physical RAM. Abstracted so it can be mocked in tests.
abstract class DeviceMemoryProbe {
  /// Total physical memory in megabytes, or null if it cannot be determined.
  Future<int?> totalMemoryMb();
}

class SystemMemoryProbe implements DeviceMemoryProbe {
  const SystemMemoryProbe();

  @override
  Future<int?> totalMemoryMb() async {
    try {
      // system_info_plus returns physical memory in MB.
      return await SystemInfoPlus.physicalMemory;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/common/motion/device_memory_probe.dart`
Expected: No issues. (If `SystemInfoPlus.physicalMemory` resolves to a different symbol in the installed version, fix the single call here; the return contract — `Future<int?>` in MB — stays the same.)

- [ ] **Step 3: Commit**

```bash
git add lib/common/motion/device_memory_probe.dart
git commit -m "feat(motion): add DeviceMemoryProbe with system_info_plus impl"
```

---

## Task 5: Storage key + fast-keys

**Files:**
- Modify: `lib/config/constants.dart`
- Modify: `lib/common/services/local/local_storage.dart`

- [ ] **Step 1: Add the constant**

In `lib/config/constants.dart`, inside `class Constants`, after `static const appLocale = 'app_locale';` add:

```dart
  static const animationPreference = 'animation_preference';
```

- [ ] **Step 2: Route it through SharedPreferences**

In `lib/common/services/local/local_storage.dart`, extend `_fastKeys`:

```dart
const _fastKeys = {
  Constants.appTheme,
  Constants.appLocale,
  Constants.animationPreference,
};
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/config/constants.dart lib/common/services/local/local_storage.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/config/constants.dart lib/common/services/local/local_storage.dart
git commit -m "feat(motion): add animationPreference storage key"
```

---

## Task 6: Extend ThemeState

**Files:**
- Modify: `lib/common/theme_bloc/theme_state.dart`

- [ ] **Step 1: Add fields, constructor args, copyWith, props**

Replace the body of `lib/common/theme_bloc/theme_state.dart` with:

```dart
part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final ScreenMode? mode;
  final bool isDarkTheme;
  final bool isBigFontSize;
  final bool isLoaded;
  final AnimationPreference animationPreference;
  final bool animationsEnabled;

  const ThemeState({
    this.mode = ScreenMode.light,
    this.isDarkTheme = false,
    this.isBigFontSize = false,
    this.isLoaded = false,
    this.animationPreference = AnimationPreference.auto,
    this.animationsEnabled = true,
  });

  factory ThemeState.initial() {
    return const ThemeState(
      mode: ScreenMode.light,
      isDarkTheme: false,
      isBigFontSize: false,
      isLoaded: false,
      animationPreference: AnimationPreference.auto,
      animationsEnabled: true,
    );
  }

  ThemeState copyWith({
    ScreenMode? mode,
    bool? isDarkTheme,
    bool? isBigFontSize,
    bool? isLoaded,
    AnimationPreference? animationPreference,
    bool? animationsEnabled,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isBigFontSize: isBigFontSize ?? this.isBigFontSize,
      isLoaded: isLoaded ?? this.isLoaded,
      animationPreference: animationPreference ?? this.animationPreference,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        isDarkTheme,
        isBigFontSize,
        isLoaded,
        animationPreference,
        animationsEnabled,
      ];
}
```

- [ ] **Step 2: Verify it compiles (will fail to analyze until enum import exists in theme_bloc.dart — that import is added in Task 8; defer full analyze)**

Run: `flutter analyze lib/common/theme_bloc/theme_state.dart`
Expected: may report `AnimationPreference` undefined until Task 8 wires the import; that is expected and resolved in Task 8. Do not commit yet — commit together with Task 7 and 8.

---

## Task 7: Add ThemeBloc events

**Files:**
- Modify: `lib/common/theme_bloc/theme_event.dart`

- [ ] **Step 1: Read the current events file**

Run: `sed -n '1,80p' lib/common/theme_bloc/theme_event.dart`
Expected: shows existing `ThemeEvent` subclasses (`OnThemeChangeEvent`, `OnChangeFontSizeEvent`, `OnThemeLoadedEvent`).

- [ ] **Step 2: Append the two new events**

Add to `lib/common/theme_bloc/theme_event.dart` (after the existing events, before any closing):

```dart
class OnAnimationsPreferenceChanged extends ThemeEvent {
  final AnimationPreference preference;
  const OnAnimationsPreferenceChanged(this.preference);

  @override
  List<Object?> get props => [preference];
}

class OnAnimationsLoadedEvent extends ThemeEvent {
  final AnimationPreference preference;
  final bool animationsEnabled;
  const OnAnimationsLoadedEvent({
    required this.preference,
    required this.animationsEnabled,
  });

  @override
  List<Object?> get props => [preference, animationsEnabled];
}
```

> If `ThemeEvent` does not already extend `Equatable`/declare `props`, match the existing style instead (e.g. drop the `props` overrides). Check `sed -n '1,20p' lib/common/theme_bloc/theme_event.dart` and mirror it.

---

## Task 8: Extend ThemeBloc logic + wire Motion

**Files:**
- Modify: `lib/common/theme_bloc/theme_bloc.dart`
- Test: `test/common/theme_bloc/theme_bloc_animations_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/common/theme_bloc/theme_bloc_animations_test.dart
import 'package:amana_pos/common/motion/device_memory_probe.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCacheStorage extends Mock implements CacheStorage {}

class _FakeMemoryProbe implements DeviceMemoryProbe {
  _FakeMemoryProbe(this.value);
  final int? value;
  @override
  Future<int?> totalMemoryMb() async => value;
}

void main() {
  late _MockCacheStorage cache;

  setUp(() {
    cache = _MockCacheStorage();
    // Defaults so the constructor's _loadAccessibilitySettings resolves cleanly.
    when(() => cache.getBool(any())).thenAnswer((_) async => false);
    when(() => cache.getValue(any())).thenAnswer((_) async => null);
    when(() => cache.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => cache.save(any(), any())).thenAnswer((_) async => true);
    Motion.animationsEnabled.value = true;
  });

  ThemeBloc build({int? memMb = 4096}) => ThemeBloc(
        cacheStorage: cache,
        memoryProbe: _FakeMemoryProbe(memMb),
      );

  group('OnAnimationsPreferenceChanged', () {
    blocTest<ThemeBloc, ThemeState>(
      'alwaysOff disables animations and persists',
      build: () => build(),
      act: (bloc) =>
          bloc.add(const OnAnimationsPreferenceChanged(AnimationPreference.alwaysOff)),
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        verify(() => cache.save(Constants.animationPreference, 'alwaysOff')).called(1);
        expect(Motion.on, isFalse);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'auto on a 1 GB device resolves to off',
      build: () => build(memMb: 1024),
      act: (bloc) =>
          bloc.add(const OnAnimationsPreferenceChanged(AnimationPreference.auto)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.animationsEnabled, isFalse);
        expect(Motion.on, isFalse);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'auto on a 4 GB device resolves to on',
      build: () => build(memMb: 4096),
      act: (bloc) =>
          bloc.add(const OnAnimationsPreferenceChanged(AnimationPreference.auto)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.animationsEnabled, isTrue);
        expect(Motion.on, isTrue);
      },
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/common/theme_bloc/theme_bloc_animations_test.dart`
Expected: FAIL — `memoryProbe` named param / events undefined.

- [ ] **Step 3: Update imports and constructor**

In `lib/common/theme_bloc/theme_bloc.dart`, add imports near the top (after existing imports):

```dart
import 'package:amana_pos/common/motion/device_memory_probe.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/common/motion/motion_resolver.dart';
```

Change the class fields + constructor to:

```dart
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final CacheStorage cacheStorage;
  final DeviceMemoryProbe memoryProbe;

  ThemeBloc({
    required this.cacheStorage,
    this.memoryProbe = const SystemMemoryProbe(),
  }) : super(ThemeState.initial()) {
    on<OnThemeChangeEvent>(_changeTheme);
    on<OnChangeFontSizeEvent>(_onChangeFontSizeEvent);
    on<OnThemeLoadedEvent>(_onThemeLoaded);
    on<OnAnimationsPreferenceChanged>(_onAnimationsPreferenceChanged);
    on<OnAnimationsLoadedEvent>(_onAnimationsLoaded);

    _loadAccessibilitySettings();
    _loadAnimationPreference();
  }
```

- [ ] **Step 4: Add the load + handler methods**

Add these methods inside `ThemeBloc` (e.g. after `_loadAccessibilitySettings`):

```dart
  Future<void> _loadAnimationPreference() async {
    final stored = await cacheStorage.getValue(Constants.animationPreference);
    final pref = AnimationPreference.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => AnimationPreference.auto,
    );
    final memMb =
        pref == AnimationPreference.auto ? await memoryProbe.totalMemoryMb() : null;
    final enabled = resolveAnimationsEnabled(pref, memMb);
    add(OnAnimationsLoadedEvent(preference: pref, animationsEnabled: enabled));
  }

  void _onAnimationsLoaded(
    OnAnimationsLoadedEvent event,
    Emitter<ThemeState> emit,
  ) {
    Motion.on = event.animationsEnabled;
    emit(state.copyWith(
      animationPreference: event.preference,
      animationsEnabled: event.animationsEnabled,
    ));
  }

  Future<void> _onAnimationsPreferenceChanged(
    OnAnimationsPreferenceChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await cacheStorage.save(Constants.animationPreference, event.preference.name);
    final memMb = event.preference == AnimationPreference.auto
        ? await memoryProbe.totalMemoryMb()
        : null;
    final enabled = resolveAnimationsEnabled(event.preference, memMb);
    Motion.on = enabled;
    emit(state.copyWith(
      animationPreference: event.preference,
      animationsEnabled: enabled,
    ));
  }
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/common/theme_bloc/theme_bloc_animations_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Analyze the theme_bloc trio**

Run: `flutter analyze lib/common/theme_bloc/`
Expected: No issues (resolves the `AnimationPreference` reference deferred from Task 6).

- [ ] **Step 7: Commit Tasks 6–8 together**

```bash
git add lib/common/theme_bloc/ test/common/theme_bloc/theme_bloc_animations_test.dart
git commit -m "feat(motion): ThemeBloc owns and resolves animation preference"
```

---

## Task 9: Inject the probe in providers

**Files:**
- Modify: `lib/config/providers/providers.dart`

- [ ] **Step 1: Pass the probe**

In `lib/config/providers/providers.dart`, add the import:

```dart
import 'package:amana_pos/common/motion/device_memory_probe.dart';
```

Change the `ThemeBloc` provider to:

```dart
    BlocProvider<ThemeBloc>(
      create: (_) => ThemeBloc(
        cacheStorage: getIt<CacheStorage>(),
        memoryProbe: const SystemMemoryProbe(),
      ),
    ),
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/config/providers/providers.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/config/providers/providers.dart
git commit -m "feat(motion): inject SystemMemoryProbe into ThemeBloc"
```

---

## Task 10: Instant route transitions when motion is off

**Files:**
- Modify: `lib/config/router/app_router.dart`

- [ ] **Step 1: Import Motion**

In `lib/config/router/app_router.dart`, add:

```dart
import 'package:amana_pos/common/motion/motion.dart';
```

- [ ] **Step 2: Short-circuit `_buildRoute`**

Replace the body of `_buildRoute` so the first lines are:

```dart
  PageRoute _buildRoute(Widget child, RouteSettings settings) {
    if (!Motion.on) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    final isIOS = !kIsWeb && Platform.isIOS;
    // ... existing iOS + PageRouteBuilder logic unchanged ...
```

(Keep everything after this unchanged.)

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/config/router/app_router.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/config/router/app_router.dart
git commit -m "feat(motion): skip route transitions when animations are off"
```

---

## Task 11: `mAnimate()` drop-in for flutter_animate

**Files:**
- Create: `lib/common/motion/motion_animate.dart`

- [ ] **Step 1: Create the extension**

```dart
// lib/common/motion/motion_animate.dart
import 'package:amana_pos/common/motion/motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension MotionAnimate on Widget {
  /// Drop-in for [Widget.animate]. When motion is off, renders the effect
  /// chain at its end state instantly (no autoplay, value pinned to 1.0),
  /// so entrance effects (fadeIn/slideY/etc.) show the final appearance.
  Animate mAnimate({
    Key? key,
    List<Effect>? effects,
    AnimateCallback? onInit,
    AnimateCallback? onPlay,
    AnimateCallback? onComplete,
    bool? autoPlay,
    Duration? delay,
    AnimationController? controller,
    Adapter? adapter,
    double? target,
    double? value,
  }) {
    final motionOff = !Motion.on;
    return animate(
      key: key,
      effects: effects,
      onInit: onInit,
      onPlay: onPlay,
      onComplete: onComplete,
      autoPlay: motionOff ? false : autoPlay,
      delay: delay,
      controller: controller,
      adapter: adapter,
      target: target,
      value: motionOff ? 1.0 : value,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/common/motion/motion_animate.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/common/motion/motion_animate.dart
git commit -m "feat(motion): add mAnimate drop-in over flutter_animate"
```

---

## Task 12: Migrate call sites to `mAnimate()`

**Files:**
- Modify: all 49 files that call `.animate(`

- [ ] **Step 1: List the call sites**

Run: `grep -rln "\.animate(" lib`
Expected: ~49 files.

- [ ] **Step 2: Replace `.animate(` with `.mAnimate(`**

Run (macOS/BSD sed):

```bash
grep -rl "\.animate(" lib | while read -r f; do
  sed -i '' 's/\.animate(/.mAnimate(/g' "$f"
done
```

- [ ] **Step 3: Add the import to each changed file**

For every file changed in Step 2 that does NOT already import it, add:

```dart
import 'package:amana_pos/common/motion/motion_animate.dart';
```

Tip: list files still missing the import after a first pass:

```bash
for f in $(grep -rl "\.mAnimate(" lib); do
  grep -q "common/motion/motion_animate.dart" "$f" || echo "$f";
done
```

Add the import line to each file printed. (Leave the existing `flutter_animate` import in place — effect methods like `.fadeIn()` still come from it.)

- [ ] **Step 4: Verify nothing else matched**

Run: `grep -rn "\.animate(" lib`
Expected: no matches (all are now `.mAnimate(`). If `AnimationController.animateTo`/`animateBack` appear, they are unaffected — the replace only targeted `.animate(`.

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib`
Expected: No issues. Fix any missing-import errors by adding the import from Step 3.

- [ ] **Step 6: Commit**

```bash
git add lib
git commit -m "refactor(motion): route flutter_animate calls through mAnimate"
```

---

## Task 13: Stop the offline-hero loop when motion is off

**Files:**
- Modify: `lib/core/offline/presentation/widgets/offline_hero.dart`

- [ ] **Step 1: Import Motion**

Add to `lib/core/offline/presentation/widgets/offline_hero.dart`:

```dart
import 'package:amana_pos/common/motion/motion.dart';
```

- [ ] **Step 2: Guard the repeat in `initState`**

Replace the controller setup block:

```dart
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
```

with:

```dart
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (Motion.on) {
      _controller.repeat(reverse: true);
    } else {
      // Rest centered (Tween midpoint => 0 offset) and never spin.
      _controller.value = 0.5;
    }
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/core/offline/presentation/widgets/offline_hero.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/offline/presentation/widgets/offline_hero.dart
git commit -m "feat(motion): freeze offline hero float when animations are off"
```

---

## Task 14: Jump the menu icon when motion is off

**Files:**
- Modify: `lib/features/main_screen/presentation/widgets/animated_menu_icon.dart`

- [ ] **Step 1: Import Motion**

Add to the file:

```dart
import 'package:amana_pos/common/motion/motion.dart';
```

- [ ] **Step 2: Guard `didUpdateWidget`**

Replace:

```dart
  @override
  void didUpdateWidget(AnimatedMenuIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      widget.isOpen ? _ctrl.forward() : _ctrl.reverse();
    }
  }
```

with:

```dart
  @override
  void didUpdateWidget(AnimatedMenuIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (!Motion.on) {
        _ctrl.value = widget.isOpen ? 1.0 : 0.0;
      } else {
        widget.isOpen ? _ctrl.forward() : _ctrl.reverse();
      }
    }
  }
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/main_screen/presentation/widgets/animated_menu_icon.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/main_screen/presentation/widgets/animated_menu_icon.dart
git commit -m "feat(motion): snap menu icon state when animations are off"
```

---

## Task 15: Localization strings

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add English strings**

In `lib/l10n/app_en.arb`, near the existing `themeLight`/`themeDark`/`themeSystem` keys, add:

```json
  "settingsAnimations": "Animations",
  "settingsAnimationsAutoSubtitle": "Off on low-memory devices",
  "animationsAuto": "Automatic",
  "animationsAlwaysOn": "Always on",
  "animationsAlwaysOff": "Always off",
```

(If the file is strict JSON, ensure commas/locations are valid — add a comma to the line above the insert if needed.)

- [ ] **Step 2: Add Arabic strings**

In `lib/l10n/app_ar.arb`, add the matching keys:

```json
  "settingsAnimations": "الحركات",
  "settingsAnimationsAutoSubtitle": "متوقفة على الأجهزة محدودة الذاكرة",
  "animationsAuto": "تلقائي",
  "animationsAlwaysOn": "تشغيل دائمًا",
  "animationsAlwaysOff": "إيقاف دائمًا",
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: regenerates `lib/l10n/app_localizations*.dart` with the new getters. (If the project generates l10n during `flutter pub get`/build instead, run `flutter pub get`.)

- [ ] **Step 4: Verify the getters exist**

Run: `grep -n "settingsAnimations" lib/l10n/app_localizations.dart`
Expected: getter declarations present.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n
git commit -m "i18n: add animation setting strings (en, ar)"
```

---

## Task 16: Animation selector widget

**Files:**
- Create: `lib/features/settings/presentation/widgets/settings_animation_picker.dart`
- Test: `test/features/settings/widgets/settings_animation_picker_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/settings/widgets/settings_animation_picker_test.dart
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_animation_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping an option invokes the callback', (tester) async {
    AnimationPreference? picked;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SettingsAnimationPicker(
          selected: AnimationPreference.auto,
          onSelected: (p) => picked = p,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap the "Always off" option.
    await tester.tap(find.text('Always off'));
    await tester.pump();

    expect(picked, AnimationPreference.alwaysOff);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/widgets/settings_animation_picker_test.dart`
Expected: FAIL — `SettingsAnimationPicker` not found.

- [ ] **Step 3: Create the widget**

```dart
// lib/features/settings/presentation/widgets/settings_animation_picker.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SettingsAnimationPicker extends StatelessWidget {
  final AnimationPreference selected;
  final ValueChanged<AnimationPreference> onSelected;

  const SettingsAnimationPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;

    final options = <(AnimationPreference, String)>[
      (AnimationPreference.auto, tr.animationsAuto),
      (AnimationPreference.alwaysOn, tr.animationsAlwaysOn),
      (AnimationPreference.alwaysOff, tr.animationsAlwaysOff),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppDims.s2),
            _AnimationOption(
              label: options[i].$2,
              isSelected: options[i].$1 == selected,
              onTap: () => onSelected(options[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimationOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimationOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // No AnimatedContainer here on purpose: this control toggles motion.
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 1.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs200(context).copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

> If `context.tr`, `AppDims`, `AppTextStyles.bs200`, or `context.appColors` differ from what `settings_theme_picker.dart` uses, copy that file's exact imports/usages — this widget intentionally mirrors it.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/settings/widgets/settings_animation_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/widgets/settings_animation_picker.dart test/features/settings/widgets/settings_animation_picker_test.dart
git commit -m "feat(settings): add animation preference picker widget"
```

---

## Task 17: Wire selector into mobile settings

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Import the picker**

Add near the other settings-widget imports at the top of `settings_screen.dart`:

```dart
import 'package:amana_pos/features/settings/presentation/widgets/settings_animation_picker.dart';
```

- [ ] **Step 2: Add the selector under the theme picker in `_AppearanceSection`**

In `_AppearanceSection.build`, replace the `Column`'s `children` list so it ends with the new block after the existing theme `BlocSelector`:

```dart
      children: [
        SectionLabel(label: tr.settingsSectionAppearance),
        const SizedBox(height: AppDims.s2),
        BlocSelector<ThemeBloc, ThemeState, ScreenMode?>(
          selector: (state) => state.mode,
          builder: (context, mode) {
            return SettingsThemePicker(
              selectedMode: mode ?? ScreenMode.device,
              onModeSelected: (selectedMode) {
                context.read<ThemeBloc>().add(
                      OnThemeChangeEvent(mode: selectedMode),
                    );
              },
            );
          },
        ),
        const SizedBox(height: AppDims.s4),
        Text(
          tr.settingsAnimations,
          style: AppTextStyles.bs200(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppDims.s2),
        BlocSelector<ThemeBloc, ThemeState, AnimationPreference>(
          selector: (state) => state.animationPreference,
          builder: (context, pref) {
            return SettingsAnimationPicker(
              selected: pref,
              onSelected: (p) {
                context.read<ThemeBloc>().add(OnAnimationsPreferenceChanged(p));
              },
            );
          },
        ),
        const SizedBox(height: AppDims.s1),
        if (context.select<ThemeBloc, AnimationPreference>(
              (b) => b.state.animationPreference,
            ) ==
            AnimationPreference.auto)
          Text(
            tr.settingsAnimationsAutoSubtitle,
            style: AppTextStyles.bs100(context).copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
      ],
```

> Verify imports for `AppTextStyles`, `AppDims`, `context.appColors`, `AnimationPreference`, and `OnAnimationsPreferenceChanged` exist in this file; add any missing ones (`config/enum.dart`, `theme/app_text_styles.dart`, `theme/app_spacing.dart`, `theme/app_theme_colors.dart`, `common/theme_bloc/theme_bloc.dart`). If `AppTextStyles.bs100` does not exist, use `bs200` for the subtitle too.

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/settings/presentation/settings_screen.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat(settings): show animation picker in mobile appearance section"
```

---

## Task 18: Wire selector into desktop settings

**Files:**
- Modify: `lib/features/settings/presentation/widgets/desktop_settings_view.dart`

- [ ] **Step 1: Find the desktop appearance block**

Run: `grep -n "SettingsThemePicker\|Appearance\|settingsSectionAppearance" lib/features/settings/presentation/widgets/desktop_settings_view.dart`
Expected: shows where the theme picker is rendered in the desktop view.

- [ ] **Step 2: Add the same picker block after the desktop theme picker**

Mirror Task 17, Step 2: add the import, then insert the `Text(tr.settingsAnimations)` label, the `BlocSelector<ThemeBloc, ThemeState, AnimationPreference>` wrapping `SettingsAnimationPicker`, and the auto-subtitle, immediately after the desktop `SettingsThemePicker`. Use the spacing widgets already used in that file.

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/settings/presentation/widgets/desktop_settings_view.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/presentation/widgets/desktop_settings_view.dart
git commit -m "feat(settings): show animation picker in desktop appearance section"
```

---

## Task 19: app.dart MediaQuery signal layer

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Import Motion**

Add to `lib/app.dart`:

```dart
import 'package:amana_pos/common/motion/motion.dart';
```

- [ ] **Step 2: Wrap `child` in the `builder` with a Motion-driven MediaQuery**

Replace the `builder:` in the `MaterialApp` with:

```dart
                builder: (context, child) {
                  Widget result = child!;
                  if (Platform.isMacOS || Platform.isWindows) {
                    result = MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.noScaling,
                      ),
                      child: result,
                    );
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: Motion.animationsEnabled,
                    builder: (context, enabled, mqChild) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(disableAnimations: !enabled),
                        child: mqChild!,
                      );
                    },
                    child: result,
                  );
                },
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/app.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat(motion): propagate disableAnimations via MediaQuery"
```

---

## Task 20: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: No issues (or only pre-existing warnings unrelated to this work).

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass, including the new motion/bloc/widget tests.

- [ ] **Step 3: Manual smoke check (device or emulator)**

Run the app. In Settings → Appearance:
- Set **Always off** → navigate between screens: transitions are instant; open/close the side menu: icon snaps; offline screen hero is static.
- Set **Always on** → animations return.
- Set **Automatic** → on a low-RAM device/emulator (≤2 GB) animations are off; subtitle "Off on low-memory devices" is visible.
- Kill and relaunch the app → the chosen preference persists.

- [ ] **Step 4: Final commit (if any cleanup)**

```bash
git add -A
git commit -m "chore(motion): finalize disable-animations setting" || echo "nothing to commit"
```

---

## Self-Review Notes

- **Spec coverage:** central `Motion` (T2), tri-state + RAM resolve (T3,T8), persistence (T5,T8), routes (T10), flutter_animate (T11,T12), offline hero + menu icon (T13,T14), MediaQuery signal (T19), settings UI mobile+desktop (T16–T18), i18n (T15), conservative fallback on unknown RAM (T3 resolver) — all covered.
- **Type consistency:** `AnimationPreference` (auto/alwaysOn/alwaysOff), `resolveAnimationsEnabled(pref, int?)`, `Motion.on`/`Motion.duration`, `OnAnimationsPreferenceChanged`/`OnAnimationsLoadedEvent`, `kLowEndMemoryThresholdMb = 2048` are used identically across tasks.
- **Threshold semantics:** `auto` is OFF when `totalMemoryMb <= 2048` (resolver uses `> threshold` for ON), matching the "≤ 2 GB = low-end" decision.
- **Risk note:** the only API not verifiable offline is `SystemInfoPlus.physicalMemory`; it is isolated to `SystemMemoryProbe` (T4) and mocked in tests, so a symbol tweak there does not ripple.
