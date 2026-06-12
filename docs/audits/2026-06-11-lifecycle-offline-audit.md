# App Lifecycle & Offline/Online Handling Audit

**Date:** 2026-06-11
**Scope:** App startup → auth → main session → logout; connectivity detection; offline queueing; sync; local cache consistency; error handling.

Severity legend: 🔴 Critical (causes data loss, wrong data, or app unusable) · 🟠 High (visible instability) · 🟡 Medium (correctness/UX gaps) · ⚪ Low (hygiene)

---

## 🔴 Critical

### C1. Forced logout never navigates — user stuck with a dead session
`lib/core/network/app_interceptors.dart:166-186`
`_navigateToLoginSafely()` gets the navigator and then executes a bare `return;` — **it never pushes the login route**. When the refresh token expires, `_triggerForcedLogout()` wipes the tokens and then... nothing. The user stays on the current screen; every subsequent request fails with the session-expired sentinel, which `RequestHandler` maps to `Left(null)` → blocs show `'Failed to ...'` or nothing. This presents exactly as "the app randomly stops working until you kill it."

Also: forced logout clears tokens but does **not** clear the offline DB or reset `OfflineStatusBloc`/`AuthBloc` (unlike the normal logout in `auth_bloc.dart:121-178`), so state is left inconsistent.

**Fix:** actually navigate (`pushNamedAndRemoveUntil(RouteStrings.splash)`), and route the forced logout through the same cleanup path as `OnLogoutEvent` (or dispatch an `AuthBloc` event instead of doing it inside the interceptor).

### C2. Bootstrap refresh overwrites locally-deducted stock while sales are still pending
`lib/core/offline/data/offline_local_cache.dart:28-189` (`saveBootstrap`) + `lib/core/offline/presentation/bloc/offline_status_bloc.dart:99-116`
Offline sales deduct stock locally (`offline_sales_queue.dart:319`). On reconnect, `_backgroundRefresh()` and `_backgroundSyncSales()` are fired **concurrently** (`offline_status_bloc.dart:113-114`). `saveBootstrap` deletes and rewrites the entire `stock`/`products` tables with server values that **do not yet include the unsynced sales**. Result: stock counts jump back up while sales are still queued → cashier can oversell; quantities visibly "flicker" wrong. There is also no bootstrap re-fetch after the sales sync completes, so local stock stays inflated until the next reconnect.

**Fix:** order the reconnect flow: sync pending sales → then refresh bootstrap. While any `pending/syncing` sales exist, either skip the stock overwrite or re-apply pending deductions on top of the fresh bootstrap inside the same transaction.

### C3. Refresh-token 401 can deadlock the interceptor
`lib/core/network/app_interceptors.dart:64-112, 115-146`
The refresh call (`api-public/v1/auth/token/refresh/`) is made with the **same `_dio` instance that has this interceptor installed**. If that call itself returns 401, `onError` runs again, finds `_refreshTokenFuture` non-null, and awaits it — but that future can't complete because it is blocked inside this very interceptor. Circular wait: every request from then on hangs until the 3-minute timeout. Use a separate bare `Dio` for the refresh call, or skip the 401 handler for the refresh path.

### C4. No crash/error reporting wired up at all
`lib/main.dart`
`firebase_crashlytics` is in `pubspec.yaml`, but `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and Crashlytics recording are never set up. Combined with the heavy use of `unawaited(...)` and silent `catch (_) {}` blocks across the offline stack, **failures in production are completely invisible** — which is why the instability is hard to pin down. Wire up:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (e, s) { FirebaseCrashlytics.instance.recordError(e, s, fatal: true); return true; };
```

### C5. Hard-coded debug proxy breaks all networking in debug builds
`lib/core/network/dio_client.dart:20-36`
In `kDebugMode` every request is forced through `PROXY 172.16.10.52:9099` and certificate validation is disabled. If that machine isn't running Proxyman on that LAN IP, **every network call in a debug build fails or hangs** — this alone explains a large share of "it's not stable" during development, and behavior differs between debug and release. Gate it behind an env flag (`--dart-define=USE_PROXY=true`) instead of `kDebugMode`.

---

## 🟠 High

### H1. 3-minute timeouts block the POS flow
`lib/core/network/dio_client.dart:7-8`
`connectTimeout` and `receiveTimeout` are both **3 minutes**. `PosRepoImpl.submitSale` checks `NetworkMonitor.isOnline`, which only checks the network *interface* (wifi connected ≠ internet works). On wifi-without-internet or a down server, checkout hangs up to 3 minutes before the sale falls back to the offline queue. For a POS, the online attempt should give up fast (8–15s) and queue offline. Set sane global timeouts (~30s) and a short per-request timeout on `createSale`.

### H2. Sync only runs on connectivity *changes* — pending sales can sit forever while online
No periodic sync exists (verified: no `Timer.periodic` touches `SyncManager`). Triggers are: connectivity transition (`offline_status_bloc.dart:112-115`), `OnOfflineStatusStarted` (login/business load), and manual "Retry All". If a sale fails to sync (server hiccup, one bad batch) and the connection never flaps, **nothing retries it**. Likewise `failed` sales are only retried when a full sync runs. Add a periodic sync timer (e.g., every 1–2 min while pending count > 0) — this is the standard fix for "sales stuck in pending".

### H3. No app-lifecycle observer — resume does nothing
Only `barcode_scanner_screen.dart` observes `AppLifecycleState`. When the app returns from background (mobile) or wakes from overnight idle (desktop POS), there is no connectivity re-check, no sync kick, no bootstrap refresh. Connectivity events that happened while suspended are missed, so the app can show "offline" while online (or vice versa) and hold pending sales indefinitely. Add a root `WidgetsBindingObserver` that on `resumed`: re-checks `isOnline`, emits the status, and triggers sync.

### H4. `SyncManager` throttle is dead code + exceptions leak through `unawaited`
`lib/core/sync/sync_manager.dart:55-72`
`_lastSyncAt` is set at the start and **reset to `null` in `finally`**, so the 20-second `_kMinSyncInterval` never throttles anything (concurrency is already covered by `_syncingSales`). Every connectivity flap fires a full sync + full bootstrap + asset download. Meanwhile `syncPendingSales()` rethrows network failures; most callers catch, but any `unawaited` caller (e.g., `offline_first_manager.dart:83,105,176`) turns that into an unhandled async error. Fix the throttle (keep `_lastSyncAt` on success, allow manual "Retry All" to bypass) and make `syncPendingSales` not throw for routine network failures.

### H5. Reconnect triggers a redundant double/triple refresh storm
`offline_status_bloc.dart:99-116`: on every online transition it runs `_backgroundRefresh()` (→ `_refreshAll` → bootstrap + asset manifest + sales sync) **and** `_backgroundSyncSales()` in parallel. `NetworkMonitor` (`network_monitor.dart:20-25`) emits raw `connectivity_plus` events without `distinct()` — wifi↔vpn transitions, etc., each re-trigger a full catalog download and asset sweep. On flaky networks this is a constant background hammering that competes with checkout traffic. Debounce + `distinct()` the monitor stream and make reconnect work sequential: sync sales → bootstrap → assets.

### H6. `OfflineFirstManager.initializeAfterLogin()` is dead code
Never called anywhere (verified). Its network watcher (`_startNetworkWatcherOnce`) and the `blockedNeedsFirstOnlineSync` result are unused — `OfflineStatusBloc` duplicates the same logic. Two parallel "offline-first orchestrators" exist, one dead. Delete it (or consolidate into it) so there is exactly one owner of the reconnect/sync policy.

---

## 🟡 Medium

### M1. `isOnline` = interface check, not reachability
`network_monitor.dart:15-18`. Everything (submit gating, logout gating, sync gating) trusts `connectivity_plus`, which only says "wifi is connected". A captive portal or dead upstream makes the app behave "online" and hit 3-minute timeouts everywhere (see H1). Consider a lightweight reachability probe (HEAD to your API) cached for ~10s, at least for the POS submit and logout gates.

### M2. Sales stuck in `syncing` until the *next* sync attempt
`sync_manager.dart:80` resets stuck `syncing` rows only at the start of the next run. If the app is killed mid-sync, those sales count toward the logout-blocking count and don't display as retryable until another sync trigger happens (see H2). Reset stuck rows at app startup too.

### M3. Logout requires online + fully synced, but the failure leaves loading state inconsistencies
`auth_bloc.dart:121-178`. Reasonable policy, but note: a sale stuck in `failed` does not block logout and is then **deleted** by `clearAllOnLogout` (`offline_local_cache.dart:1012-1013`) — a failed-but-valid sale (e.g., failed due to a transient 503 mis-classified as failure) is silently lost money. Since `markFailed` is applied for *any* non-synced result (`sync_manager.dart:100-104`), transient server errors land in `failed`. Distinguish retryable vs. permanent failures, and warn before logout deletes failed sales ("2 failed sales will be discarded").

### M4. Splash auth check is token-presence only + fixed 1.8s delay
`splash_bloc.dart:26-40`. Fine for MVP, but combined with C1 (broken forced logout), an expired refresh token still routes to the main screen and the user lands in the dead-session state. Once C1 is fixed this is acceptable; consider validating/refreshing the token during splash.

### M5. Business load short-circuits on cache and never refreshes
`auth_bloc.dart:194-207`. If a cached business exists, the server is never consulted that session — subscription status (`SubscriptionExpiredScreen` gating) can stay stale indefinitely on a device that's always "warm". Refresh in the background after serving the cache.

### M6. Preparing-screen pending-close flag can cancel the next legitimate show
`offline_preparation_listener.dart:254-265`. `_closePreparingScreen` sets `_pendingClosePreparing = true` and, when the screen isn't showing, returns **without ever resetting it**. The next show attempt (first bootstrap!) sees the stale flag and skips showing once. Reset the flag when no close is actually scheduled.

### M7. Inbound sync error handling conflates business rejection with network failure
`sync_manager.dart:111-148`: any error → `markFailed`. A rejected inbound (validation) and a network blip look identical, and `getPending` retries `failed` rows forever — permanently-invalid rows are re-sent on every sync, every reconnect, indefinitely. Add a retry-count / permanent-failure status.

---

## ⚪ Low / hygiene

- `dio_client.dart:18` — `dio = dio;` self-assignment (no-op).
- `app_interceptors.dart:159-163` — `isLoggingOut` reset via 4-second `Future.delayed` is a race window; tie it to actual navigation completion.
- `request_handler.dart:160-162` — PATCH errors logged with context `'PUT $path'` (copy-paste).
- `offline_status_bloc.dart` is registered as a lazy **singleton** (`dependencies_provider.dart:332`) but also handed to a `BlocProvider` (`providers.dart:44-46`) — make sure nothing ever closes it via the provider, or it's dead for the rest of the process.
- `splash` delay (1800ms) + progress bar animation are pure waiting; consider starting the token check immediately and holding only the remaining animation time.
- `OfflineSalesQueue.enqueueSale` uses `ConflictAlgorithm.abort` — a UUID collision is practically impossible, but a double-tap on checkout that reuses state would throw an unhandled exception; PosBloc catches it generically, OK.

## What is solid 👍

- Client-generated `client_sale_id` (UUID) is sent on both the online `createSale` and offline sync paths → server-side dedupe is possible (verify the backend actually dedupes on it).
- Offline sale enqueue + stock deduction happen in a single SQLite transaction.
- Token refresh single-flights concurrent 401s and restores multipart bodies on retry.
- Logout is gated on pending sales, and cross-user cache wipe on user switch is handled.
- Asset manifest preserves already-downloaded files (`saveAssetManifestPreservingDownloads`).

## Recommended fix order (MVP stabilization)

1. **C5** debug proxy (1 line gate) — restores stable dev environment immediately.
2. **C1** forced-logout navigation + full cleanup.
3. **C4** Crashlytics wiring — visibility for everything else.
4. **H1** timeouts (global 30s, `createSale` ~10s).
5. **C2 + H5** reconnect sequencing: debounce/distinct connectivity → sync sales → bootstrap → assets; don't clobber stock while sales pending.
6. **H2 + H3** periodic sync timer + root lifecycle observer (resume → recheck + sync).
7. **C3** separate Dio for token refresh.
8. **H4/H6/M-items** as cleanup passes.
