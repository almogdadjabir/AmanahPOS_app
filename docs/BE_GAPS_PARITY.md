# BE + Dashboard gaps: desktop/mobile parity and per-business feature switches

Audience: the backend agent for `amanaPOS-be` and the dashboard agent for `amanaPOS-Dashboard`.
Source: `docs/audits/2026-11-26-desktop-vs-mobile-parity-audit.html` and the phase plan `docs/superpowers/plans/2026-11-26-mobile-parity-phases.md`.
Same rules as `docs/BE_GAPS.md`: additive, backward compatible, old app versions keep working. Mobile and desktop will not edit the BE or the dashboard.

## The idea

An owner decides, from the dashboard, which till features are on for the business. Mobile and desktop read the switches (feed/bootstrap business row) and show or hide the feature. Today only shifts and receipt settings are on the business row. We need the rest.

These are **business settings** (owner choice), not **plan features** (`plan.features`, subscription gating). A switch can be later tied to a plan feature, but that is out of scope here. Do not mix the two.

## G1. New business switches (BE)

Add to `Business` (migration), to the business row in feed, bootstrap and `offline/serializers.py`, to `business.update` (owner only), and to the REST business serializer (`apps/tenants/serializers.py`, next to `shifts_*`).

| Field | Type | Default | Meaning |
|---|---|---|---|
| `split_payments_enabled` | bool | `true` | Till may take one sale paid by two or more methods (`payments[]` with more than one part). Off: the till shows no split option. |
| `on_account_enabled` | bool | `true` | Till may sell on account (`credit` method, also as a part of a split) and manage customer debts. Off: no `credit`, no debt screens. |
| `line_discount_enabled` | bool | `true` | Till may give a discount on one line. |
| `sale_discount_enabled` | bool | `true` | Till may give a whole-sale discount. |
| `stock_count_enabled` | bool | `true` | Till may run a stock count (`stock.count`). |
| `cash_drawer_enabled` | bool | `false` | Pay-in, pay-out and expected-cash tracking inside a shift. Only meaningful while `shifts_mode != off`. |

Existing, already there and kept as they are: `shifts_mode` (`off|auto|manual`), `shifts_auto_open`, `shifts_auto_close`, `shifts_cashiers_may_operate`, `receipt_header`, `receipt_footer`, `receipt_paper_width`, `receipt_copies`, `receipt_auto_print`, `tax_*`.

Defaults keep today's behaviour for existing businesses (everything that already works stays on), except `cash_drawer_enabled`, which is new behaviour and starts off.

Open point for the BE agent: one JSON column (`pos_features`) or six boolean columns? Mobile and desktop do not care. Booleans are easier to validate and to show in the feed; pick one, tell us the final names, and do not rename them later.

## G2. Server-side enforcement (BE)

The switch is a till rule, but the server must not be fooled by an old app:

- `sale.create` with more than one payment part while `split_payments_enabled=false` -> **accept** (never lose a finished sale, same principle as sync-contract §4.4) with warning `split_not_allowed`. Do not reject.
- `sale.create` with method `credit` (or a credit part) while `on_account_enabled=false` -> accept with warning `on_account_not_allowed`.
- `debt.payment` / `debt.writeoff` while `on_account_enabled=false` -> `rejected: not_allowed` (these are new ledger writes, nothing is lost).
- `shift.*` and `cash_movement.create` while `shifts_mode=off` -> `rejected: not_allowed`; `cash_movement.create` while `cash_drawer_enabled=false` -> `rejected: not_allowed`.
- `stock.count` while `stock_count_enabled=false` -> `rejected: not_allowed`.
- Line and sale discounts: accept with warning, same reasoning as sales.
- Add each new code/warning to `sync-contract.md`.

Reason for "accept with warning" on sales: an offline till may have been switched off on the dashboard after the sale happened. The sale already took place.

## G3. Dashboard Settings screen (Dashboard)

New section in business Settings (owner only), beside the existing shifts and receipt sections:

- Switches for the six fields above, each with a one-line explanation, saved with `business.update` (or the REST business PATCH).
- Dependency hints: Cash drawer is disabled (greyed, with the reason) while Shifts is Off. On account off hides debts everywhere.
- A note under each switch: "Tills pick this up the next time they sync."
- Existing shift and receipt settings must keep working and appear in the same place.
- Arabic and English, RTL.

## G4. Receipt settings on the dashboard (Dashboard + BE check)

Mobile will print the same receipt as desktop. Check that the dashboard exposes everything the receipt uses, all owner-only:

- `receipt_footer` (max 80 characters, desktop limit `ReceiptSettings.FooterMaxLength`), `receipt_paper_width` (58 or 80), `receipt_copies`, `receipt_auto_print`, logo on or off (is there a `receipt_show_logo`? desktop has `receipt.show_logo`; if the business row has no such field, add `receipt_show_logo` bool default `true`).
- `receipt_header`: desktop does not use it. Tell us if it is used anywhere; mobile will ignore it unless told.

## G5. Shifts in pull/bootstrap (BE) - later, not blocking

`docs/pos-pairing.md` says shifts, cash movements and debts are not in pull/bootstrap. Until they are, a reinstalled phone loses its local shift history and two tills in one shop cannot see each other's shifts.
Please add feed entities `shift`, `cash_movement`, `debt_entry` (and bootstrap pages) when you have time. Until then mobile treats them as local + push only. Tell us when it lands so we can add the applier.

## G6. Customer balance (BE) - check

The receipt shows "owes now". Mobile computes it locally from the ledger it has. If `debt_entry` is not in the feed (G5), a phone cannot know a customer's balance from another till. Please say whether `customers` rows in the feed can carry a `debt_balance` (read-only, server computed) so mobile can show it. If not, mobile shows the balance only from its own ledger and says so.

## G7. Pairing started from the phone (BE + Dashboard) - mostly confirmation

Owner's scope (2026-11-26): the signed-in owner/manager creates the pairing code **from the mobile app**, exactly as the dashboard `/{locale}/link-device` page does. The desktop then redeems it. The existing endpoints already cover this: `POST /api/v1/sync/pairing/`, `GET /api/v1/sync/pairing/<id>/`, redeem and choose. Please confirm or fix:

- `POST /sync/pairing/` works with a mobile-app JWT (no step-up `auth_time` needed) and with `X-Tenant-ID`/`business_id` for owners with several businesses.
- The QR the desktop shows: what URL does it contain today (dashboard `link-device`, with or without a `device`/`name` hint)? Mobile needs a stable format to recognise it. Proposal: `https://app.amanapos.com/{locale}/link-device?src=desktop` (any extra query ignored). If the desktop QR needs to carry more (device name, platform), tell us the parameter names so both sides agree. This is a desktop change, so tell the owner, not the app.
- `GET /sync/pairing/<id>/` returns `device_name` once `used`, so the phone can say "Counter 1 linked".
- Dashboard Devices list shows the paired device with platform and a revoke button (confirm).
- Optional: universal/app links. If the owner wants the phone to open the app directly when the QR is scanned with the system camera, we need `/.well-known/assetlinks.json` and `apple-app-site-association` on `app.amanapos.com`. Say if that is wanted and who hosts it.

## Acceptance (what we will check from the app side)

1. Turn each switch off on the dashboard, sync a till, the feature disappears. Turn it on, it comes back.
2. An old app version that ignores the switch can still push a finished sale without losing it.
3. `business.update` with each new key from a cashier is `forbidden`.
4. Feed, bootstrap and the REST business endpoint all return the same six fields.

## Order we need things in

G1 + G2 + G3 first (blocks mobile phases 3, 4 and 5). G4 can go with them. G5 and G6 are improvements, G7 is confirmation only and can happen any time before mobile phase 7.

## G8. Cashier discount setting (BE + Dashboard)

New per-business till switch `cashier_discount_mode`: `off` (default) | `approval` (cashier needs the owner PIN) | `free` (cashier discounts alone). Same place and delivery as the G1 switches (sync bootstrap `business_features` row, dashboard "Till rules"). The phone only reads it. Owner and manager are never restricted.
