# PIN Management — Design

**Date:** 2026-06-22
**Status:** Approved (pending spec review)
**Area:** Authentication / user management
**Builds on:** [2026-06-22-pin-setup-unlock-design.md](2026-06-22-pin-setup-unlock-design.md)

## Summary

Two additions to the existing local-PIN system:

1. **Owner-provisioned cashier PINs** — when the owner adds a cashier, they set a
   required 4-digit PIN for that cashier, and can later change or disable it from
   the cashier's detail screen. The PIN is persisted on the **backend** as a
   cashier credential.
2. **Self PIN management** — the logged-in user can change or disable their own
   PIN from Settings → Account. These operate on the **local vault** and work
   fully offline today.

## Goals

- Owner sets a **required** 4-digit PIN when creating a cashier.
- Owner can **change** or **disable** a cashier's PIN from the cashier detail screen.
- Logged-in user can **change** or **disable** their own PIN from Settings.
- Reuse the existing PIN UI primitives (`PinDots`, `PinKeypad`, `PinScaffold`)
  and `PinVaultService` — no new visual language.

## Non-Goals / Deferred

- **Cashier unlock token-sync.** Setting a cashier's PIN does NOT yet let that
  cashier unlock the till. Unlock restores the cashier's own access/refresh
  tokens, which are not on the device at creation time. Wiring that
  provisioning/sync is owned by the project owner as a later task. This spec
  captures, persists, and manages the credential only.
- No biometrics, no PIN recovery beyond the existing "different account" login.

## Decisions (locked)

| Decision | Value |
|---|---|
| Cashier PIN at creation | **Required**, 4 digits. |
| Cashier PIN persistence | **Backend** (create/edit-cashier requests). |
| Cashier PIN management | Change + disable, from the cashier detail/edit screen. Owner only. |
| Self PIN management | Change + disable, from Settings → Account. Local vault. |
| Cashier unlock plumbing | **Deferred** — owner wires token-sync later. |

## Architecture

### Two homes for PINs

- **Cashier PIN (owner-provisioned):** lives on the backend. The app sends it on
  create and on change, and signals disable. The app does NOT create a local
  vault record for the cashier (that would be a tokenless "ghost" record that
  can't unlock). The deferred sync will populate the vault with tokens + PIN at
  cashier-provisioning time.
- **Own PIN (logged-in user):** lives in the local `PinVaultService` vault,
  exactly as the base PIN feature. Change/disable mutate the local record.

### Components

**Feature A — Cashier PIN (owner)**

1. `AddUserRequestDto` (`lib/features/users/data/models/requests/add_user_request_dto.dart`)
   — add `String? pin`; include in `toJson` when present.
2. `EditUserRequestDto` / a dedicated request — carry `pin` for change and a
   disable signal. Implemented as two use-case methods rather than overloading
   edit (clearer mapping to the BE endpoints the owner will add):
   - `UsersUseCase.setCashierPin({required String userId, required String pin})`
   - `UsersUseCase.disableCashierPin(String userId)`
   - `UsersUseCase.addUser(...)` gains a required `pin` parameter.
   Mirror these on `UsersRepository` + `UsersRepoImpl`.
3. **Add Cashier sheet** (`lib/features/users/presentation/widgets/add_user_sheet.dart`)
   — a required 4-digit PIN input (4-box secure field styled to match the app),
   validated as exactly 4 digits before submit.
4. **Cashier detail** (`lib/features/users/presentation/user_detail_screen.dart`)
   — "Change PIN" and "Disable PIN" actions (owner only, gated by
   `AppPermissions.canAccessUsers`). Change opens a 4-digit enter+confirm sheet;
   disable shows a confirm dialog.
5. `UsersBloc` events: `OnSetCashierPin`, `OnDisableCashierPin`, and `pin`
   carried on the existing add event.

**Feature B — Own PIN (Settings)**

1. **Settings Account section** (`lib/features/settings/presentation/settings_screen.dart`,
   `_AccountSection`) — two new `SettingsRowItem`s: "Change PIN", "Disable PIN".
2. **Change PIN flow** — new `PinMode.change` in `PinBloc`:
   - Step 1: enter current PIN → validate via `vault.findUserByPin`; on no match,
     error and stay.
   - Step 2: enter new PIN.
   - Step 3: confirm new PIN → `vault.changePin(userId, newPin)`.
   Reuses `PinScaffold` / `PinDots` / `PinKeypad`. Titles per step.
3. **Disable PIN** — confirm dialog → `vault.removeUser(currentUserId)`. If the
   vault becomes empty, the next cold start no longer locks (splash falls back to
   token→main, per the base spec).

**Shared**

- `PinVaultService.changePin(String userId, String newPin)`:
  - Rejects if `newPin` collides with a *different* enrolled user's PIN
    (`isPinTaken` excluding self).
  - Re-hashes with a fresh salt, preserves the user's tokens/profile, updates
    the record in place.
  - Returns a result indicating success / pin-taken / user-not-found.
- `removeUser(userId)` already exists.

### Routing

- Change-PIN (self) reached via a new route `pinChangeScreen` wrapped with a
  `PinBloc` in `PinMode.change` for the current user.
- Cashier change/disable handled in-place via bottom sheets / dialogs from the
  cashier detail screen (consistent with the existing add/edit/deactivate sheets).

## Data Flow

**Add cashier:** form (name/phone/role/**pin**) → `UsersBloc` add event →
`UsersUseCase.addUser(..., pin)` → BE. Success refreshes the list. No local vault
write.

**Change cashier PIN:** detail → change sheet (enter+confirm) →
`OnSetCashierPin(userId, pin)` → `setCashierPin` → BE.

**Disable cashier PIN:** detail → confirm → `OnDisableCashierPin(userId)` →
`disableCashierPin` → BE.

**Change own PIN:** Settings → `pinChangeScreen` → verify current → new → confirm
→ `vault.changePin`. Local only.

**Disable own PIN:** Settings → confirm → `vault.removeUser(currentUserId)`.
Local only.

## Error Handling

- Cashier PIN field: block submit unless exactly 4 digits; inline message.
- `changePin` pin-taken → "This PIN is already in use. Choose another."
- Change own PIN, wrong current PIN → "Incorrect PIN. Try again.", stay on step 1.
- BE failures on cashier set/disable → surface via the existing `GlobalSnackBar`
  pattern used by the users feature.

## Testing

- `PinVaultService.changePin`: success re-hash; wrong nonexistent user; pin-taken
  by another user; same-pin allowed for self.
- `PinBloc` change mode: verify→new→confirm success calls `changePin`; wrong
  current PIN errors; new-pin mismatch on confirm resets to the new-entry step.
- `UsersBloc`/usecase: add carries `pin`; `OnSetCashierPin` and
  `OnDisableCashierPin` call the right use-case methods and handle success/error.
- Settings rows present and route correctly (smoke).

## Risks / Open Items

- **Deferred unlock** — owner-set cashier PIN is inert until token-sync is wired.
  Documented as the owner's follow-up; the UI should not imply the cashier can
  immediately unlock.
- **Raw PIN to backend** — the create/change requests send the 4-digit PIN; the
  backend is responsible for hashing at rest. App-side it is treated as a normal
  credential field over HTTPS.
- **Disable own PIN while other users enrolled** — only removes the current
  user's record; the device still locks for the remaining enrolled users, which
  is correct.
