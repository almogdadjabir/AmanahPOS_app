# Navigation

## Files

```
lib/features/main_screen/
├── data/
│   ├── app_feature.dart          ← AppFeature enum
│   ├── navigation_config.dart    ← screenFor(AppFeature) → Widget
│   ├── navigation_model.dart
│   └── section.dart              ← Section + SectionItem models
└── presentation/
    ├── bloc/
    │   ├── navigation_bloc.dart  ← bloc + part directives
    │   ├── navigation_event.dart ← part of navigation_bloc.dart
    │   └── navigation_state.dart ← part of navigation_bloc.dart
    ├── main_screen.dart
    ├── offline_preparation_listener.dart
    └── widgets/
        └── pos_app_bar.dart

lib/features/feature_menu/
├── feature_menu.dart             ← sliding bottom-sheet menu
├── feature_menu_sections.dart    ← buildMenuSections()
└── widgets/
    ├── feature_list_item.dart
    ├── menu_footer.dart
    ├── section_grid.dart
    └── section_label.dart
```

## AppFeature Enum

```dart
enum AppFeature { pos, business, users, categories, products, inventory, customers }
```

## NavigationState

```dart
AppFeature     currentFeature   // default: AppFeature.pos
AppPermissions permissions      // default: AppPermissions.none
bool           menuOpen         // default: false

// Derived:
Widget get currentScreen => NavigationConfig.screenFor(currentFeature);
```

## NavigationEvents

| Event | Effect |
|---|---|
| `NavigationFeatureSelected(feature)` | Switch screen if permitted |
| `NavigationPermissionsChanged(permissions)` | Update permissions; maybe redirect |
| `NavigationReset()` | Full reset to initial on logout |
| `SetMenuOpenEvent({bool? open})` | Toggle or set menu open/closed |

## NavigationBloc Behaviour

**AuthBloc subscription** (not widget-based):
```dart
_authSub = _authBloc.stream.listen(_onAuthStateChanged);
_syncFromAuthState(_authBloc.state);  // seed on construction
```

`_onAuthStateChanged` runs on every `AuthState` emission:
- If `!isLoggedIn && permissions != AppPermissions.none` → dispatch `NavigationReset`.
- If `authState.permissions != state.permissions` → dispatch `NavigationPermissionsChanged`.

`_onPermissionsChanged`:
- First time `isOwner` is detected (`!_ownerRedirectDone`) → land on `AppFeature.business`.
- Current feature no longer allowed → fall back to `AppFeature.pos`.

## MainScreen

```dart
Scaffold(
  appBar: PosAppBar(onMenuTap: () => add(SetMenuOpenEvent())),
  body: Stack([
    state.currentScreen,   // BlocBuilder on currentFeature only
    FeatureMenu(),         // always in tree; animated in/out
  ]),
)
```

Wrapped in `OfflinePreparationListener`.

## FeatureMenu

Sliding bottom sheet. Animated with `AnimatedSlide` + `AnimatedOpacity`.

`BlocBuilder` rebuild gate:
```dart
buildWhen: (prev, curr) =>
    prev.menuOpen != curr.menuOpen ||
    prev.currentFeature != curr.currentFeature ||
    prev.permissions != curr.permissions,
```

Sections built by `buildMenuSections(context, navState)` in `feature_menu_sections.dart`.
Each `SectionItem` has: `id`, `label`, `subtitle`, `icon`, `color`, `active`, `onTap`.
Empty sections (all items filtered by permissions) are dropped.

## OfflinePreparationListener (`offline_preparation_listener.dart`)

`MultiBlocListener` wrapping the main screen body. Handles:

1. **`AuthBloc` sessionId change** → reset `ProductBloc` + `CategoryBloc`.
2. **`AuthBloc` business change** → show/hide `FancyBusinessBottomSheet`.
3. **`OfflineStatusBloc` bootstrap change** → show/hide `PreparingOfflineScreen`.
4. **`AuthBloc` subscription expiry** → show/hide `SubscriptionExpiredScreen`.

*(Fix 1 adds a 5th listener here — see `amanapos_fixes_prompt.md`.)*
