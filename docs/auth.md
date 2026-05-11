# Auth

## Files

```
lib/common/auth_bloc/
├── auth_bloc.dart    ← bloc + part directives
├── auth_event.dart   ← part of auth_bloc.dart
└── auth_state.dart   ← part of auth_bloc.dart
```

`AuthBloc` is registered as a **GetIt singleton** and provided via `BlocProvider(create: (_) => getIt<AuthBloc>())`.

## AuthState Fields

```dart
AuthStatus authStatus          // initial | loading | success | failure
User? profile                  // logged-in user
bool isLoggedIn
String? responseError
BusinessStatus businessStatus  // initial | loading | success | failure
BusinessData? defaultBusiness
int sessionId                  // increments ONLY on a different user login
```

**Derived getter (not stored):**
```dart
AppPermissions get permissions => AppPermissions.from(
  businessType: defaultBusiness?.businessType,
  userRole: profile?.role,
);
```

## AuthEvents

| Event | When dispatched |
|---|---|
| `OnLoadProfileEvent({User? user})` | Splash → authenticated, or after login |
| `OnLoadBusinessEvent()` | After profile loads; or retry after coming back online |
| `OnLogoutEvent()` | User taps logout |
| `OnProfileUpdated(user)` | In-place profile update (no business reload, no sessionId bump) |

## Key Behaviour

**Profile load** (`_onLoadProfile`):
1. Read token from `CacheStorage`. If none → return.
2. Load cached profile from `CacheStorage` → emit immediately.
3. Fetch fresh profile from API.
4. If different user detected → `offlineLocalCache.clearAllOnLogout()` → bump `sessionId`.
5. Dispatch `OnLoadBusinessEvent()`.

**Business load** (`_onLoadBusinessEvent`):
1. Try `offlineLocalCache.getBusinesses()` → emit cached if found.
2. Fetch `businessUseCase.getBusinessList()`.
3. Save `xTenantID` to `CacheStorage`.
4. Emit with `defaultBusiness`.
5. `offlineStatusBloc.add(const OnOfflineStatusStarted())`.

**sessionId rule:**
- Bumps on a confirmed DIFFERENT user login (`isDifferentUser == true`).
- Same user re-logging in: no bump.
- Data blocs (`ProductBloc`, `CategoryBloc`) listen in `OfflinePreparationListener` and reset when `sessionId` changes.

**Logout** (`_onLogout`):
- Requires online + no pending sales.
- Clears `OfflineLocalCache`, tokens, cached profile.
- Emits `AuthState.initial()`.
- Navigates to `RouteStrings.splash`.

## AppPermissions (`lib/core/permissions/app_permissions.dart`)

```dart
class AppPermissions {
  final AppBusinessType businessType;  // restaurant | shop | unknown
  final AppUserRole role;              // owner | cashier | unknown
}
```

Permission getters:
```dart
bool get _hasSession => role != AppUserRole.unknown;

canAccessPOS         → always true
canAccessProducts    → _hasSession
canAccessCategories  → _hasSession
canAccessInventory   → _hasSession && businessType != restaurant
canAccessCustomers   → _hasSession && !isRestaurantCashier
canAccessReports     → _hasSession && isOwner
canAccessUsers       → _hasSession && isOwner
canAccessBusiness    → _hasSession && isOwner
```

`AppPermissions.none` = `{ businessType: unknown, role: unknown }` → all `_hasSession` checks return false → menu only shows POS.

**Equality:** `==` compares `businessType` and `role` only.

## CacheStorage Keys (from `Constants`)

```dart
Constants.authToken       // JWT token
Constants.refreshToken
Constants.xTenantID       // business/tenant ID sent as header
Constants.cachedProfile   // JSON-serialised User
```
