# Phase 4: Customers + Returns/Refunds, local-first (design)

Date: 2026-11-17. Size: a project (two features, one phase). Builds on Phases 0-3 (outbox, LocalWriter, SyncEngine, appliers, DB v14 — do NOT bump to v15).

## Intent
Customers and returns must work 100% offline like sales and catalog already do. Returns MUST land before real money: today a refund needs the server (REST `POST api/v1/sales/{id}/refund/`), so a cashier offline cannot refund, and money handed back is not tracked locally.

## Goals
- Customer create/update/deactivate: write local row + outbox mutation in one transaction (LocalWriter), UI reads local table, no spinner.
- Refund offline: local `sale_refunds` row, sale status (`partial_refund`/`refunded`) and local dashboard net revenue update instantly; push `sale.refund`.
- Local guard: refund qty per line <= sold - already refunded (synced + pending local). Refund method (cash/bankak/...) is stored, so drawer cash is computable.
- Money invariants proven by tests: no lost/duplicated refund across randomized runs (extend CONV_SEEDS convergence), idempotent on `reference`.

## Non-goals
Cancel-sale flow, store credit, editing a refund, loyalty-point logic (server-owned), team (Phase 5), checksum (Phase 6).

## Anti-goals
Silently absorbing a rejected refund; letting a client set `loyalty_points`; double-applying a refund on retry.

## Constraints (BE contract, live)
- `customer create|update|delete`; `loyalty_points` server-owned (never sent). Same-phone/unique clash returns `conflict_unique` + conflicting row id: merge locally onto the existing row.
- `sale.refund` payload `{sale_id, reference (client UUID, idempotency), items:[{sale_item_id, quantity}], method, reason, occurred_at}`. Sale unknown yet -> `retry` `dependency_pending` (engine retries). Concurrent refund of same line -> `rejected` `refund_exceeds_sold` + `server_state`.
- Known BE issue: `dependency_failed` on dependents; mobile workaround from Phase 3 already in place.
- Refunds net on refund date (`occurred_at` = `created_at`).
- BE repo is never edited; new BE needs go in docs/BE_GAPS.md.

## Approaches
1. **Optimistic local refund + reverse on rejection (chosen, user-approved).** Matches sales/catalog pattern; works offline; rejection handled explicitly.
2. Pessimistic: refund only when online. Fails the offline goal; rejected.
3. Record refund locally but never reverse, owner reconciles manually. Hides divergence from totals; rejected (anti-goal).

## Decisions
- **Rejection (`refund_exceeds_sold`, user's call):** reverse the local refund (remove/void the optimistic `sale_refunds` row, restore sale status and totals using `server_state`), flag the sale "refund rejected" visibly for the owner/cashier, never silent. Surface in the existing pending/failed-sync UI.
- Customers: repo swaps data source from `RequestHandler` to local + outbox (`CustomerRepoImpl`), bloc/usecase signatures kept. Search/filter/paging run on the local table.
- Returns: `ReturnsRepoImpl` writes local-first; the returns screen shows pending/rejected state per refund.
- Refund `reference` generated once at creation and persisted with the mutation (stable across retries).
- Stock: whether a refund restocks follows the current server behavior; keep what the REST flow does today (builder to confirm from `returns` code and BE contract, no new behavior).

## Left to the builder
Schema additions only if needed within v14 (dev phones are reinstalled; no migration). Exact UI for the rejected flag, test layout, task breakdown (writing-plans).

## Known leftovers (not this phase)
F3 ghost rows after `full_resync_required`; expiry stock.add; on-device checklist; Arabic strings review.
