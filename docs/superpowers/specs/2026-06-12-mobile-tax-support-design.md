# Mobile Tax Support — Design

**Date:** 2026-06-12
**Source spec:** `docs/TAX_SUPPORT.md` (backend tax support)
**Scope:** Full TAX_SUPPORT.md §7 checklist + read-only tax settings card. Offline-first preserved.

## Goal

Surface the backend's business-level tax system (VAT/GST style, single rate per
business, inclusive or exclusive) in the Flutter POS app — cart preview,
receipts, sales history, reports KPI — while obeying the golden rule: **tax is
always calculated server-side; the app never sends tax fields.** The app only
*previews* tax locally using the same formulas, including fully offline.

## Decisions made

- **Scope:** full checklist — cart, receipt, sales history, reports KPI.
- **Offline receipts:** show a locally computed tax preview from cached
  business settings (server recomputes at sync time; preview matches unless
  settings changed while offline).
- **Settings UI:** read-only tax info card on the business detail screen
  (tax is configured from the admin dashboard only).
- **Architecture:** central `TaxConfig` value object + pure `TaxCalculator`
  (approach A) — one source of truth for the §2 formulas, unit-testable,
  no duplication across widgets.

## 1. Data layer — business tax config

- Add `taxEnabled` (bool, default `false`), `taxName` (String, default
  `"VAT"`), `taxRate` (String decimal, default `"0.00"`), `taxInclusive`
  (bool, default `false`) to `BusinessData` in
  `lib/features/business/data/models/responses/business_response_dto.dart`
  (`fromJson` + `toJson`).
- No SQLite migration needed: the offline `businesses` table stores the raw
  business JSON, so cached copies carry the new fields after the next
  refresh/bootstrap. Missing fields parse to safe defaults (tax disabled).

## 2. Domain — TaxConfig + TaxCalculator

New file `lib/features/pos/domain/tax_config.dart`:

- `TaxConfig { bool enabled; String name; double rate; bool inclusive; }`
  with `TaxConfig.fromBusiness(BusinessData)` and a `TaxConfig.disabled()`
  default. `rate` is the percentage (e.g. `15.0`).
- `TaxCalculator` (pure static functions or top-level):
  - `taxableAmount = subtotal − discount`
  - exclusive: `tax = round2(taxable × rate/100)`, `net = taxable + tax`
  - inclusive: `tax = round2(taxable − taxable / (1 + rate/100))`, `net = taxable`
  - disabled: `tax = 0`, `net = taxable`
  - `round2` = 2 decimals, ROUND_HALF_UP (for positive values Dart's
    `(x * 100).round() / 100` is half-up).
- Unit tests assert the spec's example table: rate 15%, taxable 90.00 →
  exclusive tax 13.50 / net 103.50; inclusive tax 11.74 / net 90.00; plus
  disabled and zero-rate cases.

## 3. Stop sending tax (golden rule)

- Remove `tax_amount` from `CreateSaleRequestDto.toJson()` (and the field
  itself plus its plumbing through `PosUsecase` / `PosRepository` /
  `PosRepoImpl` where it exists only to be forwarded).
- Remove `tax_amount` from the offline-sync payload built in
  `OfflineSaleDto.toJson()` / `OfflineSalesQueue`.
- Keep the `pending_sales.tax_amount` column (no destructive migration); it
  now stores the **local preview** only, displayed by the pending-sync
  screen — never sent to the server.

## 4. POS flow

- `PosState` gains `taxConfig` (default disabled) and derived getters:
  `taxAmount`, `netTotal`; `total` becomes the net payable (`netTotal`) so
  the payment button and cart peek charge the right amount in exclusive mode.
- `PosScreen` already reads `BusinessBloc`; it dispatches the selected
  business's `TaxConfig` into `PosBloc` on init and on business switch
  (new event, e.g. `OnTaxConfigChanged`).
- Receipt snapshot on submit success: add `lastTaxAmount`, `lastNetTotal`,
  and a snapshot of the active `TaxConfig`. **Online sales** prefer the
  server response values (`tax_amount`, `net_amount`, `tax_rate`,
  `tax_inclusive`); **offline sales** use the local preview.
- The local preview tax is written into `pending_sales.tax_amount` for
  display on the pending-sync screen.

## 5. UI

All new strings localized (en + ar) via the existing l10n setup.

- **Cart totals** — `TotalsSection` (mobile) and the desktop cart panel:
  - tax disabled or rate 0 → unchanged (Subtotal / Total).
  - exclusive → Subtotal, `Tax (VAT 15%)`, Total (= net).
  - inclusive → `Total (incl. VAT 15%)` with a secondary
    `Tax included: X` line.
- **Receipt** — `SaleReceiptSheet` (rendered sheet + shared/WhatsApp text):
  same exclusive/inclusive layouts as §2 of TAX_SUPPORT.md.
- **Sales history** — `SaleDto` parses `tax_amount`, `tax_rate`,
  `tax_inclusive`; the sale detail sheet shows the tax line (exclusive vs.
  inclusive layout) using the **snapshot** values from the sale, not live
  settings.
- **Reports/dashboard** — surface `summary.total_tax_collected` from
  `/api/v1/sales/reports/` as a "Tax Collected" KPI; hidden (or zero) when
  tax is disabled.
- **Business settings** — read-only card on the business detail screen:
  e.g. `VAT · 15% · prices exclude tax`, or `Tax disabled`.

## 6. Offline behavior

- Cart preview and offline receipts compute from the **cached** business
  config (fields ride along in the cached business JSON).
- Pending-sync screen keeps displaying the stored preview tax.
- After sync, server values are authoritative (existing sync-result flow);
  no new sync machinery. Known accepted behavior: if tax settings change
  while a device is offline, synced sales get sync-time settings (documented
  in TAX_SUPPORT.md §4).

## 7. Error handling / edge cases

- Businesses without tax fields in cached JSON → defaults (disabled) — no
  crashes on stale caches.
- `tax_rate` parsed defensively (`double.tryParse`, fallback 0).
- Sales-history records predating tax support (`tax_amount` null/`"0.00"`)
  render without a tax line.
- Receipt for offline sale later reprinted from sales history uses server
  values once synced.

## 8. Testing

- Unit tests for `TaxCalculator` (spec example table, rounding, disabled,
  inclusive/exclusive).
- Unit test that `CreateSaleRequestDto.toJson()` and the offline-sync
  payload contain **no** tax keys.
- Widget/bloc-level checks where practical for totals display in the three
  modes (disabled / exclusive / inclusive).
