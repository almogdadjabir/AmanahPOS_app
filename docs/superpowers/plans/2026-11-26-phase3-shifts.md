# Phase 3: Shifts and cash drawer Implementation Plan

> For agentic workers: execute inline with superpowers:executing-plans. Steps use checkbox syntax.

**Goal:** Shifts (off/auto/manual), cash drawer (pay in/out, expected cash, count) on mobile, matching desktop behaviour, offline-first, switchable per business.

**Architecture:** Local tables `shifts` and `cash_movements` (DB v15). One writer `ShiftService` (LocalWriter: row + outbox in one transaction: `shift.open|close|count`, `cash_movement.create`). Pure maths in `CashExpectation` (cents, BigInt). Read side `ShiftStore` computes figures from local sales, payments, refunds and movements over the shift's time range. UI uses the app design system (`AppSheet`, `AppGroup`, `AppButton`, `SettingsRow`, `AppLargeTitle`). Switches come from `BusinessFeaturesService` (Phase 2).

**Spec:** mockup `docs/ui-revamp/phase3-shifts-mockup.html` (approved 2026-11-26, owner's three proposals accepted), desktop `AmanaPOS.Domain/Shifts/*`, backend `apps/sync/handlers.py` lines 917-1040.

## Global Constraints
- Money is exact decimal strings, never double (`ExactDecimal`).
- A sale is never blocked by a shift. Shifts off: no chip, no row, no screens.
- Drawer off, shifts on: shift is a work period with a sales summary, no opening cash, no count, no pay in/out. (owner decision)
- Auto schedule runs on app start, on resume and every 30 s while open; late opens use the scheduled time. (owner decision)
- Chip lives in the POS top bar. (owner decision)
- Permissions: owner/manager always; cashier open/close/count only when `shifts_cashiers_may_operate`; pay in/out any signed-in user.
- Wire payloads follow the backend: `shift.open {shop_id, opened_at, opened_by, opening_cash, origin, device_id, note}`, `shift.close {expected_cash, counted_cash, closed_at, closed_by, note}`, `shift.count {counted_cash, expected_cash, note}`, `cash_movement.create {shift_id, kind: pay_in|pay_out, amount, reason, occurred_at}` (depends on the shift's create).
- Git forbidden for me. The owner commits.

## Review Focus
- Close while a sale is being written: figures are read in the same transaction as the close.
- Two opens racing (double tap): second returns AlreadyOpen, no second outbox row.
- Close crossing a timezone/day boundary: ranges use UTC instants, display uses business offset.
- Pay out bigger than the drawer: allowed, flagged.
- Rejected shift push (e.g. `not_allowed` after the owner switched shifts off): row stays, visible in sync conflicts, never loops.

## Tasks

### Task 1: Schema v15
- Files: `lib/core/offline/offline_db.dart`, `test/core/offline/offline_db_v15_test.dart`, update `offline_db_v14_test.dart` version assertion.
- Produces: tables `shifts(id, shop_id, opened_at, closed_at, opened_by, opened_by_name, closed_by, closed_by_name, opening_cash, expected_cash, counted_cash, note, origin, sync_state)` and `cash_movements(id, shift_id, kind, amount, reason, occurred_at, user_id, user_name, sync_state)`; `OfflineDb.schemaVersion == 15`.
- [ ] Test: fresh DB has both tables; v14 DB upgrades and keeps rows; running the step twice is safe.
- [ ] Implement `createV15Schema` (idempotent), call from onCreate and onUpgrade.

### Task 2: Pure maths and schedule
- Files: `lib/features/shifts/domain/cash_expectation.dart`, `shift_schedule.dart`, tests.
- Produces: `CashParts`, `CashExpectation.expected/difference/payOutExceeds` (cents as BigInt strings in/out), `ShiftSchedule.evaluate(now, settings, openShiftOpenedAt, lastShiftOpenedAt)` returning `None|Open(at)|Close(at)`.
- [ ] Port desktop tests: expected = opening + cashSales + debt + payIns - refunds - cancels - payOuts; difference sign; schedule windows incl. crossing midnight and "closed early not reopened".

### Task 3: Models and ShiftStore (read)
- Files: `lib/features/shifts/domain/shift.dart`, `data/shift_store.dart`, tests.
- Produces: `ShiftInfo` (state open/needsCount/counted, difference), `CashMovementInfo`, `ShiftFigures(parts, other)`, `ShiftStore.open(shopId)`, `latest(shopId)`, `byId`, `carryOverCash(shopId)`, `list(shopId, limit, beforeOpenedAt)`, `figures(shift)`, `movements(shiftId)`, `countNeedingCount(shopId)`, `watch...` through DbChangeNotifier.
- [ ] Tests: cash sales from `sale_payments` method cash (and legacy `payment_method='cash'` with no payment rows), cancelled sales excluded, rejected refunds excluded, only `[opened_at, closed_at)` and the shift's shop, other methods listed as "other".

### Task 4: ShiftService (write) with permissions
- Files: `lib/features/shifts/domain/shift_service.dart`, tests.
- Produces: `ShiftService.open(...)`, `close(counted?, note)`, `count(shiftId, counted, note)`, `addMovement(isPayIn, amount, reason)`, `ShiftError` enum, result type; uses `BusinessFeatures` + role.
- [ ] Tests: one outbox row per call with the wire payload above; open twice -> AlreadyOpen and one row; close freezes expected; count only for needsCount; cashier blocked unless allowed; disabled/drawer-off errors; pay-out over drawer flagged; movement depends on the open row.

### Task 5: Auto schedule reconciler
- Files: `lib/features/shifts/domain/shift_reconciler.dart`, tests.
- [ ] Applies `ShiftSchedule` via `ShiftService` with origin auto (no user), idempotent per window; business-time conversion with `BusinessDay.offsetOf`.

### Task 6: State, strings, screens
- Files: `lib/features/shifts/presentation/{shifts_cubit.dart, shifts_screen.dart, shift_action_sheet.dart, shift_chip.dart}`, ARB (EN and AR), `settings_screen.dart` row, `pos_app_bar.dart` chip, routes, DI.
- [ ] Widget tests with a fake service for: states (off hidden, none, open drawer on, open drawer off, needs count), close difference text, pay-out warning, RTL smoke.

### Task 7: Verify
- [ ] `flutter analyze` for touched files clean; `flutter test` for core, shifts, receipt green; report limits (not run on a device, backend not proven).
