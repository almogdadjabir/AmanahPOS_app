# Phase 2: paged bootstrap, pull appliers, assets by hash

Date: 2026-11-16. Status: **implemented** (Tasks 1-12 of `docs/superpowers/plans/2026-11-16-phase2-bootstrap-pull-assets.md`, 2026-11-17). Parent spec: [2026-11-16-offline-first-sync-design.md](2026-11-16-offline-first-sync-design.md). Contract (read-only): `amanaPOS-be/docs/sync-contract.md`, `sync-contract-deviations.md` (items 18-23), [../../BE_GAPS.md](../../BE_GAPS.md).

## Intent

Amana POS is used in Sudan on weak links; the phone is the working copy of the business. Phase 0/1 built the push side and the sales/stock/inbound pull appliers. Today catalog data (business, shops, categories, products, customers, vendors) still enters SQLite through the legacy one-blob `offline/bootstrap/` + `OfflineFirstManager`, which writes outside the outbox/applier rules, cannot resume, and restarts from zero if a 5 MB response fails at 90%. Phase 2 makes the sync core the ONLY way server data enters the device: a resumable paged first setup, a pull applier for every feed entity, and images downloaded by content hash. Real money is involved, so a half-finished or wrong-tenant setup must never look complete.

## Goals

- First setup (no cursor for this scope) downloads every visible entity page by page, resumable after kill/offline/token loss, then continues with `pull` from the server's `snapshot_cursor` and misses nothing written during the download.
- Appliers for all feed entities, so bootstrap rows and pulled rows take ONE code path (`ChangeApplier.apply`).
- Images downloaded only when `image_hash` differs from the local file's, verified by sha256, thumbnails first, never blocking first setup and never losing an existing image on failure.
- Legacy `OfflineFirstManager.refreshBootstrap`, `getBootstrap`, asset manifest-by-`updated_at` and their triggers are retired.
- Tests with `FakeSyncServer` extended for paged bootstrap and fault injection (the existing convergence test grows a bootstrap-in-the-middle scenario).

## Non-goals / anti-goals

- No write paths for catalog/customers/team (Phases 3-5). Blocs that read "cache then REST" keep doing so; they now read SQLite that the new appliers fill.
- No local refund creation (Phase 4). Pulled refunds fill `sale_refunds`; refunds made on this device stay REST until Phase 4 (must land before real use, unchanged).
- No dashboard/reports changes, no checksum audit (Phase 6).
- No BE edits. BE needs go to `docs/BE_GAPS.md`.
- Anti-goal: any state where the app lets the user in as "ready" while the catalog is partial, or where bootstrap for tenant A leaves rows visible under tenant B.
- Anti-goal: deleting or rolling back local data that has unsynced edits.

## Constraints

- Zero users: no data migration; DB version bump is additive (and may drop legacy tables/columns).
- Never run git except `git add` when asked. Foreground tests only.
- Cursor, bootstrap progress, and rows are **scope-keyed** (`userId|tenantId`) like Phase 1; background worker and app must not both bootstrap (`sync_lock`).
- Typed 401 handling, scope checks and "never log out on network/5xx" rules from Phase 0 apply to every new request.
- Contract facts: no backfill, so no cursor means bootstrap required (deviation 18); keyset `page_cursor`, not page numbers (21); catalog bootstrap includes inactive rows (21); `sales_since` default 90 days, refunds windowed by refund date OR parent sale date (22); `image_hash` = sha256 of the **uploaded** bytes, legacy rows may have an empty hash (23); cashier scope (shared products + own shop, own user row only, no vendor/inbound); `full_resync_required` when the cursor is older than `pruned_through`, malformed or ahead; feed rows carry `version`, `origin_device_id` (own echo ignored), `shop_id`; `delete` also means "no longer visible to you".

## Approaches (decided with you)

- **A. Separate `Bootstrapper` beside the engine (chosen).** Runs when the engine returns `needsBootstrap`, under the same scope / `sync_lock` / token rules. Persists per-entity progress in `sync_state` (scoped). Feeds each page to the same appliers pull uses. Sets the pull cursor only when finished. Easy to test resumability and drive a progress screen.
- B. Bootstrap phase inside `SyncEngine.run`: fewer files but the engine is already ~1,100 lines and a long interruptible UI-visible run conflicts with the 25 s background budget and the single-run lease model.
- C. Keep legacy bulk bootstrap, add pull after: smallest, but two writers and the 90% restart remain.

## Design

### 1. Transport

`SyncTransport` gains `bootstrapManifest({scope})` and `bootstrapPage({entity, pageCursor, limit, snapshotCursor, salesSince, scope})`, DTOs `BootstrapManifest {entities, snapshotCursor, serverTime}` and `BootstrapPage {entity, snapshotCursor, items, hasMore, nextPageCursor}` in `sync_contract.dart`. `HttpSyncTransport` and `FakeSyncServer` implement them (typed errors, scope-bound auth, 15 s timeouts, gzip), same error mapping as `pull`. Capability gate: `bootstrap_paged` (plus `push`,`pull`) from `sync/ping`; without it first setup shows "update the server / try later" and never falls back to the legacy blob.

### 2. Bootstrapper

State (scoped keys in `sync_state`): `bootstrap_snapshot` (cursor from the manifest), `bootstrap_entities` (ordered list from the manifest), `bootstrap_done` (entities finished), `bootstrap_page_cursor` (per current entity), `bootstrap_started_at`. All written in the same transaction as the page's rows.

Run:
1. Preconditions: engine gate (token, ping capabilities, scope matches live session), acquire `sync_lock`.
2. If no stored snapshot: fetch manifest, store snapshot + entity list. If one exists, **reuse it** (resume); never take a new snapshot mid-bootstrap, so the pull continues from the original seq and misses nothing. **Staleness is detected only by `pull`** (verified in the BE: `bootstrap_page` just echoes the snapshot and never validates it; `pull` answers `full_resync_required` when the cursor is older than `pruned_through`). So a bootstrap that spans a prune window finishes, then its first pull returns `full_resync_required`; the engine restarts the bootstrap with a fresh snapshot. To prevent a loop, a second `full_resync_required` right after a bootstrap that just completed backs off (engine backoff, loud log) instead of restarting immediately. `BootstrapPage` therefore needs no resync flag.

   **Item shape (verified in BE `apps/sync/feed.py`/`pull.py`):** a bootstrap `items[]` row is exactly the feed row's `data` (`feed.serialize` is shared), including `id` and `version` (stock/expiry_batch have no `version`, treated as 0; sale rows carry nested items/payments exactly as in the feed). Bootstrap items have NO `seq`, `origin_device_id` or `shop_id` wrapper fields. The synthetic `PullChange` therefore uses `seq = 0`, `originDeviceId = null` (no echo filtering needed: a bootstrap is never an echo) and `shopId` taken from the row's own `shop`/`shop_id` field where the applier needs it. Appliers must not read anything from the change wrapper that the item does not carry; a contract test pins one real-shaped item per entity (copied from the BE serializers) through the applier.
3. Entities in dependency order: `business`, `shop`, `category`, `product`, `vendor`, `customer`, `user`, `subscription`, `bankak_account`, `stock`, `expiry_batch`, `sale` (items+payments), `refund`, `inbound`, `notification`. Entities the manifest does not list (cashier) are skipped. Unknown entity names are logged and skipped (never crash).
4. Per page: one SQLite transaction = wrap each item as a synthetic upsert `PullChange` (id from item, `version` from item, `data` = item) -> `ChangeApplier.apply` -> advance `bootstrap_page_cursor`; on the last page of an entity mark it done in the same transaction. Notify changed tables after commit.
5. When all entities are done: in ONE transaction set the pull cursor = stored snapshot, clear bootstrap state, mark the scope "bootstrapped". Engine then runs a normal pull.
6. Crash/kill/offline/cancel at any point: next run resumes at the stored page cursor. Replaying a page is idempotent (appliers are idempotent by id + version).
7. Bootstrap rows respect the same local-edit rules as pull: `skipWhenLocalPending` rows are deferred through the existing `deferred_pull` mechanism rather than overwritten, versions never roll a row back. Rows whose parent is not yet present (e.g. stock before product from a cashier-scoped feed) are applied anyway; local tables have no FK enforcement and entity order makes this rare.
8. Cashier scope and role changes: a bootstrap response is the truth for what this user sees; after the final transaction, rows of the scope that were not seen in the bootstrap and have no unsynced outbox rows are NOT deleted in Phase 2 (stale rows are corrected by later `delete` changes or `full_resync_required`); documented limitation.

Triggers: `SyncOutcome.needsBootstrap` (engine, triggers, background worker) starts the Bootstrapper in the foreground app. The **background worker never bootstraps** (it only reports `needsBootstrap` and leaves it to the app), to keep it inside the 25 s budget and avoid UI-invisible multi-MB work.

`full_resync_required` from `pull`: engine already calls `_resetForBootstrap` (today it does `_st.clear()`, which also wipes `deferred_pull`). Extended to: clear the cursor and any old bootstrap progress, mark "bootstrap required", **keep the existing local rows visible** (the app stays usable offline while the refresh runs) and keep the outbox untouched. Dropping the OLD deferred pulled changes is correct (the new bootstrap re-sends current server state). Rows the NEW bootstrap skips because they have unsynced outbox rows are written to `deferred_pull` during the bootstrap and are NOT cleared by the final transaction, so the next pull applies them once their outbox rows resolve. `SyncStateStore.clear()` is split so the reset path does not clear bootstrap's own deferrals after they are written.

**Two distinct states** (a scoped flag `bootstrapped`, set by the final transaction and cleared only by logout of that scope's data wipe, never by `full_resync_required`): *never bootstrapped* = blocking first-setup screen; *bootstrapped but cursor reset* = non-blocking refresh with a small progress indicator, app fully usable from local data. The engine's `needsBootstrap` check keeps using "no cursor"; the UI readiness gate (`OfflineStatusBloc`/router) uses `bootstrapped`.

### 3. Appliers (read side)

New `ChangeApplier`s registered in `buildSyncAppliers()`: `business`, `shop`, `category`, `product`, `customer`, `vendor`, `expiry_batch`, `refund`, `user`, `subscription`, `notification`, `bankak_account`. Existing `stock`, `sale`, `inbound` appliers are reused unchanged except for a shared "item shape" check. Each:

- `apply(upsert)` writes typed columns + keeps the full JSON where the table has one; `apply(delete)` removes the row (tombstone) or hides it (`is_active=0` only when the feed says `upsert is_active:false`).
- Versioned entities (`category`, `product`, `customer`, `vendor`, `shop`, `user`, `business`) implement `localVersion` so older/equal versions never overwrite.
- Own-write echo: rows whose `origin_device_id` equals this device are ignored unless the local row lacks that version (so a lost push result is healed by the echo).
- `onPushResult`: no-op for entities Phase 2 does not write (Phases 3-5 fill them in). `tables` lists the local tables written.
- Money as strings -> integer cents/milli handling via existing helpers (`decimal3`); a malformed row is skipped and logged, never poisons a page (Phase 0 rule M1).
- Product `image`/`thumbnail_url`/`image_hash` are stored; changing `image_hash` marks the asset stale (section 4).
- Local schema: add only what the feed carries and the UI reads (`image_hash`, `version`, `thumbnail_url`, `is_active`, `unit`, `expiry_alert_days`, `sale_refunds` already exists for Phase 4 reads). DB version bump is additive.

### 4. Assets by hash

- Source of truth is the feed/bootstrap rows (`image`, `thumbnail_url`, `image_hash`), not the legacy manifest. `offline_assets` is reshaped to `(type, id, variant: thumb|full, url, expected_hash, local_path, local_hash, bytes, state, attempts, next_attempt_at)`; zero users so no migration.
- `AssetSync` runs after the engine's pull (and once after first-setup finishes), never inside the pull transaction: select rows where `expected_hash != local_hash` (or no file), thumbnails before full images, small batches, concurrency 2-3.
- Download to a temp file, compute sha256, compare with `expected_hash`. Mismatch -> discard temp, back off, keep the previous file. Success -> atomic rename, update row, notify. For rows with an **empty** `image_hash` (legacy BE rows, deviation 23) fall back to "download once, key by url"; they never loop.
- Never delete the old file before the new one is verified. Orphans (row deleted or hash changed) are removed on a later pass.
- Network: `Dio` with the sync auth/headers only for the BE host; short timeouts, resumable by simply retrying the file; no download when `ping` fails; budgeted per run by count/bytes (thumbnails first) so metered data and the background budget are respected. The background worker may download thumbnails only, within its time budget.
- UI reads `localPath` when present, else the thumbnail/remote URL fallback already used; images never block a screen.

### 5. First-setup UX (your decision: blocking with progress)

When the scope has no cursor, the app shows a first-setup screen (Nile Ledger style, reuse existing offline-preparation listener slot) with: step list (shops/catalog/stock/sales...), per-entity progress, byte-light "N of M" counts from page sizes, retry and a clear offline message ("Internet is required only for first setup"), resumable on relaunch. It unblocks the app when the final transaction commits (ALL entities including the 90-day sales window, ordered last, so a user never sees partial revenue or an incomplete catalog as if complete; the cursor is only set then anyway), not when images finish; thumbnails then fill in ("Images downloading" non-blocking indicator). HTML mockup first per the UI revamp workflow, approved before coding.

### 6. Retire legacy

Remove `OfflineFirstManager.refreshBootstrap` / `initializeAfterLogin` bootstrap path, `OfflineRemoteDataSource.getBootstrap`, `getAssetManifest`, `saveBootstrap`, `saveAssetManifestPreservingDownloads`, network-reconnect bootstrap triggers, and `hasBootstrapCache` (replaced by "scope bootstrapped" from `SyncStateStore`). `OfflineStatusBloc` derives readiness from sync state. Blocs and readers keep their public signatures. `clearAllOnLogout` semantics preserved (never delete unsynced sales/outbox).

## Risks and the tests that guard them

- Missed writes during a long bootstrap -> FakeSyncServer writes rows between pages; after finishing, pull from `snapshot_cursor` yields them; final DB equals server (convergence + bootstrap).
- Resume correctness -> kill after every page boundary and mid-page (fault injection), assert no dup/lost rows and a single snapshot.
- Wrong-tenant / session switch mid-bootstrap -> `scopeChanged` aborts quietly; progress is per scope.
- Cashier scope: only visible entities requested; role-limited fakes.
- Stale cursor on resume -> bounded restart.
- Hash verify: corrupted download never replaces a good file; empty-hash rows terminate.
- Page with malformed row, unknown entity, inactive rows, 20k products perf (applier throughput budget, one txn per page).
- Offline at first setup -> clear blocked state, no partial "ready".
- Full suite (807) stays green; `CONV_SEEDS=200` before sign-off; analyzer count not worse than 74.

## Left to the builder

Page size (default 500, BE max 1000; smaller for `sale`), exact local column sets/indexes, asset concurrency and byte budgets, backoff constants, screen layout, naming of new state keys.

## Calls I made (override any)

1. The background worker never bootstraps.
2. Bootstrap does not delete unseen stale rows in Phase 2 (limitation documented).
3. Bootstrap uses the **same appliers** as pull (no second code path), via synthetic upserts.
4. Missing `bootstrap_paged` capability = blocked first setup, no legacy fallback.
5. First setup unblocks when EVERYTHING (incl. 90-day sales) is committed, images follow. On a weak link sales are the slowest part; this trades first-setup time for never showing partial history. `sales_since` is fixed at 90 days (the BE default), not configurable in Phase 2.
7. Role/business change: scope key is `userId|tenantId`; a role change for the same user does not trigger a re-bootstrap in Phase 2 (stale role-hidden rows are removed by later `delete` changes or `full_resync_required`). Revisit in Phase 5 (team).
8. The plan starts with an audit task: map every legacy reader of `OfflineLocalCache` / `offline_*` tables (columns, JSON blobs) to what the new appliers write, and where `OfflinePreparationListener` and the login/logout init path hook in, BEFORE any legacy code is removed.
6. Entity order is fixed in the client (dependency-friendly), not the manifest's order.
