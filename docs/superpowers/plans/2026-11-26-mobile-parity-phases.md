# Mobile parity with desktop: phases

Source: `docs/audits/2026-11-26-desktop-vs-mobile-parity-audit.html`. Backend and dashboard asks: `docs/BE_GAPS_PARITY.md` (G1 to G7).
Rule for every phase: design approved first (HTML mockup for anything visual), then code. Desktop code is a reference, never copied blindly. Each phase ends with `flutter analyze` clean for the files touched and the tests for the phase green. The owner commits.

## How features are switched on and off

The owner decides in the dashboard, per business. The till reads the switches from the business row it already syncs (`business_applier`) and stores them locally, so it works offline. A switch only hides or shows the feature on the till; the server never loses a finished sale because a switch changed (BE_GAPS_PARITY G2).

One small service on mobile, `BusinessFeatures`, reads the stored row and exposes plain getters (`splitPayments`, `onAccount`, `lineDiscount`, `saleDiscount`, `stockCount`, `shiftsMode`, `cashDrawer`). Every screen asks it. Nothing else reads the raw columns. Until the backend sends a field, the getter uses the default listed in G1 so the app keeps working against the current server.

## Phases

| # | Phase | Needs BE | Switch | Size | Notes |
|---|---|---|---|---|---|
| 1 | **Receipt: one widget, image/PDF share, thermal image** | none (receipt settings already on the row) | none (receipt settings: footer, paper, logo, copies, auto print) | M | Fixes the offline PDF font bug and the hard-coded English. Needs the decisions below. |
| 2 | **Business features service + settings read** | G1 fields (works with defaults before) | all | S | `BusinessFeatures`, migration for the new columns, applier changes. Unblocks 3 to 6. |
| 3 | **Shifts and cash drawer** | G1 `cash_drawer_enabled`, G2 | `shifts_mode` (exists), `cash_drawer_enabled` | L | Tables, service, outbox (`shift.*`, `cash_movement.create`), screen, top chip, expected-cash maths from desktop `CashExpectation.cs`. |
| 4 | **Split payments** | G1 `split_payments_enabled` | yes | M | Split sheet at checkout, parts sum to net, receipt prints parts, refund rule of desktop issue #65/#66. |
| 5 | **On account and customer debts** | G1 `on_account_enabled`, G2 | yes | L | `credit` method, ledger screen, `debt.payment`, `debt.writeoff` (owner/manager), "owes now" on receipt. Server owns sale/refund entries. |
| 6 | **Line discount, sale discount, stock count** | G1 | yes | M | Small separate pieces; cashier guard on stock count. |
| 7 | **Pairing from the phone** | G7 (mostly confirm) | n/a | M | Owner is signed in on the phone; scans the QR the desktop shows (or opens the link), and the phone generates the 6-digit code, same as the dashboard `/link-device` page. Backend endpoints already exist. See detail below. |
| 8 | **Cleanup** | none | n/a | S | Analyzer warnings, `UI-REVIEW.md` items, cancel-sale decision, owner-approval flow. |

Phases 1 and 2 can go in parallel with the backend agent working on G1 to G4. Phase 3 does not start until G1 and G2 are in a running backend.

## Phase 1 detail (starts now)

Decisions the owner must make first (recommendation first):

Decided by the owner on 2026-11-26:

1. Font: **desktop keeps Segoe UI** (not changed). Mobile cannot ship Segoe UI (Microsoft licence). Plan: ship **Selawik** (Microsoft's open-source, SIL OFL, metric-compatible replacement for Segoe UI) for Latin text, so widths and line breaks equal desktop. Arabic: desktop falls back to Tahoma/Arial on Windows, which also cannot ship; mobile uses a bundled Arabic font whose widths will differ a little. Result: same layout, same sizes, same rows; glyph shapes may differ slightly, Arabic most. This is the honest limit of "100%".
2. PDF: the receipt image placed on a roll-width page (exact to the screen, text not selectable). **Chosen.**
3. Thermal: print the receipt as a raster image, text path as fallback. **Chosen.**
4. Share: image only, no text, same helper as Baraka (`sharePngFromWidget`). **Chosen.**

Work:
1. `ReceiptData` (plain data, mirrors desktop `Receipt`): built from the local sale, refunds, customer, cashier, tax snapshot, payment parts, business profile, logo, receipt settings.
2. `ReceiptPaper` widget: port of `ReceiptVisual.Build` (58 mm = 219 px, 80 mm = 302 px at 96 dpi; padding 12/16/12/20; sizes 17/15/12/11/10.5/10; ink `#111111`, grey `#555555`; dashed rules; Latin digits and LTR numbers in Arabic; date `dd MMM yyyy · HH:mm` in business time).
3. Strings: `Receipt_*` keys into `app_en.arb` and `app_ar.arb` with the desktop wording.
4. Screen: sale-complete sheet and sale detail show `ReceiptPaper`.
5. Share image: `RepaintBoundary` to PNG at pixel ratio 3, share the file only, no text.
6. Share PDF: same PNG on a roll-width page, no text line.
7. Thermal: raster print through the existing printer service; text path stays as fallback.
8. Remove `PdfGoogleFonts` and the A4 PDF; remove the text share.
9. Golden tests (fixed fixtures, EN and AR, 58 and 80 mm). Compare to desktop PNGs rendered from the same fixtures; owner approves the side-by-side before the phase is done.

Not in phase 1: shifts, split, debts. The receipt already has places for split parts, line discount and owes-now so later phases only feed it data.

## Phase 7 detail (scope set by the owner, 2026-11-26)

The phone does what the dashboard `/link-device` page does:

1. The desktop shows a QR (it opens the dashboard link-device page today). The owner scans it with the phone's camera (`mobile_scanner` is already in the app) or opens the link.
2. The app recognises the link-device address and opens an in-app "Link a POS" screen (owner or manager only).
3. The screen calls `POST /api/v1/sync/pairing/` (JWT, optional `business_id`) and shows the 6-digit code, a 5-minute countdown and a "new code" button (the old live code is replaced; 10 codes per hour limit shown as a friendly message on 429).
4. It polls `GET /api/v1/sync/pairing/<id>/` until `status` is `used`, `expired` or `replaced`. Statuses `choosing` and `used` show the device name from `device_name`.
5. The desktop types the code. Merge or new-business is chosen on the desktop (`choose`), nothing extra on the phone.
6. Also from Settings: "Link a POS" entry for owners who do not scan.

No new backend work is expected. We only need confirmation of the items in `BE_GAPS_PARITY.md` G7 (what the QR contains, rate limits, device list in the dashboard).
