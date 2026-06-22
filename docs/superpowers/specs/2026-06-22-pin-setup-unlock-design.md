# PIN Setup & Unlock — Design

**Date:** 2026-06-22
**Status:** Approved (pending spec review)
**Area:** Authentication / offline-first session management

## Summary

Add a local 4-digit PIN as the day-to-day way to enter the Amana POS app on a
shared device. Each staff member (owner, manager, cashier) does **one** full
OTP/password login on the device and then sets a PIN. From then on, the app
opens to a **PIN pad** — no user picker. The typed PIN is matched against every
enrolled user on the device; a match silently restores that user's session and
opens the app. This is fully offline-capable.

## Goals

- After any **new full login**, prompt the user to create a 4-digit PIN.
- On cold start (and on resume after a background timeout), show a **PIN unlock
  screen** — a bare PIN pad, no list of users.
- The PIN itself identifies the user: matching a typed PIN to an enrolled record
  logs that user in automatically ("simple, clean").
- Support **multiple enrolled users on one device** (shared POS device).
- Work **offline** — unlocking must not require the network.
- Respect existing **roles** (owner / manager / cashier) and offline-first data.

## Non-Goals

- No user picker / account list on the unlock screen (security choice).
- No biometric unlock (PIN only).
- No manual "lock now / switch user" button in-app (only cold start + timeout).
- Per-sale cashier attribution changes on user switch are **out of scope** for
  this MVP (flagged below; revisit if backend requires it).

## Decisions (locked)

| Decision | Value |
|---|---|
| Device model | Many users share one device; unlock is a bare PIN pad (PIN = identity). |
| Enrollment | Each user logs in fully once, then sets a PIN. |
| Lock triggers | Cold start **and** resume after background timeout. No manual lock button. |
| Background timeout | **2 minutes**. |
| Biometrics | None — PIN only. |
| Lockout | After **5** failed attempts → **30s** lock, escalating on repeat. |
| Recovery | Always-present "Forgot PIN / Use a different account" → full login (re-enrolls). |
| PIN length | 4 digits. |
| Offline wipe | Wipe offline DB only when **businessId/tenant** differs, not on every user id change. |

## Architecture

### Why the active-session swap works

`AppInterceptors` reads `Constants.authToken` and `Constants.xTenantID` fresh
from `CacheStorage` on **every** request
(`lib/core/network/app_interceptors.dart:46`). Therefore switching the active
user is simply writing that user's tokens into those keys — no client rebuild,
no re-login round trip. The PIN vault is a separate per-user store; unlocking
copies the matched user's tokens into the active keys and loads their profile.

### Components

1. **`PinVaultService`** — `lib/common/services/local/pin_vault_service.dart`
   Pure data layer over `CacheStorage` key `pin_vault`. Methods:
   - `Future<bool> hasAnyEnrolled()`
   - `Future<bool> isUserEnrolled(String userId)`
   - `Future<void> enrollUser({required User profile, required String pin, required String accessToken, required String refreshToken, required String tenantId})`
   - `Future<PinUserRecord?> findUserByPin(String pin)` — hashes input against
     each record's salt, returns the match or null.
   - `Future<bool> isPinTaken(String pin)` — enrollment uniqueness check.
   - `Future<void> recordFailedAttempt()` / `Future<void> clearAttempts()`
   - `Future<Duration> lockoutRemaining()`
   - `Future<void> removeUser(String userId)` / `Future<void> clearVault()`

2. **`PinBloc`** — `lib/features/pin/presentation/bloc/`
   Drives both screens. Modes: `setup` (enter → confirm) and `unlock`
   (match / mismatch / lockout). On successful unlock, writes matched user's
   tokens to the active keys via `CacheStorage`, then dispatches
   `OnLoadProfileEvent(user: matched.profile)` on the existing `AuthBloc`.

3. **`AppLockController`** — a `WidgetsBindingObserver` registered at the app
   root. Records a timestamp on `paused`/`inactive`; on `resumed`, if elapsed
   > 2 min **and** `PinVaultService.hasAnyEnrolled()`, pushes the unlock route.

### Storage shape — `pin_vault`

```jsonc
{
  "version": 1,
  "lockedUntil": null,        // ISO8601 or null — device-level lockout
  "failedAttempts": 0,
  "users": [
    {
      "userId": "...", "businessId": "...", "tenantId": "...",
      "fullName": "...", "role": "cashier", "phone": "...",
      "pinSalt": "<base64>", "pinHash": "<base64 PBKDF2-HMAC-SHA256>",
      "accessToken": "...", "refreshToken": "...",
      "profileJson": { /* User.toJson() */ },
      "enrolledAt": "<ISO8601>", "lastUnlockAt": "<ISO8601>"
    }
  ]
}
```

- **Hashing:** PBKDF2-HMAC-SHA256, per-user random salt (16 bytes),
  ~100k iterations. Adds the `crypto` package. The 4-digit space is small, so
  **lockout is the real defense**; hashing only prevents plaintext at rest.
- **At-rest security:** vault lives in `CacheStorage` — encrypted on
  iOS/Android, SharedPreferences (plaintext) on desktop, identical to how the
  app already stores `auth_token`. Accepted trade-off.
- **Uniqueness:** at setup, reject a PIN already matching an enrolled user
  (`isPinTaken`) so PIN→user mapping stays unambiguous.

## Flows

### Enrollment (after full login)
1. Login succeeds → `LoginStatus.competed`.
2. If `!isUserEnrolled(user.id)` → route to **PIN Setup**.
3. Setup: enter 4 digits → confirm 4 digits → on match, `enrollUser(...)` with
   the tokens just obtained → route to main screen.
4. If already enrolled → straight to main.

### Cold start (Splash)
Change `SplashBloc` decision (`lib/features/splash/domain/blocs/splash_bloc.dart`):
- `PinVaultService.hasAnyEnrolled()` → **PIN Unlock** screen.
- else token present → main screen (legacy/upgrade path).
- else → login.

### Unlock
1. User types 4 digits → `findUserByPin(pin)`.
2. **Match** → write tokens to active keys, set `x_tenant_iD`, update
   `lastUnlockAt`, `clearAttempts()`, dispatch `OnLoadProfileEvent(user:)`,
   navigate to main.
3. **No match** → `recordFailedAttempt()`, shake feedback, clear digits.
4. After 5 fails → 30s lockout (escalating: e.g. 30s, 60s, 120s, 300s);
   show countdown, disable pad.
5. **"Forgot PIN / Use a different account"** link (always visible) → full
   login → re-enroll.

### Adding another user
Same "Use a different account" link on the unlock screen → full login once →
PIN setup → now enrolled alongside existing users.

### Background resume
`AppLockController` resume elapsed > 2 min + vault non-empty → push unlock.

## Offline-data handling on user switch

Today `AuthBloc._onLoadProfile` wipes the offline DB whenever the user **id**
changes (`lib/common/auth_bloc/auth_bloc.dart:47-55`, `:92-100`). With many
cashiers of the **same business** switching via PIN, this would needlessly wipe
the shared catalog and is impossible offline.

**Change:** split the two concerns —
- **Wipe offline cache** (`clearAllOnLogout`) only when **businessId/tenant**
  differs from the current session.
- **Bump `sessionId`** (resets cart and other per-session blocs) whenever the
  **user id** differs.

So same-business PIN switches keep the catalog; a genuinely different business
still wipes.

**Flagged for backend:** pending offline sales live in the shared DB and would
sync under whichever token is active at sync time. Per-sale cashier attribution
on switch is **out of scope** here; revisit if the backend needs each sale
stamped with its creating cashier.

## Routing

New routes in `RouteStrings` and `AppRouter`:
- `pinSetupScreen`
- `pinUnlockScreen`

Both wrapped with their `PinBloc` provider (via `FeatureBlocProviders`).

## Screens (UI built later via frontend-design)

Two new screens, each responsive **mobile + desktop**, following existing
`desktop_*` widget + `LayoutBuilder` conventions:

1. **PIN Setup** — "Create your PIN" → "Confirm your PIN" two-step. 4 dots +
   numeric keypad, mismatch feedback, back/cancel.
2. **PIN Unlock** — brand/logo, 4 dots, numeric keypad, lockout countdown
   state, "Forgot PIN / Use a different account" link.

Desktop variants accept physical-keyboard digit entry (0–9, backspace, enter).

## Dependencies

- Add `crypto` (PBKDF2-HMAC-SHA256). No other new packages (biometrics excluded).

## Testing

- `PinVaultService`: enroll → `findUserByPin` match/no-match; `isPinTaken`
  uniqueness; failed-attempt counting and lockout window; multi-user vault;
  remove/clear.
- `PinBloc`: setup enter/confirm mismatch & success; unlock match → token swap +
  `OnLoadProfileEvent`; no-match attempt increment; lockout disables entry.
- `SplashBloc`: routes to unlock when vault non-empty, else legacy behavior.
- `AuthBloc` wipe refinement: same-business switch does **not** wipe; different
  business does wipe; `sessionId` bumps on user-id change.

## Risks / Open Items

- **4-digit brute force** offline — mitigated by lockout + escalation only.
  Accepted for MVP.
- **Desktop plaintext vault** — same posture as existing token storage. Accepted.
- **Sale attribution on switch** — out of scope; backend follow-up if needed.
