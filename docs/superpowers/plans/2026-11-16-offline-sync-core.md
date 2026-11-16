# Offline Sync Core (Phase 0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the local-first core (atomic local writes + outbox + change notifier + sync engine + transport + fake server + tests) that every feature migrates onto in Phases 1-7.

**Architecture:** All UI reads and writes hit SQLite. A write is one transaction that changes the row, appends an outbox mutation, and (after commit) notifies readers. A single-flight `SyncEngine` runs `ping -> push -> pull` against a `SyncTransport` (HTTP in prod, `FakeSyncServer` in tests), idempotent by `mutation_id`, resumable at any crash point.

**Tech Stack:** Flutter 3.44 / Dart ^3.9, `sqflite` (existing), `sqflite_common_ffi` (dev, in-memory tests), `dio`, `uuid`, `connectivity_plus`, `get_it`, `flutter_test`, `mocktail`.

**Spec:** [../specs/2026-11-16-offline-first-sync-design.md](../specs/2026-11-16-offline-first-sync-design.md). Backend contract (field names, statuses, codes): [../../BE_GAPS.md](../../BE_GAPS.md).

**Later plans (not in this one):** P1 Sales+Stock+background worker, P2 pull/bootstrap/assets, P3 Catalog, P4 Customers+Returns, P5 Team, P6 Dashboard/Reports, P7 Hardening.

## Global Constraints

- **No users exist: no data migration.** Legacy `pending_sales`, `pending_sale_items`, `pending_inbound_transactions` are left untouched in Phase 0 (Phase 1 deletes them). New tables are added in DB version 6 via `onCreate` and `onUpgrade (<6)`.
- **Git: never commit/push.** Memory rule: only `git add` when the user asks. Every "Checkpoint" step is `flutter test` + `flutter analyze`, not a commit.
- Contract strings are exact: statuses `applied|duplicate|rejected|retry`; codes `forbidden, limit_exceeded, validation_error, not_found, conflict_version, conflict_unique, dependency_failed, dependency_pending, entity_deleted, subscription_inactive, server_busy, payload_too_large, token_expired, account_disabled, device_revoked, refund_exceeds_sold`.
- Push batch <= **100** mutations (BE max 200); pull page **500**; ping timeout 5 s; push/pull timeout 15 s; **no automatic HTTP retry interceptor on sync calls** (idempotency is by `mutation_id`).
- Money/decimals travel as **strings** in payloads, never `double`.
- DB access always through `OfflineDb.instance.database` (or injected `Database` in tests). Timestamps stored/sent as UTC ISO-8601.
- Capabilities from `sync/ping` gate features; unknown capability = feature stays on the legacy online path.
- Follow repo style: `lib/core/...` snake_case files, feature tests mirror `lib/` under `test/`.

## Review Focus

1. Arabic/unicode and 1 MB+ payloads in `payload_json` round-trip intact (Task 3).
2. Process killed between server applied the batch and the app wrote results: replay must be a no-op, no duplicate rows (Task 10).
3. Lease expires while a sync is still running (slow link): second runner must not double-push (Task 9).
4. Device clock wrong by hours/days: `occurred_at` kept, skew recorded, no ordering by wall clock (Tasks 8, 9).
5. Server reports `min_app_version` above the installed app: sync stops with a typed state, outbox untouched (Task 9).

## File Structure

```
lib/core/sync/
  sync_schema.dart              DDL + table-name constants for outbox / sync_state
  db_change_notifier.dart       table-invalidation stream + watch<T>()
  outbox/outbox_entry.dart      OutboxEntry, OutboxStatus
  outbox/outbox_store.dart      enqueue/claim/results/leases/counts
  local_writer.dart             atomic write helper (txn + outbox + notify)
  contract/sync_contract.dart   PushRequest/PushResult/PullResponse/PingResponse + enums
  transport/sync_transport.dart interface + SyncTransportException
  transport/http_sync_transport.dart
  reachability.dart             ServerReachability
  sync_state_store.dart         cursor, device_id, skew, last_synced_at
  change_applier.dart           ChangeApplier interface + registry
  sync_engine.dart              SyncEngine, SyncStatus
  sync_triggers.dart            resume/connectivity/after-write triggers
test/core/sync/
  support/test_db.dart          in-memory sqflite_ffi DB factory
  support/fake_sync_server.dart
  ...one test file per unit + engine_scenarios_test.dart + convergence_test.dart
```

Existing `lib/core/sync/sync_manager.dart` stays until Phase 1.

---

### Task 1: Test harness and schema v6

**Files:**
- Modify: `pubspec.yaml` (dev: `sqflite_common_ffi: ^2.3.3`)
- Modify: `lib/core/offline/offline_db.dart` (version 6, `OfflineDb.forTesting(Database)`, create sync tables)
- Create: `lib/core/sync/sync_schema.dart`
- Create: `test/core/sync/support/test_db.dart`
- Test: `test/core/sync/sync_schema_test.dart`

**Interfaces:**
- Produces: `SyncSchema.createAll(DatabaseExecutor)`; table constants `SyncTables.outbox = 'outbox'`, `SyncTables.syncState = 'sync_state'`; `Future<OfflineDb> openTestDb()` returning an in-memory `OfflineDb` with full schema; `OfflineDb.forTesting(Database db)`.

Tables: `outbox(seq INTEGER PRIMARY KEY AUTOINCREMENT, mutation_id TEXT UNIQUE NOT NULL, entity TEXT NOT NULL, op TEXT NOT NULL, entity_id TEXT NOT NULL, depends_on_entity_id TEXT, base_version INTEGER, occurred_at TEXT NOT NULL, payload_json TEXT NOT NULL, status TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, next_attempt_at TEXT, lease_until TEXT, error_code TEXT, error_message TEXT, created_at TEXT NOT NULL)` with indexes on `(status, seq)` and `(entity, entity_id)`; `sync_state(key TEXT PRIMARY KEY, value TEXT, updated_at TEXT NOT NULL)`.

- [ ] **Step 1: Write failing test** `sync_schema_test.dart`: `openTestDb()` then `PRAGMA table_info(outbox)` contains columns `mutation_id, status, lease_until, depends_on_entity_id`; inserting two rows with the same `mutation_id` throws a `DatabaseException`.
- [ ] **Step 2: Run** `flutter test test/core/sync/sync_schema_test.dart` -> FAIL (`openTestDb` undefined).
- [ ] **Step 3: Implement** the pubspec dev dep, `SyncSchema`, `_dbVersion = 6` (create in `_onCreate`, and in `_onUpgrade` for `oldVersion < 6`), `OfflineDb.forTesting`, `openTestDb()` using `databaseFactoryFfi` + `inMemoryDatabasePath` and `sqfliteFfiInit()`.
- [ ] **Step 4: Run** same test -> PASS. Run `flutter pub get` first if needed.
- [ ] **Step 5: Checkpoint:** `flutter analyze lib/core test/core` clean.

---

### Task 2: DbChangeNotifier (reactive reads)

**Files:**
- Create: `lib/core/sync/db_change_notifier.dart`
- Test: `test/core/sync/db_change_notifier_test.dart`

**Interfaces:**
- Produces:
  - `class DbChangeNotifier { void notify(Set<String> tables); Stream<Set<String>> get changes; Stream<T> watch<T>({required Set<String> tables, required Future<T> Function() query, Duration debounce = const Duration(milliseconds: 16)}); void dispose(); }`
  - `watch` emits immediately (initial query), then re-runs `query` after any `notify` intersecting `tables`, coalescing bursts within `debounce`, never emitting out of order (a slow earlier query must not overwrite a later one), cancel-safe.

- [ ] **Step 1: Tests:** (a) `watch` emits initial value; (b) `notify({'sales'})` re-queries watcher of `{'sales'}` but not watcher of `{'products'}`; (c) 10 notifies within debounce cause exactly 1 re-query; (d) if query #1 is slower than #2, only #2's result is the last emitted (use `Completer`s); (e) cancelling the subscription stops queries.
- [ ] **Step 2: Run** -> FAIL.
- [ ] **Step 3: Implement** with a broadcast `StreamController<Set<String>>` and a generation counter per watcher to drop stale results.
- [ ] **Step 4: Run** -> PASS.

---

### Task 3: Outbox model and store

**Files:**
- Create: `lib/core/sync/outbox/outbox_entry.dart`, `lib/core/sync/outbox/outbox_store.dart`
- Test: `test/core/sync/outbox_store_test.dart`

**Interfaces:**
- Consumes: Task 1 `openTestDb`.
- Produces:
  - `enum OutboxStatus { pending, inflight, done, rejected, blocked }`
  - `class OutboxEntry { int? seq; String mutationId; String entity; String op; String entityId; String? dependsOnEntityId; int? baseVersion; DateTime occurredAt; Map<String,dynamic> payload; OutboxStatus status; int attempts; DateTime? nextAttemptAt; String? errorCode; String? errorMessage; }` with `toRow()/fromRow()`.
  - `class OutboxStore { OutboxStore(OfflineDb db, {Uuid? uuid, DateTime Function()? now}); Future<OutboxEntry> enqueue(DatabaseExecutor txn, {required String entity, required String op, required String entityId, required Map<String,dynamic> payload, String? dependsOnEntityId, int? baseVersion, DateTime? occurredAt}); Future<List<OutboxEntry>> claimBatch({int limit = 100, Duration lease = const Duration(minutes: 2)}); Future<void> applyResult(DatabaseExecutor txn, String mutationId, {required OutboxStatus status, String? code, String? message}); Future<void> scheduleRetry(String mutationId, DateTime at); Future<int> releaseExpiredLeases(); Future<void> unblockDependents(DatabaseExecutor txn, String entityId); Future<void> failDependents(DatabaseExecutor txn, String entityId); Stream<int> watchPendingCount(DbChangeNotifier n); Future<List<OutboxEntry>> rejected(); Future<void> retryRejected(String mutationId); Future<void> discard(String mutationId); }`
  - `enqueue` sets status `blocked` if a non-`done` `create` for `dependsOnEntityId` exists, else `pending`. `claimBatch` returns `pending` rows with `next_attempt_at` null or due, ordered by `seq`, sets them `inflight` + `lease_until` in one transaction and never returns a row whose earlier `seq` for the same `entity_id` is not `done` (per-entity ordering).

- [ ] **Step 1: Tests:** enqueue assigns increasing `seq`; payload with Arabic text (`"قهوة سودانية"`) and a 1.2 MB string round-trips exactly; duplicate explicit `mutationId` impossible (uuid v4 per call); `blocked` when dependency create pending, `unblockDependents` flips to `pending`, `failDependents` sets `rejected` with code `dependency_failed`; `claimBatch(limit:2)` returns 2 oldest and a second call returns the next ones, none twice; two updates of the same entity are never in one batch out of order; `releaseExpiredLeases` returns expired `inflight` rows to `pending` (use injected `now`); `retryRejected` -> `pending` attempts reset; `discard` deletes row and also `failDependents`.
- [ ] **Step 2: Run** -> FAIL.
- [ ] **Step 3: Implement.** Claim inside `db.transaction`. `done` rows are kept 7 days then pruned by `pruneDone()` (add, test).
- [ ] **Step 4: Run** -> PASS.

---

### Task 4: LocalWriter (the atomic write path)

**Files:**
- Create: `lib/core/sync/local_writer.dart`
- Test: `test/core/sync/local_writer_test.dart`

**Interfaces:**
- Consumes: `OutboxStore.enqueue`, `DbChangeNotifier.notify`.
- Produces: `class LocalWriter { LocalWriter(OfflineDb db, OutboxStore outbox, DbChangeNotifier notifier); Future<T> write<T>({required Set<String> tables, required Future<T> Function(WriteScope scope) body}); }` and `class WriteScope { Transaction txn; Future<OutboxEntry> enqueue({entity, op, entityId, payload, dependsOnEntityId, baseVersion, occurredAt}); }`. Notify happens **only after commit** and only for `tables` + `{'outbox'}`.

- [ ] **Step 1: Tests:** (a) body inserts a row into a scratch table and enqueues; both visible after; (b) body throws after enqueue -> neither row nor outbox entry exists and **no notification** fired; (c) notification fires once, after commit (assert a watcher reading in its callback sees the committed row); (d) two concurrent `write` calls both succeed with distinct `seq`.
- [ ] **Step 2: Run** -> FAIL.
- [ ] **Step 3: Implement** using `db.transaction`; collect `notify` after the `await`.
- [ ] **Step 4: Run** -> PASS.

---

### Task 5: Contract DTOs + transport interface

**Files:**
- Create: `lib/core/sync/contract/sync_contract.dart`, `lib/core/sync/transport/sync_transport.dart`
- Test: `test/core/sync/sync_contract_test.dart`

**Interfaces:**
- Produces (fields per BE_GAPS sections 2, 5, 6):
  - `enum PushStatus { applied, duplicate, rejected, retry }`
  - `class PushResult { String mutationId; PushStatus status; String? entityId; int? version; int? serverSeq; String? code; String? message; Map<String,dynamic>? serverState; List<String> warnings; List<StockAfter> stockAfter; }`
  - `class PushResponse { DateTime serverTime; List<PushResult> results; String? nextCursor; }`
  - `class PullChange { int seq; String entity; String op; String id; int? version; Map<String,dynamic>? data; String? originDeviceId; }`, `class PullResponse { DateTime serverTime; List<PullChange> changes; String nextCursor; bool hasMore; bool fullResyncRequired; }`
  - `class PingResponse { bool ok; DateTime serverTime; String? minAppVersion; String? latestAppVersion; bool maintenance; int? retryAfterSeconds; Set<String> capabilities; }`
  - `abstract class SyncTransport { Future<PingResponse> ping(); Future<PushResponse> push({required String deviceId, required String appVersion, required List<OutboxEntry> mutations}); Future<PullResponse> pull({String? cursor, int limit = 500}); }`
  - `class SyncTransportException implements Exception { SyncTransportKind kind; int? httpStatus; String? code; String? message; }` with `enum SyncTransportKind { network, timeout, server, unauthorized, tokenExpired, accountDisabled, deviceRevoked, tooLarge, maintenance }`.
  - All have `fromJson` (and `PushRequest` payload builder `toJson`).

- [ ] **Step 1: Tests:** `PushResponse.fromJson` parses a contract sample with each of the four statuses, `stock_after`, `warnings`, `server_state`; unknown status string -> throws `FormatException`; `PingResponse` without `capabilities` -> empty set; `PullResponse` `full_resync_required: true`.
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** -> PASS.

---

### Task 6: FakeSyncServer (contract-faithful, with fault injection)

**Files:**
- Create: `test/core/sync/support/fake_sync_server.dart`
- Test: `test/core/sync/fake_sync_server_test.dart`

**Interfaces:**
- Produces: `class FakeSyncServer implements SyncTransport` holding in-memory `Map<String, Map<String,Map<String,dynamic>>> tables`, `List<PullChange> feed`, `Map<String,PushResult> applied` (by `mutation_id`), stock ledger per `(product,shop)`. Behaviours: applies mutations in `seq` order, idempotent by `mutation_id` (`duplicate`), version++ per write, `stock` ops add signed `delta` and return `stockAfter`, `sale.create` always `applied` (negative stock allowed, warnings), dependency failure -> `rejected/dependency_failed`, unique-key collision -> `rejected/conflict_unique`, deleted target -> `entity_deleted`, every applied write appends a `PullChange` with increasing `seq`. Fault knobs: `Duration latency`, `bool down` (throws `SyncTransportException(network)`), `int dropResponseAfterApply` (applies batch, then throws `timeout`: the "lost response" case), `double flakyRate` with seeded `Random`, `String? failNextWith` (typed codes `tokenExpired`, `accountDisabled`), `minAppVersion`, `fullResyncRequired`, `capabilities`. Helper `FakeSyncServer.forDevice(String id)` returns a view sharing state (for multi-device tests).

- [ ] **Step 1: Tests:** replay same `mutation_id` -> `duplicate` and one stored row; ordering by `seq`; `dropResponseAfterApply` applies yet throws; pull with cursor returns only newer changes, `hasMore` paging at `limit`; two device views see each other's changes; stock `+5` then `-3` from two devices -> quantity 2.
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** -> PASS.

---

### Task 7: HttpSyncTransport

**Files:**
- Create: `lib/core/sync/transport/http_sync_transport.dart`
- Test: `test/core/sync/http_sync_transport_test.dart`

**Interfaces:**
- Consumes: Task 5 types, existing Dio instance factory in `lib/core/network/dio_client.dart` (read it; use a **separate** Dio without retry interceptors but with the existing auth header + refresh logic).
- Produces: `HttpSyncTransport(Dio dio)` implementing `SyncTransport`: `GET api/v1/sync/ping/` (5 s), `POST api/v1/sync/push/` (gzip request body when > 2 KB, 15 s), `GET api/v1/sync/pull/?cursor=&limit=` (15 s). Error mapping: `DioExceptionType.connectionError|connectionTimeout|receiveTimeout|sendTimeout` -> `network|timeout`; 401 with body code `token_expired|account_disabled|device_revoked` -> matching kinds, other 401 -> `unauthorized`; 413 -> `tooLarge`; 503 or `maintenance:true` -> `maintenance`; 5xx -> `server`.

- [ ] **Step 1: Tests** with a fake `HttpClientAdapter`: each mapping above; push body JSON equals contract shape (`device_id, app_version, client_time, mutations[].mutation_id/seq/entity/op/entity_id/base_version/occurred_at/payload`); gzip header present for a 10 KB body.
- [ ] **Step 2-4:** FAIL -> implement -> PASS.

---

### Task 8: ServerReachability and SyncStateStore

**Files:**
- Create: `lib/core/sync/reachability.dart`, `lib/core/sync/sync_state_store.dart`
- Test: `test/core/sync/reachability_test.dart`, `test/core/sync/sync_state_store_test.dart`

**Interfaces:**
- Produces:
  - `class SyncStateStore { SyncStateStore(OfflineDb db); Future<String> deviceId() /* generated once, persisted */; Future<String?> cursor(); Future<void> setCursor(DatabaseExecutor txn, String cursor); Future<Duration?> clockSkew(); Future<void> setClockSkew(Duration d); Future<DateTime?> lastSyncedAt(); Future<void> setLastSyncedAt(DateTime t); Future<Set<String>> capabilities(); Future<void> setCapabilities(Set<String>); Future<void> clear(); }`
  - `class ServerReachability { ServerReachability(SyncTransport t, {Duration ttl = const Duration(seconds: 15), DateTime Function()? now}); Future<PingResponse?> check({bool force = false}); void reportSuccess(); void reportFailure(); bool get isReachable; Stream<bool> get changes; }` Returns cached result within `ttl`; `reportFailure` flips to unreachable immediately; computes skew = `serverTime - deviceNow` (midpoint of request) and exposes via `lastPing`.

- [ ] **Step 1: Tests:** device id stable across reopen of same DB; cursor set inside a txn rolls back with it; reachability caches within ttl (1 transport call), `force` bypasses, failure flips `isReachable` and emits once, skew computed with a fake clock 3 h ahead.
- [ ] **Step 2-4:** FAIL -> implement -> PASS.

---

### Task 9: ChangeApplier registry and SyncEngine (push + pull + state machine)

**Files:**
- Create: `lib/core/sync/change_applier.dart`, `lib/core/sync/sync_engine.dart`
- Test: `test/core/sync/sync_engine_test.dart`

**Interfaces:**
- Consumes: Tasks 3, 5, 6, 8.
- **Amendments (controller rulings, binding):** (1) `SyncStateStore` gains `Future<bool> acquireLock(String holder, Duration ttl)`, `Future<bool> renewLock(String holder, Duration ttl)`, `Future<void> releaseLock(String holder)` backed by key `sync_lock` in `sync_state` (value = holder + expiry; acquire succeeds if absent/expired/same holder). (2) `SyncEngine` takes an optional `Future<RefreshOutcome> Function()? refreshToken`; `enum RefreshOutcome { refreshed, rejected, transient }`. On transport `tokenExpired|unauthorized`: call it once per `syncNow`; `refreshed` -> retry the failed call once; `rejected` -> `blocked(tokenExpired)` and status `needsLogin`; `transient` (or null callback) -> treat as network failure (backoff, NOT blocked, never logout). `accountDisabled|deviceRevoked` -> `blocked(...)` as listed. The engine itself NEVER logs out. (3) The engine must NOT adopt `PushResponse.nextCursor` as its pull cursor; results are matched by `mutation_id`, never by position; a `rejected` replay stays rejected; `entity_deleted` on a delete mutation is treated as converged (applied). (4) Transport/DTO `FormatException` never reaches the engine (transport wraps as `SyncTransportException(server,'malformed_response')`), engine treats `server` kind as backoff.
- Produces:
  - `abstract class ChangeApplier { String get entity; Future<void> apply(Transaction txn, PullChange change); Future<void> onPushResult(Transaction txn, OutboxEntry sent, PushResult result); Set<String> get tables; }` and `class ChangeApplierRegistry { void register(ChangeApplier a); ChangeApplier? of(String entity); }`
  - `enum SyncPhase { idle, pinging, pushing, pulling, backoff, blocked }`; `enum SyncBlockReason { none, appTooOld, tokenExpired, accountDisabled, deviceRevoked, maintenance }`; `class SyncStatus { SyncPhase phase; SyncBlockReason block; int pending; int rejected; DateTime? lastSyncedAt; bool serverReachable; String? lastError; }`
  - `class SyncEngine { SyncEngine({required OfflineDb db, required SyncTransport transport, required OutboxStore outbox, required SyncStateStore state, required ServerReachability reachability, required ChangeApplierRegistry appliers, required DbChangeNotifier notifier, required String appVersion, Backoff? backoff, DateTime Function()? now, SyncHooks? hooks}); Future<SyncOutcome> syncNow({SyncReason reason}); Stream<SyncStatus> get status; }` where `SyncHooks` has optional async callbacks `beforeResultWrite`, `afterPushApplied`, `beforePullPageCommit` (used by tests to simulate process death by throwing `CrashSimulation`).
  - Algorithm: (1) single-flight: in-process mutex **and** DB lease key `sync_lock` in `sync_state` (value = holder uuid + expiry; engine **renews** it each batch and aborts if renewal shows another holder); (2) `reachability.check`; if `minAppVersion > appVersion` -> `blocked(appTooOld)`; maintenance -> `backoff(retryAfter)`; (3) `releaseExpiredLeases`; (4) push loop: `claimBatch(100)` -> transport.push -> **one transaction** applying every result: `applied|duplicate` -> outbox `done` + `appliers.onPushResult` + `unblockDependents`; `rejected` -> `rejected` + `failDependents`; `retry` -> `scheduleRetry(backoff)`; repeat until none claimable; (5) pull loop: page -> **one transaction**: apply all changes via registry (skip changes whose `originDeviceId == deviceId`; unknown entity -> ignore but still advance), then `setCursor`; `fullResyncRequired` -> clear cursor, emit `SyncOutcome.needsBootstrap` and stop; (6) `setLastSyncedAt`, notify. Transport `network|timeout|server` -> mark in-flight batch back to `pending` with backoff (exponential 2 s base, x2, cap 5 min, +-20% jitter via injected `Random`), `reportFailure`. `unauthorized/tokenExpired` -> `blocked(tokenExpired)` (caller refreshes then calls `syncNow` again); `accountDisabled|deviceRevoked` -> `blocked(...)`, outbox untouched.

- [ ] **Step 1: Tests (engine_test):** happy path (3 mutations -> all `done`, appliers called, status ends idle with `lastSyncedAt`); empty outbox still pulls; server down -> items remain `pending`, `serverReachable=false`, no exception; `retry` result schedules `next_attempt_at` in the future and is not re-claimed before due; `rejected` parks item and fails dependents; pull page applied atomically with cursor (hook throws in `beforePullPageCommit` -> cursor unchanged, no changes applied); own-device changes skipped; `fullResyncRequired` stops with `needsBootstrap`; `appTooOld` leaves outbox untouched; `tokenExpired`/`accountDisabled` set block reason; second concurrent `syncNow` returns `SyncOutcome.alreadyRunning`; lease held by another holder (unexpired) -> `alreadyRunning`; lease expired -> takeover; lease renewed during long push (fake clock advanced past initial lease between batches) so a second runner still cannot start.
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** -> PASS.

---

### Task 10: Fault-injection scenarios (crash safety)

**Files:**
- Test: `test/core/sync/engine_scenarios_test.dart`

Uses real `LocalWriter` + `FakeSyncServer` + a scratch `widgets` table with a test `ChangeApplier`.

- [ ] **Step 1: Write these tests** (all must pass without engine changes, otherwise fix the engine):
  1. **Lost response:** server applies the batch then throws `timeout` (`dropResponseAfterApply`); app retries; server has exactly 1 row per mutation, outbox ends `done`.
  2. **Crash after server applied, before results written** (`hooks.beforeResultWrite` throws `CrashSimulation`): recreate engine on same DB (simulated restart); `releaseExpiredLeases` + next `syncNow` -> `duplicate` results -> outbox `done`, server row count unchanged.
  3. **Crash mid-pull page:** cursor not advanced, no half-applied page; next run re-applies the page cleanly (idempotent apply).
  4. **Flaky link:** seeded `flakyRate: 0.5`, 50 mutations, loop `syncNow` up to 40 times -> eventually all applied, zero duplicates on server.
  5. **Dependency chain:** `product.create` rejected (`limit_exceeded`) -> dependent `sale.create` line item mutation `rejected` with `dependency_failed`; user-visible via `outbox.rejected()`.
  6. **Server down 2 hours then up:** 500 queued mutations (fake clock) all drain in batches of 100 in order.
  7. **Skew:** device clock +5 h: `occurred_at` stored untouched, skew recorded, batches still ordered by `seq`.
  8. **Version conflict result** `rejected/conflict_version` with `serverState` is stored in the outbox row (`error_message` JSON) for the UI.
- [ ] **Step 2: Run** -> expect PASS (fix engine defects found; each fix gets its own regression assertion).

---

### Task 11: Convergence property test (multi-device money invariant)

**Files:**
- Test: `test/core/sync/convergence_test.dart`

- [ ] **Step 1: Write test:** for 200 seeds: 3 devices (each its own in-memory DB + engine sharing one `FakeSyncServer`), random sequences of 20-60 actions (stock `+delta`, sale lines with decimal-string totals, product renames, customer creates) executed offline, then syncs in random device order with random faults (flaky, dropped responses, crashes via hooks). After fixed-point syncing: (a) server stock per `(product,shop)` == initial + sum of all deltas; (b) sum of sale totals on server == sum across devices; (c) every device's local synced tables equal the server's for entities each device pulls; (d) no duplicate `mutation_id`; (e) no outbox row left `pending/inflight` except deliberately rejected ones. Seed printed on failure for repro.
- [ ] **Step 2: Run** `flutter test test/core/sync/convergence_test.dart`. Expected PASS; runtime < 60 s.

---

### Task 12: Triggers and DI wiring (flag-gated, no behaviour change yet)

**Files:**
- Create: `lib/core/sync/sync_triggers.dart`
- Modify: `lib/config/providers/providers.dart` (register `DbChangeNotifier`, `OutboxStore`, `LocalWriter`, `SyncStateStore`, `SyncTransport` as `HttpSyncTransport`, `ServerReachability`, `ChangeApplierRegistry`, `SyncEngine`, `SyncTriggers` as singletons), `lib/main.dart` (start triggers after login)
- Modify: `docs/offline.md` (new "Sync core" section: write path, outbox, engine, how to add an entity: implement `ChangeApplier` + use `LocalWriter`)
- Test: `test/core/sync/sync_triggers_test.dart`

**Interfaces:**
- Produces: `class SyncTriggers { SyncTriggers(SyncEngine e, NetworkMonitor n, OutboxStore o, DbChangeNotifier c, {Duration afterWriteDebounce = const Duration(seconds: 5), Duration periodic = const Duration(minutes: 5)}); void start(); Future<void> stop(); void onAppResumed(); }` Triggers: app resume, connectivity regained (`NetworkMonitor.onStatusChanged == true`), outbox change (debounced 5 s), periodic while foreground, manual. Never starts a second sync while one runs (engine already guards; trigger coalesces).

- [ ] **Step 1: Tests (fake_async):** 10 outbox notifications within 5 s -> one `syncNow`; resume triggers one; connectivity false->true triggers one; `stop()` cancels timers; no trigger fires before `start()`.
- [ ] **Step 2-4:** FAIL -> implement -> PASS.
- [ ] **Step 5: Checkpoint:** `flutter analyze` (no new issues), `flutter test` whole suite green, app still launches (`flutter run` smoke; core is wired but no feature uses it yet). Update memory note on progress: Phase 0 done.

---

## Self-review (done)

- **Spec coverage:** Outbox, change notifier, LocalWriter, engine (single-flight + lease, backoff, ping, version gate, auth blocks), transport + fake server with faults, reachability/clock skew, triggers, convergence + lifecycle crash tests, docs: covered. Deferred by design to later plans: WorkManager/BGTask (P1), stock base+delta storage (P1), bootstrap/assets (P2), feature repositories (P3-P5), local aggregates and checksum audit (P6), perf budgets and device checklist (P7).
- **Types:** `OutboxEntry`, `PushResult`, `PullChange`, `SyncStatus`, `SyncHooks` names used identically across Tasks 3-12. `WriteScope.enqueue` mirrors `OutboxStore.enqueue` minus `txn`.
- **Gap noted:** `SyncOutcome` enum (`completed, alreadyRunning, needsBootstrap, blocked, backoff`) and `SyncReason` (`resume, connectivity, afterWrite, periodic, manual, background`) and `Backoff` helper are defined in Task 9's implementation step.
