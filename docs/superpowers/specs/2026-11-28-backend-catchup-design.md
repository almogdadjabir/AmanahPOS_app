# Backend catch-up (2026-11-27/28) — short design

Source: docs/02-mobile-agent-prompt.md + amanaPOS-be/docs/handoff/_backend-changes-summary.md.

## Intent
Align the app with backend changes without breaking or losing local data, and keep it smooth on cheap/old Android phones as well as new Android/iOS devices.

## Goals
1. Inbound/vendors/expiry/premium summary gated by role (owner/manager) + business type (not restaurant) only; no plan-feature paywall/upsell.
2. Sync bootstrap: verify gzip + timeouts + 429 Retry-After; tolerate `deleted` flag on product/category rows. (App already uses paged, resumable `/sync/bootstrap/`; the legacy monolithic `/offline/bootstrap/` is not used, so no rewrite.)
3. Debts: use `page`/`page_size` where a debtor list is shown; tolerate missing `count`.
4. Dates: one helper mapping local day -> `date_from/date_to` (UTC calendar days); document limitation + backend follow-up; display in business timezone.
5. Role-aware UI for upcoming 403s (refund/cancel/stock/product writes), opaque `receipt_number`, per-mutation `rejected` push codes.
6. Vocabulary/format: pharmacy + restaurant units -> backend enums, `owner` label, Arabic glossary, 2dp money / 3dp qty / business currency.

## Non-goals
Backend changes; git operations (user commits); rewriting the sync engine.

## Approaches
A) Sequential per-item changes with tests (chosen: smallest blast radius, keeps local DB schema untouched). B) Big-bang refactor of bootstrap (rejected: already done, risks data loss).

## Safety / data-loss
No Drift schema changes unless unavoidable; if one is needed, add a migration + test that old DB rows survive. Run full `flutter analyze` + `flutter test`.

## Low-end phone
No new heavy work on the UI thread; paginated lists only; check release-mode build on an emulator with constrained resources where possible. Report what could not be run (no physical device).
