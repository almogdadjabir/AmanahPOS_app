# Offline-First Sync: mobile design

Date: 2026-11-16. Status: **awaiting approval**. Backend contract: [../../BE_GAPS.md](../../BE_GAPS.md).

## Intent

Amana POS is used in Sudan where connectivity is poor and the server may be down for hours. After login and first setup, **the phone is the working copy of the business**. Every feature (sales, products, categories, customers, team, stock, returns, reports) must work 100% with no server, never show a spinner for local data, and sync silently in the background in chunks, like Firebase's offline persistence. The dashboard updates the instant a sale is saved. Real money is involved, so: no lost writes, no double-applied writes, no silent divergence, proven by tests.

## Goals

- Local DB is the only thing the UI reads. Network never blocks a screen.
- Every write is one atomic local transaction (data row + outbox entry + change notification). Instant UI.
- A sync engine pushes the outbox and pulls server changes, resumably, idempotently, in small batches.
- Sync survives app kill, OS background limits and battery saver as well as the platform allows (WorkManager / BGTaskScheduler plus foreground triggers).
- "Online" means **our server answers** (`sync/ping`), not that the device has Wi-Fi.
- Login and first setup (full bootstrap incl. images) are the only online-required steps. Money/security operations stay online-only (shop create/delete, subscription, Bankak, TOTP).
- Full lifecycle test suite with a fake server and fault injection.

## Non-goals / anti-goals

- No rewrite of UI screens (Nile Ledger revamp stays). Blocs change their data source only.
- No change to the sale/receipt UX beyond showing a pending marker.
- Anti-goal: any path where a completed sale can be dropped, duplicated, or blocked by stock/price/server state.
- Anti-goal: "offline" that is really just a cache with write-through to the API.

## Approaches considered

1. **Feature-by-feature migration onto a new local-first core (chosen, as you confirmed).** Build core (outbox, engine, change notifier, fake server, tests), then migrate Sales+Stock, Catalog, Customers, Team, Dashboard/Reports, Returns. Each step ships working.
2. Big-bang data layer replacement. Cleaner end state, nothing works until everything does. Rejected on risk.
3. Adopt a sync SDK (PowerSync/Firebase/Couch-style). Needs its own server stack, conflicts with your own Django BE and the contract already written. Rejected.

Storage sub-choice (my call): **keep `sqflite`**, already in the app with data and migrations, and add a table-invalidation stream for reactive reads, instead of migrating to Drift. Lower migration risk for existing installs; Drift's typed API is not worth a second migration of live user data.

## Architecture

```
UI (Bloc) ── reads ──▶ Repository ◀── streams ── LocalDb (sqflite) ◀── writes ── SyncEngine ◀── triggers
   │                       │                          ▲  ▲                           │  ▲
   └── commands ───────────┘ (one atomic txn:         │  └ ChangeNotifier            │  └ foreground / on-write(debounced)
                              row + outbox + notify)  │                              │     connectivity / periodic / WorkManager
                                                      └──────── SyncTransport ◀──────┘
                                                         (Http impl | Fake impl for tests)
```

Layers under `lib/core/sync/` (existing folder, extended):

- **LocalDb**: existing `OfflineDb`, migration v6+. Typed columns for queried/filtered fields (not only JSON blobs) with indexes: sales(created_at, shop_id, status), products(category_id, name, barcode, sku), stock(product_id, shop_id), etc. JSON column kept for the full DTO.
- **ChangeNotifier**: after each committed transaction, emits the set of changed tables. Repositories expose `Stream<T>` via "query, re-query on relevant table change" with debounce (16 ms). This is how the dashboard updates within one frame of a sale.
- **Outbox** (`outbox` table): `mutation_id (uuid), seq (autoinc), entity, op, entity_id, base_version, occurred_at, payload_json, status (pending|inflight|done|rejected|blocked), attempts, next_attempt_at, lease_until, error_code, error_message`. Enqueue is inside the same transaction as the data write. Dependency rule: a mutation referencing an entity with a pending/rejected create is `blocked` until its dependency is applied.
- **Local-first repositories** per feature: `ProductRepository`, `CategoryRepository`, `CustomerRepository`, `UserRepository`, `StockRepository`, `SalesRepository`, `ReturnsRepository`, `DashboardRepository`. Use cases/blocs keep their current signatures where possible, the `*_repo_impl` classes swap their data source from `RequestHandler` to local + outbox.
- **Stock model**: `stock_base` (last server-confirmed quantity) plus pending deltas from the outbox. Displayed quantity = base + sum(pending deltas). Sale/adjust/transfer enqueue **deltas**, never absolutes. After a push result returns `stock_after`, base is re-based and applied deltas dropped. Negative displayed stock is allowed and flagged.
- **SyncEngine**: single-flight (in-process mutex plus DB lease so the foreground isolate and the background worker never run two syncs). Loop: `ping → push (batches of <=100 ordered) → pull (pages of 500, each page one SQLite txn, cursor advanced in the same txn) → asset sync (thumbnails first) → done`. Exponential backoff with jitter on `retry`/network errors; `rejected` items are parked with a user-visible reason and never retried automatically. Cursor and outbox state are crash-safe: kill at any point and the next run resumes.
- **Transport**: `SyncTransport` interface. `HttpSyncTransport` (Dio, gzip, 15 s timeouts, no retry interceptors that could double-send; idempotency is by `mutation_id`). `FakeSyncServer` (in-memory, implements the BE contract including conflicts, partial failures, duplicates, delays, drops) used by all tests. **Capabilities from `sync/ping` gate each feature**, so mobile can ship ahead of the backend; until a capability exists that entity stays on the existing online path with a clear "needs connection" message.
- **Reachability**: `ServerReachability` = ping with short timeout, cached 15 s, flips on first failure/success of any sync call. UI shows pending count + "last synced". No blocking banners when offline, offline is the normal state.
- **Background execution**: `workmanager` (Android WorkManager, iOS BGTaskScheduler): periodic ~15 min with network constraint + a one-off expedited task enqueued after writes (debounced 5 s). Android: stays correct under Doze because all state is in SQLite. Foreground triggers: app resume, connectivity change, after-write, manual "Sync now". Background isolate re-creates DB/transport/token access from secure storage (no GetIt state shared). Battery: no wakelocks, no polling loop; work only when outbox is non-empty or periodic pull is due.
- **Auth**: access token refresh on 401 only; refresh **never** logs the user out on timeout/5xx/offline, only on an explicit 401 from refresh or `account_disabled`/`device_revoked` from sync (then lock + wipe after the outbox is exported/kept per policy below). PIN/biometric stays as built.
- **Conflict handling in UI**: rejected mutations appear in the existing Pending Sync screen (extended) with reason and actions (Retry, Edit, Discard). Owner sees a badge count. `merged` results silently update the local row from `server_state`.
- **Local receipt numbers**: `L-<shopcode>-<n>` per device, replaced by the server's number when synced. Receipts reprint with whichever number is current.
- **Dashboard/Reports**: `DashboardRepository` computes aggregates in SQL over local sales/refunds/payments following the server's documented rules. Debug-only parity check against `dashboard-summary` when online, plus periodic `sync/checksum` self-audit that triggers a repair resync on mismatch.
- **Data retention on device**: sales window 90 days (BE param), older on demand online. Tombstones applied then removed.
- **Logout with unsynced data**: blocked with an explanation and an option to sync now; forced sign-out (account disabled) keeps the outbox in a quarantine table for support export.

## Test strategy (the "full lifecycle" suite)

Pure Dart tests with `sqflite_common_ffi` (in-memory) and `FakeSyncServer`:

1. **Unit**: outbox enqueue atomicity (data+outbox+notify all or nothing), dependency blocking, stock = base + deltas, backoff scheduling, lease/single-flight, cursor persistence.
2. **Engine scenarios**: happy path; server down for hours then up; flaky link (random drops mid-batch); duplicate delivery (response lost, retry) is a no-op; app killed between push and result write; app killed mid-pull page; partial batch failure; rejected item parked; dependency chain rejection; `full_resync_required`; token expired mid-sync; account disabled.
3. **Convergence/property tests**: random interleavings of N devices doing offline sales/adjusts/edits then syncing in random order always converge to identical local and server state, and stock equals the arithmetic sum.
4. **Lifecycle journeys**: first login + bootstrap (resumable, interrupted at 90%), day of offline trading (sales, new product, new category, stock count, customer, return), reconnect, second device sees all, owner deactivates cashier, logout guard.
5. **Money invariants**: sum of local sales == server after sync; no sale lost/duplicated across 1,000 randomized runs; refund guard on concurrent refund.
6. **Perf budgets** (enforced in tests): product list/search < 16 ms on 20k products, sale save < 50 ms, dashboard re-query < 30 ms on 50k sales, cold start to POS < 1 s with local data.
7. Widget tests on touched screens: offline state renders from local, pending badge, rejected-item flow.
8. One on-device smoke checklist (airplane mode, kill app, low battery mode) documented in `docs/offline.md`.

## Delivery phases (each ends with tests green and app working)

0. Core: DB v6 migration (additive), ChangeNotifier, Outbox, SyncTransport + FakeSyncServer, SyncEngine, reachability, engine tests.
1. Sales + Stock on the new core (replaces `OfflineSalesQueue`/`OfflineInboundQueue`; migrates existing pending rows), Pending Sync screen on outbox, background worker.
2. Pull/bootstrap on the change feed (paged, resumable), assets by hash.
3. Catalog: categories, products (incl. image upload), vendors.
4. Customers, Returns/refunds.
5. Team (users) with invite-pending state.
6. Dashboard/Reports local aggregates + parity/checksum audit.
7. Hardening: perf budgets, battery, on-device checklist, docs.

## Constraints

- Existing installs must migrate without data loss (v5 to v6 additive, pending sales carried into outbox before the old tables are dropped in a later release).
- Contract fields/status/codes are exactly those in BE_GAPS.md; deviations are noted in the BE repo's `docs/sync-contract-deviations.md` and adopted here.
- No git operations by me except `git add` when you ask.

## Left to the builder

Exact table column sets, index choices, batch/page sizes (defaults above), WorkManager intervals, backoff constants, Pending Sync screen visual details (follows Nile Ledger).

## Open questions for you

1. Offline-created team members: OK that they cannot log in until their invite is delivered after sync?
2. If an owner force-deactivates a device/user with unsynced sales, we quarantine the outbox for support instead of deleting it. OK?
3. Is 90 days of local sales history enough for reports without a connection?
