# Phase 5: Team (users) local-first, short design

Parent: 2026-11-16-offline-first-sync-design.md, BE_GAPS section 9, BE docs/sync-contract-deviations.md #26-28.

## Intent
Owner can add / edit / change role / change shop / deactivate / reactivate team members with no server; changes ride the outbox. Real money: a stale role/shop change is never applied silently.

## Goals
- Reads from `synced_entities` (user), reactive via DbChangeNotifier; no spinner.
- Writes via LocalWriter + outbox: `user.create|update|deactivate|set_role|set_shop`.
- Offline-created member shows "Invite pending" until push result (`invite_sent`) / pull echo confirms; cannot log in until then.
- `conflict_version` (role/shop): park item, local row reverts to server_state, team row shows "not applied, server has X" with **Apply mine again** (re-queue with fresh base_version) / **Dismiss**. Never auto-retried, never silent.
- `conflict_unique` on create (phone exists in tenant, `conflict_entity_id`): park, show reason, owner dismisses (merge deferred).
- `forbidden`/`validation_error`/`limit_exceeded`: parked with user-visible reason; local optimistic row reverted.
- Cashier: only own `user` row exists locally; team entry points stay owner-only.
- account_disabled / device_revoked: existing SessionGuard path, outbox never deleted (verify by test, no new mechanism).

## Non-goals
Customer-style merge-into-existing for duplicate phone; DB bump (stays v14); BE edits (gaps go to BE_GAPS.md); shop/business/subscription changes (stay online-only).

## Approaches
A (chosen by owner): park + explicit re-apply. B silent re-base: rejected, violates the no-silent rule. C park only: clumsy.

## Builder's calls
- Optimistic local row carries `sync_state` marker (pending|synced|rejected) following the Phase 4 refund/customer pattern.
- base_version for set_role/set_shop = local synced version of the row; update/deactivate send none (BE does not guard them) except when payload touches role/shop.
- Own account and owner row are non-editable in UI (BE refuses).
