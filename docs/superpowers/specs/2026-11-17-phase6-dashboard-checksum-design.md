# Phase 6: local dashboard reconciled against server checksum (short design)

Parent: 2026-11-16-offline-first-sync-design.md (Phase 6). Contract: BE `docs/sync-contract.md` (`GET sync/checksum/`), BE_GAPS §11.

## Intent
The Home dashboard is already computed locally (Phase 1). Real money: the app must notice when its synced sales/refunds/stock drift from the server and fix it without user action. Local aggregates are only trustworthy if the rows under them match the server.

## Goals
- Self-audit synced sale/refund/stock against `sync/checksum`; on mismatch run a targeted repair; if still off, tell the owner quietly.
- Debug-only parity check: local "today" summary vs `sales/dashboard-summary/` (logged, never shown in release).

## Non-goals / anti-goals
- No full resync, no deleting synced sale/refund rows (money rows are never swept; a surplus local row is reported, not removed).
- No cashier-visible noise. No retry loop. No DB bump (stays v14). No BE edits.

## Approach (user chose A)
A targeted repair (re-page sale, refund, stock only, re-check once, then owner banner). Rejected: B log-only (no fix), C full resync (heavy on 3G).

## Design
- `ChecksumAudit` (core/sync/audit): requires ping capability `checksum`, a signed-in scope, engine idle, outbox empty for the scope, and a completed pull (has_more false). Throttled: at most once per 6 h per scope (`sync_state` key), plus manual trigger.
- Local totals (cents-exact via the existing integer-cents SQL, never doubles), **synced rows only** (`sync_state='synced'`; pending/rejected excluded since the server has no such row):
  - sale: count + sum(net_amount) over all statuses, window = last N=7 days by `received_at` (server `created_at`), fallback `occurred_at`. Compare `sum_total` (and `sum_revenue` on REVENUE_STATUSES).
  - refund: count + sum(total) for refunds in window or whose sale is in window (server rule).
  - stock: count + sum(`base_quantity`) (server base, excludes this device's pending deltas).
- Verdicts: `match`, `inconclusive` (a synced row within 5 min of the window edge, or the server `max_seq` moved during the call: skip, retry next run), `mismatch`.
- On `mismatch`: `ChecksumRepair` takes a fresh manifest, pages `bootstrapPage` for sale/refund/stock through the existing appliers (version-guarded, idempotent, one transaction per page, never touches the pull cursor or bootstrap progress), then re-audits once. Still off: persist `audit_state=drift` (+ detail JSON) in `sync_state`.
- Owner-only quiet banner on Home and a row on the Pending Sync screen while `drift`; clears on the next `match`. en + ar strings. Detail JSON available for support export.
- Debug parity: `kDebugMode` + online + audit-run: compare local `summaryFor(today)` with the REST summary, log differences. Known basis difference (REST sums `total_amount`; checksum uses `net_amount`, BE_GAPS item 3) is why the audit compares raw synced totals, not dashboard revenue.

## Constraints
Foreground tests only; format only changed files; analyze must stay at 73; uses `FakeSyncServer` (needs a checksum endpoint added to the fake) for tests, incl. drift injection and the existing convergence seeds.

## Left to the builder (my calls)
Window N=7, 6 h throttle, 5-min edge tolerance, banner wording and placement, detail JSON shape, fake-server checksum implementation.
