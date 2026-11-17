# Phase 4: Customers + Returns/Refunds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Customer create/update/deactivate and sale refunds work fully offline through `LocalWriter` + the outbox, and every push outcome (incl. `refund_exceeds_sold`) is handled visibly.

**Architecture:** `RefundService` and `CustomerService` mirror `CategoryService`/`StockService`: validate, write local rows, enqueue, all in one `LocalWriter.write`. A refund is a `sale_refunds` row with a `sync_state` plus a `sale.refund` outbox row (entity `sale`, op `refund`). `SaleApplier.onPushResult` settles/voids it; `RefundApplier` replaces the local twin when the server refund is pulled. Returns and Customers screens read local tables only.

**Tech Stack:** Flutter, sqflite (+ffi in tests), flutter_bloc, get_it, uuid, existing `FakeSyncServer`.

**Spec:** `docs/superpowers/specs/2026-11-17-phase4-customers-returns-design.md`. Parent: `docs/superpowers/specs/2026-11-16-offline-first-sync-design.md`. Rulings/pattern: Phase 3 plan `docs/superpowers/plans/2026-11-17-phase3-catalog-writes.md` and ledger `.superpowers/sdd/2026-11-17-phase3-catalog-writes/progress.md`. BE contract: `docs/BE_GAPS.md` sections 4.3 and "Refunds"; BE repo `docs/sync-contract.md` (read only).

## Global Constraints

- NO git commands by agents (user commits). Where a template says "Commit", write the task report listing changed files instead.
- Never edit the BE repo (`/Users/almogdadjabir/Documents/projects/amana/amanaPOS-be`); BE needs go to `docs/BE_GAPS.md`.
- DB stays **v14** (do NOT bump to v15). Dev phones reinstall; schema additions go into the v14 create/upgrade code only, no data migration.
- Tests run in the FOREGROUND only. Baseline: 1440 pass / 2 skip, `flutter analyze` 73 (must not grow), `CONV_SEEDS=200` passes.
- Money is a String; never double. IDs are UUID v4 generated on device. Refund `reference` is a client UUID generated once and persisted (stable across retries).
- `LocalWriter.write` never nests; bodies use `scope.txn` only.
- `loyalty_points` is server-owned: never sent, never edited locally.
- A rejected refund is never silent: the local refund is voided (excluded from all totals) and flagged on the sale.
- Restock behavior of a refund is NOT changed: keep exactly what the REST `POST sales/{id}/refund/` flow does today; confirm from BE contract, add no new stock logic.
- Conflict policy A (Phase 3): a `conflict_unique` never rewrites ids automatically; merge into the existing row is user-triggered via the existing catalog conflict UI.
- Follow Nile Ledger for UI; small state markers/dialogs need no mockup approval, a new full screen does.

## Review Focus

1. Local pending refund + the same refund later pulled from the server must count ONCE in dashboard net revenue and in the line returnable quantity. Pinned in Task 3.
2. Refund queued for a sale that is still unsent (offline sale then offline refund) must not be sent before the sale create is `done`; `retry dependency_pending` must retry, not reject. Pinned in Tasks 2 and 3.
3. A voided (`refund_exceeds_sold`) refund must disappear from dashboard totals, sale status and the returnable guard, yet remain visible as flagged. Pinned in Task 3.
4. Two refunds of the same line queued offline on one device cannot exceed sold quantity (guard counts pending). Pinned in Task 2.
5. A sale naming a customer whose create is unsent must not be sent before it (else `customer` null). Pinned in Task 5.
6. Deactivating or editing a customer never overwrites server-owned `loyalty_points`. Pinned in Task 5.
7. A pull/refresh never erases an unsynced local customer create/edit. Pinned in Task 5.

---

### Task 1: Schema, contract shape, fake server

**Files:**
- Modify: `lib/core/offline/offline_db.dart` (`sale_refunds` create + v14 upgrade step), `test/core/sync/support/fake_sync_server.dart` (`sale.refund` handler), `lib/core/sync/contract/sync_contract.dart` only if a refund payload helper is added
- Create: `docs/superpowers/plans/2026-11-17-phase4-audit.md`
- Test: `test/core/offline/sale_refunds_schema_test.dart`, `test/core/sync/fake_sync_server_refund_test.dart`

**Interfaces:**
- Produces: `sale_refunds` gains `reference TEXT`, `sync_state TEXT NOT NULL DEFAULT 'synced'` (`pending|synced|rejected`), `error_code TEXT`, `error_message TEXT`, `reason TEXT`; index on `(sale_id, sync_state)`. Pulled rows keep `sync_state='synced'`. Fake server `sale.refund` payload is `{sale_id, reference, items:[{sale_item_id, quantity}], method, reason, occurred_at}`; returns `applied` (with `refund_reference`, `refund_total`), `duplicate` on same `(sale, reference)`, `retry`+`dependency_pending` when the sale is unknown, `rejected`+`refund_exceeds_sold`+`server_state` when cumulative qty exceeds sold.

- [ ] **Step 1:** Audit doc: list (a) every reader of `sale_refunds` (dashboard queries, sales history, reports) so Task 3 can add the `sync_state != 'rejected'` filter to each; (b) every REST caller of `returns_repo_impl` / customer repo; (c) what the BE refund feed row (`ser_refund`) carries: does it include `reference`? Record the answer (drives the twin-matching in Task 3); (d) how the REST refund path handles stock, to confirm the "no new stock logic" rule.
- [ ] **Step 2:** Test `sale_refunds has sync_state/reference/error columns on create and upgrade-to-v14` (fresh DB and an upgraded v13 DB both have them; existing rows default `synced`). Run: FAIL.
- [ ] **Step 3:** Add the columns in `onCreate` and the v14 upgrade step (idempotent `ALTER TABLE ... ADD COLUMN` guarded by a column check).
- [ ] **Step 4:** Tests in `fake_sync_server_refund_test.dart`: `refund_exceeds_sold when two devices refund the same line` (second rejected with `server_state`), `replay same reference returns duplicate`, `unknown sale returns retry dependency_pending`, `refund before sale in same batch applies in seq order`. Update the fake to the contract shape; fix any existing fake-server tests that used the old `product_id` shape.
- [ ] **Step 5:** `flutter test test/core` passes; analyzer not above 73.

### Task 2: `RefundService` (local-first refund)

**Files:**
- Create: `lib/features/returns/domain/refund_service.dart`
- Modify: `lib/features/pos/data/local/sale_local_store.dart` (add `applyLocalRefundStatus`, `refundedQuantities`), `lib/core/sync/sync_schema.dart` (table-set constant if needed)
- Test: `test/features/returns/refund_service_test.dart`

**Interfaces:**
- Produces: `class RefundService { RefundService({required LocalWriter writer, required SaleLocalStore store, required RefundActor Function() actor, DateTime Function()? now, Uuid? uuid}); Future<String> refund({required String saleId, required Map<String, String> quantitiesByLineId, required String method, String? reason}); }` returns the refund reference. `RefundValidationException(String message)`. `SaleLocalStore.refundedQuantities(DatabaseExecutor, String saleId) -> Future<Map<String, Decimal3-string>>` summing synced + pending refunds per line, ignoring `rejected`.
- Consumes: `LocalWriter.write(tables:, body:)` with `scope.enqueue(entity: 'sale', op: 'refund', entityId: saleId, payload:, dependsOn: [saleId if the sale row has sync_state != synced])`.

- [ ] **Step 1:** Tests (names + assertions):
  - `refund writes pending sale_refunds row, outbox sale.refund and updates sale status in one transaction` (row `sync_state='pending'`, total = sum of line unit_price*qty minus pro-rata discount as the REST flow computes, outbox payload has `reference`, `items:[{sale_item_id, quantity}]`, `method`, `reason`, `occurred_at`; sale status `partial_refund`, or `refunded` when every line fully returned).
  - `refund rejects quantity above sold minus already refunded` (throws `RefundValidationException`, nothing written, no outbox row).
  - `two queued refunds of the same line cannot exceed sold` (second throws).
  - `refund of an unsent sale depends on the sale create` (outbox `dependsOn` contains the sale id; row not eligible to send until the sale is done).
  - `rolls back everything when enqueue fails`.
  - `cashier of another shop cannot refund` per existing role rules (mirror what the returns permission check does today; builder reads `app_permissions.dart`).
- [ ] **Step 2:** Run: FAIL.
- [ ] **Step 3:** Implement per Interfaces. Total/discount math must match the server's rule used by the current Returns screen totals (reuse, do not re-derive; if the screen computes it, move that to a shared pure function used by both).
- [ ] **Step 4:** Tests pass; analyzer not above 73.

### Task 3: Push results, twin replacement, void on rejection

**Files:**
- Modify: `lib/core/sync/appliers/sale_applier.dart` (`onPushResult` handles `sent.op == 'refund'`), `lib/core/sync/appliers/refund_applier.dart` (replace local twin), `lib/features/dashboard/data/local/local_dashboard_queries.dart` and every reader listed in the Task 1 audit (exclude `sync_state = 'rejected'`), `lib/features/sales_history/data/local/local_sales_history.dart` (refunds list incl. pending/rejected markers, `refundedTotal` excludes rejected)
- Test: `test/core/sync/refund_push_results_test.dart`, extend `test/core/sync/refund_applier_test.dart`

**Interfaces:**
- Consumes: Task 1 columns, Task 2 `reference`/`sync_state`, `PushResult.refundReference/refundTotal/serverState`.
- Produces: refund outbox settlement: `applied`/`duplicate` -> local row `sync_state='synced'`; `rejected` with `refund_exceeds_sold` -> row `sync_state='rejected'` with `error_code`/`error_message`, sale status recomputed from remaining non-rejected refunds (using `server_state` quantities when present), sale flagged; any other `rejected` -> same void path with its code; `retry` -> unchanged (engine backoff). `RefundApplier.apply` deletes a local twin before inserting: match by `reference` if the feed carries it (Task 1 audit), else by `(sale_id, total, occurred_at)` among `pending|synced` local rows.

- [ ] **Step 1:** Tests:
  - `applied result marks refund synced and keeps one row after the server refund is pulled` (dashboard net revenue and `refundedQuantities` count it once; before the pull and after).
  - `pull arriving before the push result still yields one counted refund`.
  - `refund_exceeds_sold voids the local refund` (row stays, flagged; dashboard refund total, sale status, and returnable quantity all as if it never happened; reason shown from `error_message`).
  - `dependency_pending retries and succeeds after the sale create is applied` (offline sale then offline refund, FakeSyncServer, engine run twice).
  - `duplicate replay changes nothing`.
  - `concurrent refund from two devices: exactly one applied, one voided` (two engines against one fake server).
- [ ] **Step 2:** Run: FAIL.
- [ ] **Step 3:** Implement. Reuse the Task 2 `SaleLocalStore` helpers for status recompute. Dashboard filter goes in the shared refund query constant, not per call site, if the audit shows one.
- [ ] **Step 4:** Tests pass; analyzer not above 73.

### Task 4: Returns UI on the local path

**Files:**
- Modify: `lib/features/returns/data/repository_impl/returns_repo_impl.dart` (delegates to `RefundService`; REST path removed), `lib/features/returns/domain/repositories/returns_repository.dart`, `returns_usecase.dart`, `presentation/bloc/returns_bloc.dart` (+event/state), `lib/features/sales_history/presentation/widgets/sale_detail/sale_detail_parts.dart` (`SaleRefundsCard`: pending/synced/rejected chips), `lib/config/providers/feature_bloc_providers.dart`, `lib/l10n/app_en.arb`, `app_ar.arb` (+ regenerate localizations)
- Test: `test/features/returns/returns_bloc_test.dart`

**Interfaces:**
- Produces: `ReturnsRepository.processRefund({required String saleId, required RefundRequestDto request, required String method})` now returns `Either<String?, String>` (the reference); `RefundRequestDto` gains `method`, `reason`. `ReturnsState.returnableQuantity` derives from local `refundedQuantities`. Method defaults to the sale's single payment method, `cash` when split; no new screen.

- [ ] **Step 1:** Tests: `submit offline succeeds without network and shows pending refund`, `returnable quantity excludes pending refunds`, `RefundValidationException surfaces as failure message`, `rejected refund shows flagged state with reason on sale detail` (widget test of `SaleRefundsCard`).
- [ ] **Step 2:** Run: FAIL.
- [ ] **Step 3:** Wire repo/usecase/bloc to `RefundService`; sale detail reads local refunds incl. markers; add EN+AR strings ("Refund pending sync", "Refund rejected", reason line). No REST refund call may remain (`grep` in the task report).
- [ ] **Step 4:** Tests pass; analyzer not above 73.

### Task 5: `CustomerService`, customer push results, sale dependency

**Files:**
- Create: `lib/features/customers/domain/customer_service.dart`
- Modify: `lib/core/sync/appliers/customer_applier.dart` (`onPushResult`), `lib/features/pos/domain/sale_service.dart` (`dependsOn` includes an unsent customer id), `lib/core/offline/offline_db.dart`/`sync_schema.dart` only if a `version` column or sync marker is missing on `customers` (follow how `categories` tracks `version` NULL = unsent)
- Test: `test/features/customers/customer_service_test.dart`, `test/core/sync/customer_push_results_test.dart`

**Interfaces:**
- Produces: `class CustomerService { CustomerService({required LocalWriter writer, required CatalogActor Function() actor, DateTime Function()? now, Uuid? uuid}); Future<String> create({required String name, String? phone, String? email}); Future<void> update(String id, {String? name, String? phone, String? email}); Future<void> setActive(String id, bool active}); }` (delete maps to `setActive(false)` as today's UI does; wire op `customer.update` with `is_active`, `customer.delete` only if the UI exposes a hard delete: builder confirms from the screens). Payload never contains `loyalty_points`. Update carries `base_version` from the local row. Applier `onPushResult`: `applied`/`duplicate` adopt `version`; `rejected conflict_unique` stores the conflicting row id for the existing conflict UI (policy A); `entity_deleted` marks the local row gone per Phase 3 rules.
- Consumes: `CatalogSupport.requireWrite`, `CatalogValidationException` (Phase 3).

- [ ] **Step 1:** Tests: `create writes customers row with version NULL and a customer.create outbox row atomically`; `update sends base_version and never loyalty_points` (assert payload keys); `setActive(false) keeps row and enqueues update`; `pull does not overwrite an unsynced local edit` (via `skipWhenLocalPending`); `sale for an unsent customer depends on the customer create`; `conflict_unique result is stored for the conflict UI and no id is rewritten`; `empty name throws CatalogValidationException`.
- [ ] **Step 2:** Run: FAIL.
- [ ] **Step 3:** Implement per Interfaces, copying `CategoryService`'s structure (single `LocalWriter.write`, `tables` set incl. `customers` and outbox).
- [ ] **Step 4:** Tests pass; analyzer not above 73.

### Task 6: Customers UI/repo on the local path + conflict merge

**Files:**
- Modify: `lib/features/customers/data/repository_impl/customer_repo_impl.dart` (local reads: search, paging, active filter via SQL on `customers`; writes via `CustomerService`; REST removed), `customers_bloc.dart` (+event/state), `customers_screen.dart`, `customer_form_screen.dart`, `customer_row.dart` (pending-sync marker), `lib/features/sync/domain/catalog_conflict_service.dart` (add `customer` merge-into-existing, user-triggered; no row may keep pointing at the dropped local id: `sales.customer_id`, outbox payloads), `lib/config/providers/feature_bloc_providers.dart`, l10n EN+AR
- Test: `test/features/customers/customers_local_test.dart`, extend `test/core/sync/catalog_conflict_*` tests

**Interfaces:**
- Consumes: Task 5 `CustomerService`. Produces: `CustomerRepository` methods keep their signatures (`getCustomers`, `createCustomer`, `updateCustomer`, `setCustomerActive`) so bloc/usecase callers are unchanged.

- [ ] **Step 1:** Tests: `list/search/filter works offline from local rows`, `create offline appears immediately with pending marker`, `merge into existing re-points sales.customer_id and leaves no reference to the dropped id` (schema-grep style like Phase 3 Task 8), `no REST customer call remains`.
- [ ] **Step 2:** Run: FAIL.
- [ ] **Step 3:** Implement; strings in EN+AR (pending marker, conflict prompt); regenerate localizations.
- [ ] **Step 4:** Tests pass; analyzer not above 73.

### Task 7: Convergence, docs, ledger

**Files:**
- Modify: `test/core/sync/convergence_test.dart` (add refund + customer mutations to the randomized runs), `docs/BE_GAPS.md` (any follow-ups: e.g. `ser_refund` should carry `reference`, if the audit shows it does not), `docs/offline.md`
- Create: `.superpowers/sdd/2026-11-17-phase4-customers-returns/progress.md`

- [ ] **Step 1:** Extend convergence: random offline sale+refund+customer edits across 2 devices, final local == server for sales, refunds net total, customers; invariants: no lost refund, none counted twice, voided refunds excluded. Run with `CONV_SEEDS=200`: passes.
- [ ] **Step 2:** Full suite in the foreground: `flutter test`; record counts (baseline 1440 pass / 2 skip) and `flutter analyze` (<= 73).
- [ ] **Step 3:** Write the ledger and the BE_GAPS entries; note leftovers: F3 ghost rows, expiry stock.add, on-device checklist, Arabic strings review.
- [ ] **Step 4:** Report (no git).
