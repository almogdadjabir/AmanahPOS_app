# BE GAPS: offline-first sync for Amana POS mobile

Audience: the backend agent for `amanaPOS-be`. Mobile is being rebuilt as **offline-first**: after login + first setup the phone is the working copy of the business; the server may be unreachable for hours. The app writes everything locally, queues it, and a background service syncs in chunks. This document lists what the backend must add. Mobile will not edit the BE.

Everything here is **additive and backward compatible**. Do not change existing endpoint behaviour; old app versions must keep working.

Priority: **P0** = sync cannot be correct without it. **P1** = needed for a complete user lifecycle. **P2** = performance/hardening. **P3** = nice to have.

---

## 0. What exists today (so you do not rebuild it)

| Have | Where | Limitation for offline-first |
|---|---|---|
| `GET offline/bootstrap/` | `apps/offline` | Full dump every time, no cursor, no deletes/tombstones, no sales/users/vendors/refunds, one giant payload (no pagination). |
| `GET offline/assets/manifest/` | `apps/offline` | Uses `updated_at` only; includes entries with `url: null`; no hash. |
| `POST sales/offline-sync/` | `apps/sales` | Sales only. Idempotent via `client_sale_id`. Good pattern, generalise it. |
| `POST inventory/inbound/` | `apps/inventory` | Online only, no idempotency key. |
| `updated_at` (auto_now) | most models | Not a safe sync cursor (ties, clock, bulk updates skip it). |
| Soft delete | Product/Category/Customer use `is_active=False` | A deactivate is indistinguishable from a real delete; hard deletes (if any) leave no trace for other devices. |
| Server-generated UUID PKs (`editable=False`) | all models | Device cannot create a row offline and keep a stable id. |

---

## 1. (P0) Client-generated IDs

Offline creates need an id the moment the user taps Save, so the product can be used in a sale before it ever reaches the server.

Ask:
- Every syncable create (`Category`, `Product`, `Customer`, `Vendor`, `Shop`?, `User` invite, `InboundTransaction`, `StockMovement` via ops) accepts an optional `id` (UUID v4) from the client and uses it as the PK. Reject if the id exists under a **different tenant** (403, not 409, to avoid leaking). If it exists in the same tenant with the same `mutation_id` it is a replay (see section 2), not an error.
- Keep `editable=False` for admin; allow it through the sync service only.
- `Sale.receipt_number` stays server-assigned (unique, human-readable), the device shows a temporary local number (`L-<shopcode>-<n>`) until sync returns the real one. Confirm the receipt number allocation is race-safe under concurrent pushes (use a per-tenant/shop DB sequence or `select_for_update` counter).

---

## 2. (P0) One generic push endpoint (the outbox)

Today each feature would need its own idempotent endpoint. Instead:

```
POST /api/v1/sync/push/
Content-Encoding: gzip accepted
```

Request:

```json
{
  "device_id": "uuid",
  "app_version": "1.4.0",
  "client_time": "2026-11-16T10:00:00Z",
  "mutations": [
    {
      "mutation_id": "uuid",            // idempotency key, unique per tenant, globally
      "seq": 12,                        // device-local order; apply in this order
      "entity": "product",              // see entity table below
      "op": "create|update|delete|<custom op>",
      "entity_id": "uuid",
      "base_version": 7,                // row `version` the edit was made against; null for create
      "occurred_at": "2026-11-16T09:41:12Z",
      "payload": { }                    // entity-specific, same field names as the existing REST DTOs
    }
  ]
}
```

Response (HTTP 200 even when individual items fail):

```json
{
  "server_time": "2026-11-16T10:00:02Z",
  "results": [
    {
      "mutation_id": "uuid",
      "status": "applied|duplicate|rejected|retry",
      "entity_id": "uuid",
      "version": 8,                     // new row version after apply
      "server_seq": 123456,             // change-feed position of this write
      "code": "limit_exceeded",         // only on rejected/retry, machine readable (see 2.3)
      "message": "Plan allows 100 products",
      "server_state": { }               // only on rejected-for-conflict: current server row, so the app can reconcile
    }
  ],
  "next_cursor": "opaque"               // so the app can immediately pull what its own pushes caused
}
```

### 2.1 Required behaviours

1. **Idempotent by `mutation_id`.** Store applied mutation ids per tenant (table `sync_applied_mutations(tenant, mutation_id, result_json, created_at)`, unique `(tenant, mutation_id)`). Replaying an **applied** mutation returns the stored result with `status: "duplicate"`. Replaying a **rejected** mutation returns the same rejected result (`status: "rejected"`, same `code`), never `duplicate`. Results may come back in `seq` order; the app matches them by `mutation_id`. A `push.next_cursor` is informational only: the app must not adopt it as its pull cursor. A retry after a timeout must never double-apply. Retention >= 30 days.
2. **Ordered, per-item isolation.** Apply in `seq` order. Each mutation in its own `transaction.atomic`. One failure never aborts others. **Exception:** if mutation B depends on A (product create then sale using that product) and A is `rejected`, B must come back `rejected` with `code: "dependency_failed"` (not silently dropped).
3. **Batch size.** Accept up to **200 mutations** per call. Respond 413 with a clear code above that. Target p95 < 1.5 s for 200 mutations.
4. **Auth/permission per mutation**, using the same rules as the existing REST views (cashier cannot create products, shop scoping, etc.). Denied = `rejected` with `code: "forbidden"`.
5. **Subscription/plan limits** checked at apply time (max products/users/shops). Denied = `rejected` with `code: "limit_exceeded"`.
6. **Never lose a real sale.** See section 4. A sale that happened must be accepted even when stock is insufficient, the product was deactivated since, or the price changed.
7. Return `retry` (not `rejected`) for transient server-side failures (lock timeout, DB deadlock). The app retries `retry` with backoff and never retries `rejected`.

### 2.2 Entity / op table

| entity | ops | notes |
|---|---|---|
| `category` | create, update, delete | delete = deactivate + tombstone |
| `product` | create, update, delete | `payload.image_pending=true` when an image will follow (section 7) |
| `customer` | create, update, delete | `loyalty_points` is **server-owned**, client may not set it |
| `vendor` | create, update, delete | |
| `shop` | update | create/delete stay online-only (see section 9) |
| `sale` | `create` | reuses `_sync_one_sale`; `client_sale_id == entity_id == mutation payload id` |
| `sale` | `refund` | see section 4.3 |
| `sale` | `cancel` | |
| `stock` | `adjust`, `add`, `remove`, `transfer` | **deltas, not absolutes** (section 3) |
| `inbound` | `create` | existing inbound receive logic |
| `user` | `create`, `update`, `deactivate`, `set_role`, `set_shop` | see section 9 |
| `notification` | `mark_read`, `mark_all_read` | |

Payload field names must equal the existing REST request DTOs so mobile reuses its models.

### 2.3 Machine-readable `code` values

`forbidden`, `limit_exceeded`, `validation_error`, `not_found`, `conflict_version`, `conflict_unique` (e.g. duplicate SKU/barcode/phone), `dependency_failed`, `entity_deleted`, `subscription_inactive`, `server_busy` (retry), `payload_too_large`. Add `errors: {field: [msgs]}` on `validation_error`.

---

## 3. (P0) Stock must sync as a ledger of deltas

Two devices sell the same product offline. If the app pushed "quantity = 5" the second push would overwrite the first. Stock must be **commutative**.

Ask:
- `stock.adjust|add|remove|transfer` mutations carry `{product_id, shop_id, delta (signed decimal), reason, occurred_at}` (transfer: `from_shop`, `to_shop`, `quantity`). Server applies `F("quantity") + delta` inside the transaction, writes a `StockMovement` row with `mutation_id` for audit.
- An "absolute set" (stocktake) is sent as `op: "count"` with `{counted_quantity, expected_quantity_at_count}`. Server converts to a delta against the **current** quantity and records both in the movement, so concurrent sales are not erased.
- **Negative stock is allowed on sync** (flag `allow_negative=True` for synced sales and stock ops). The server returns `warnings: ["negative_stock"]` in the result; the app surfaces it to the owner. A POS must never refuse a sale that already happened in a shop.
- Sale creation already decrements stock; make sure that path also uses `F()` expressions and `select_for_update` on the `StockLevel` row so concurrent pushes from two devices cannot lose updates.
- Return the **resulting authoritative quantity** per affected `(product, shop)` in the push result (`stock_after: [{product_id, shop_id, quantity}]`), the device then re-bases its local pending deltas on it.

---

## 4. (P0) Sales: sync semantics

### 4.1 Accept-always rule

For `sale.create` the server must accept unless the data is structurally invalid. Specifically:
- Product deactivated/deleted since the sale: accept, keep the line with product snapshot.
- Price differs from current price: accept the **price on the line as sent** (it is what the customer paid). Do not re-price.
- Stock insufficient: accept, go negative (3).
- Customer deleted: accept, null the customer, `warnings: ["customer_missing"]`.
- Tax: use the tax config **as sent** (`tax_rate`, `tax_inclusive`, `tax_name` snapshot on the sale). Add these snapshot fields to the sale payload/model if they are not already stored per sale, so a later tax-rate change cannot alter history.

### 4.2 Required sale fields

Add/confirm on `sale.create` payload and persisted model: `client_sale_id`, `occurred_at` (device time, used for `created_at` reporting date, with server `received_at` kept separately), `cashier` (user id), `shop`, `device_id`, per-line `unit_price`, `unit_cost` snapshot (for profit reports), `discount`, tax snapshot, payment parts (see 4.4), `local_receipt_number` (kept for support lookups).

### 4.3 Refunds and cancels offline

- `sale.refund` mutation: `{sale_id, reference (client-generated, unique per sale already), items:[{sale_item_id, quantity}], method, reason, occurred_at}`. The existing unique constraint `(sale, reference)` becomes the idempotency guard. **The refund can arrive before its sale** (same batch, ordered by `seq`) which is fine, but if the sale is still unknown return `retry` with `code: "dependency_pending"`.
- The cumulative refund guard must stay: if two devices refund the same line, the second is `rejected` with `code: "refund_exceeds_sold"` and `server_state` (so the app can reverse its optimistic local refund and tell the user).
- Add refund `method` (cash/bankak/...) so drawer cash can be computed. (Also asked in `mobile-dashboard-gaps.md` #3.)

### 4.4 Split payments

Confirm how a `split` payment is stored. Offline reports and the drawer need per-method parts: `payments: [{method, amount}]`. If only `split` is stored today, add a `SalePayment` child table. Sum of parts must equal sale total, validate on push.

---

## 5. (P0) Pull endpoint: a real change feed

Replace "download everything again" with a cursor-based delta feed.

```
GET /api/v1/sync/pull/?cursor=<opaque>&limit=500&entities=product,category,...
```

Response:

```json
{
  "server_time": "...",
  "changes": [
    { "seq": 1001, "entity": "product", "op": "upsert|delete", "id": "uuid", "version": 8, "data": { /* full row, same shape as bootstrap */ } },
    { "seq": 1002, "entity": "category", "op": "delete", "id": "uuid", "version": 3 }
  ],
  "next_cursor": "opaque",
  "has_more": true,
  "full_resync_required": false
}
```

### 5.1 Requirements

1. **Cursor = monotonically increasing per-tenant sequence**, not a timestamp. Implement a `sync_changes(tenant, seq BIGSERIAL-like, entity, entity_id, op, version, shop_id NULLABLE, created_at)` table written in the same transaction as the data change (model `save`/`delete` hooks or explicit in services, not signals that can be skipped by `bulk_update`). `updated_at` ties and bulk updates are exactly what breaks timestamp cursors.
2. **Per-row `version` integer**, incremented on every write (`F("version")+1`). Needed for optimistic conflict detection on push (`base_version`). Add to: Category, Product, Customer, Vendor, Shop, User, Business. Backfill existing rows with 1.
3. **Tombstones**: deletes/deactivations appear in the feed as `op: "delete"` (and soft-deleted rows stay in the DB for at least 90 days). Deactivate (`is_active=false`) is still sent as `upsert` with `is_active:false`, a true delete is `delete`.
4. **`full_resync_required: true`** when the client cursor is older than the retention window or the tenant's data was bulk-restored/migrated. App then runs the full bootstrap again.
5. **Role-scoped**: cashiers receive only shared products + their shop's stock/batches/sales (same rules as current bootstrap). Feed rows carry `shop_id` so the filter is a cheap indexed query.
6. **Includes every entity the app works with**, not only the six in bootstrap: `business`, `shop`, `category`, `product`, `customer`, `vendor`, `stock` (resulting quantity per product/shop), `expiry_batch`, `sale` (with items + payments), `refund`, `inbound`, `user` (team, no secrets), `subscription`, `notification`, `bankak_account` (display data only).
7. **Paginated** (`limit` max 1000) with a stable order by `seq`. The first sync for a large tenant must stream in pages the app can write in one SQLite transaction each.
8. **Own-write echo**: a device must be able to ignore changes it pushed (`origin_device_id` on each change row), saves bandwidth and avoids flicker.
9. **gzip** responses; ETag/304 not needed.
10. **Performance**: p95 < 300 ms for a 500-row page, index `(tenant, seq)` and `(tenant, shop_id, seq)`.

### 5.2 Sales history window

Sales are the largest table. Pull sales for the last **N days (default 90, query param `sales_since`)** during bootstrap, then everything via the cursor. Older sales are fetched on demand online by the existing `GET sales/` list. Document the retention you pick.

### 5.3 Initial bootstrap

Keep `GET offline/bootstrap/` working for old apps. Add:
- `GET /api/v1/sync/bootstrap/?entity=product&page=1` (or a `cursor` equivalent) so the first-setup download is **paged and resumable** (current endpoint is one blob; on weak Sudan 3G a single 5 MB response that fails at 90% restarts from zero).
- Returns a `snapshot_cursor` taken **before** the first page, so after bootstrap the app pulls `sync/pull?cursor=snapshot_cursor` and misses nothing written during the download.

---

## 6. (P0) Server reachability + clock skew

Device connectivity (`connectivity_plus`) is not the signal that matters; "my server answers" is.

Ask: `GET /api/v1/sync/ping/` (no auth required, no DB hit, < 10 ms):

```json
{ "ok": true, "server_time": "...", "min_app_version": "1.2.0", "latest_app_version": "1.4.0", "maintenance": false, "retry_after": null }
```

Mobile uses it to (a) decide reachability, (b) compute clock skew so `occurred_at` can be corrected/flagged, (c) force-update gate, (d) honour `maintenance`/`retry_after`. Also make sure the load balancer returns 503/502 quickly (not 60 s hangs) when the app server is down, so the app's timeouts stay short.

Rate limit: sync endpoints need a **separate, generous throttle scope** (`sync`), the default Anon/User throttles will 429 a catch-up burst after a 2 hour outage.

---

## 7. (P1) Images

Products/categories with images created offline:

- Push `product.create` with `image_pending: true`, no binary in the push (keeps pushes small and retryable).
- `PUT /api/v1/products/<id>/image/` and `/categories/<id>/image/` accept `multipart/form-data` (single file field), **idempotent** (same bytes = same result; accept `Idempotency-Key` header, and `X-Content-SHA256` so a retry after a dropped connection is a no-op). Return the new `image`, `thumbnail_url` and bump `version` + emit a change-feed row.
- Add `image_hash` (sha256) to Product/Category and to the asset manifest and the feed, so the app downloads an image only when the hash changes (today it uses `updated_at`, which changes on any field edit and re-downloads every image).
- Manifest: drop entries whose url is null; add `bytes` size so the app can budget downloads on metered data and download thumbnails first.
- Optional P2: server-side resize variants (thumbnail 160px, card 480px, full 1080px) as stable URLs.

---

## 8. (P1) Auth that survives long outages

Mobile must keep working for days with no server. Ask:

1. **Refresh token rotation + blacklist** (`ROTATE_REFRESH_TOKENS`, `BLACKLIST_AFTER_ROTATION`) is dangerous with flaky links: if the refresh response is lost after the server rotated, the app's stored token is already blacklisted and the user gets logged out. Please make refresh **tolerant**: either a short grace window (e.g. 60 s) where the just-rotated token is still accepted and returns the same new pair, or return the new pair idempotently for a repeated refresh of the same old token. This is a P1 reliability bug waiting to happen on bad networks.
2. Refresh lifetime is 30 days. Confirm it is sliding (rotation extends it). The app treats `401` from **refresh** as "logged out"; it never logs out on timeouts/5xx.
3. `POST /api/v1/sync/push/` must return a distinct, typed `401` code `token_expired` vs `account_disabled` / `device_revoked` so the app can: re-auth silently (expired), or lock and wipe (disabled).
4. **Device registry** (P2): `POST /api/v1/sync/devices/` register `{device_id, name, platform, app_version, fcm_token}` and return the device's last push/pull time. Lets an owner revoke a lost phone (next successful sync returns `device_revoked`, app wipes local data). Also gives support a "last synced at" per device.
5. PIN/biometric stays local (already built on mobile). No BE work.

---

## 9. (P1) Team (users) offline

Creating a user triggers OTP/SMS/password flows that need the server and phone verification. Proposal (BE to confirm feasibility):

- `user.create` via push creates the account in state `invited` (no login yet), SMS invite goes out **at apply time** (i.e. when the phone reconnects). Result carries `status: applied` plus `invite_sent: true|false`.
- `user.update|deactivate|set_role|set_shop` are normal mutations. **Deactivating a user must take effect on that user's device at next sync** (`account_disabled` code, see 8.3).
- Role/permission changes must never be applied from a stale `base_version` silently: `conflict_version` is returned and the owner decides.
- Offline-created users get a placeholder in the app ("Invite pending") until the push result confirms.
- Shop create/delete, business create, subscription purchase, plan changes, Bankak account change and TOTP enrollment remain **online-only** (money/security). Mobile will block them with a clear "needs connection" message. Confirm this list is acceptable.

---

## 10. (P1) Conflict policy (server side, so mobile and BE agree)

- **Catalog entities** (category, product, customer, vendor, shop): field-level last-writer-wins by **server apply order**. If `base_version` differs, still apply non-overlapping fields; for overlapping fields apply the incoming one and return `status: "applied", "merged": true` with the final `server_state`. Reject with `conflict_version` only when the target row was **deleted** meanwhile (`entity_deleted`) or a unique key collides (`conflict_unique`, e.g. same barcode/SKU created on two phones).
- **Stock**: commutative deltas, no conflicts (section 3).
- **Sales/refunds**: append-only, no conflicts except the refund guard (4.3).
- **Delete vs edit**: delete wins; an update to a deleted row returns `entity_deleted`.
- Unique collisions must return the **conflicting row id** so the app can merge locally (e.g. map the duplicate barcode to the existing product instead of failing the user).

---

## 11. (P1) Dashboard / reports parity

The Home dashboard and reports will be computed **locally from synced data** for instant updates. For the numbers to equal the server's (and other devices'), mobile needs the exact rules:

- Document in the API schema the precise definitions: `REVENUE_STATUSES`, how refunds net out (by refund date vs sale date), tax handling, what "today" means (tenant timezone, shop opening hours if any), how custom-amount lines and split payments count. The open items in `mobile-dashboard-gaps.md` (#1 top sellers, #2 payment breakdown, #3 refund method, #4 custom amounts) must be fixed in the **synced data** (section 4.4 and 4.3) rather than only in the dashboard endpoint.
- Keep `GET sales/dashboard-summary/` and `GET sales/reports/` as the **reference** implementation. Mobile will add a debug check that compares local aggregates against it (when online) so drift is detected in testing.
- Add `GET /api/v1/sync/checksum/?entity=sale&since=...` returning `{count, sum_total, max_seq}` per entity (P2). The app uses it to self-audit ("my local sales count/sum for the last 7 days equals the server's") and trigger a repair resync if not. This is the safety net for "real people's money".

---

## 12. (P2) Hardening and observability

- Every push result and failure goes to `FailureEvent` (kind `offline_sync` exists, extend to cover all entities) with `device_id` and `mutation_id`.
- Admin-panel/system-health: counts of `rejected` by `code`, oldest unsynced device (`last_push_at`), devices not seen in > 24 h.
- Pull/push logging with duration and row counts. Alert on `sync_changes` table growth (prune applied tombstones older than 90 days only after confirming no device cursor is older, use per-device `last_cursor`).
- DB: `sync_changes` is write-hot, keep it narrow, partition or prune by age.
- Server must treat `occurred_at` more than 7 days in the future as suspect (clock error), accept the sale but set `occurred_at_suspect=true` and use `received_at` for reporting.
- Make `select_for_update` ordering consistent (product id order) in `create_sale` to avoid deadlocks when two devices sell overlapping baskets.

---

## 13. (P3) Wake-up hint

Optional: when another device writes data a shop device needs (price change, new product), send a **silent FCM data message** `{type: "sync_available"}` so the phone pulls promptly even if its periodic job has not fired. Mobile works without it (periodic + on-foreground + on-write triggers), so this is polish.

---

## Follow-ups found by the mobile Phase 1 work

- **`stock.add` should accept `expiry_date` / `batch_number` to create a batch** (like REST `POST inventory/stock/add/`, which creates a `ProductBatch` for expiry alerts). Until then the app sends dated adds through REST and refuses them offline ("Expiry tracking needs a connection").
- **Dashboard revenue basis**: endpoint sums `total_amount` (before sale discount and exclusive tax) while `sync-contract.md` says `net_amount`; BE agent to confirm which is intended; app currently matches the endpoint. (Same for the payment breakdown: the endpoint groups by `sale.payment_method`, a split sale being one `split` row; the contract says `sale.payments[]`.) The app's switch is `saleRevenueCentsSql` in `lib/features/dashboard/data/local/local_dashboard_queries.dart`.

## Follow-ups found by the mobile Phase 2 work

Found while building the paged bootstrap, the pull appliers and image sync (mobile spec `docs/superpowers/specs/2026-11-16-phase2-bootstrap-pull-assets-design.md`). Mobile works around each one today; none is blocking.

- **Expose the hash and size of the SERVED image variants.** `image_hash` is the sha256 of the UPLOADED bytes, but the stored `image` / `thumbnail` files are re-processed WebP (`process_and_upload_image`), so the device can never verify a download against it. Mobile treats `image_hash` as a change token only and verifies by HTTP 200 + non-empty + image magic bytes + `Content-Length`. Please add per variant e.g. `image_sha256` / `image_bytes` and `thumbnail_sha256` / `thumbnail_bytes` (hash of the bytes actually served) to `ser_product` / `ser_category` and the bootstrap items.
- **Legacy rows with an empty `image_hash`.** Rows uploaded before the hash existed carry `""`; mobile downloads them once keyed by url and never re-checks them. A one-off backfill (hash of the stored original) would let them follow the normal change-token path.
- **`stock_after` is `"0"` for untracked / restaurant products.** The push result for a sale line of a product that does not track stock (or any restaurant sale) returns `stock_after: "0"`, which a client could take as a real level. Please omit `stock_after` (or send `null`) when no StockLevel was changed.
- **`bootstrap_page` does not validate the snapshot.** It echoes `snapshot_cursor` without checking it against `pruned_through`; a stale snapshot is detected only by the first `pull` after the bootstrap (`full_resync_required`), after the whole download. Answering `full_resync_required` from `bootstrap_page` (or the manifest) as soon as the snapshot is older than `pruned_through` would save a full re-download on slow links.
- **Cheap bootstrap size hint.** Consider adding row counts per entity to the `sync/bootstrap` manifest (`{"entities": [...], "counts": {"product": 20134, ...}}`, approximate is fine) so the first-setup screen can show real progress instead of "step N of M" plus rows applied.
- **Dashboard revenue basis** stays open (see Phase 1 follow-ups: `total_amount` vs `net_amount`).
- **Refunds from other devices** now reach every device through the feed (`refund` entity -> local `sale_refunds`, netted on the refund `created_at`). Mobile relies on refund rows carrying `sale`, `shop`, `total` (string) and `created_at`; please keep them stable, and keep windowing bootstrap refunds by refund date OR parent sale date (deviation 22).

## Follow-ups found by the mobile Phase 3 work

Found while building offline catalog writes (mobile spec `docs/superpowers/specs/2026-11-17-phase3-catalog-writes-design.md`). Mobile works around each one today. The first two touch money and should go first.

- **(MONEY) A sale must not fail because a product EDIT in the same push was rejected.** `services._apply_one` collects the entity id of EVERY rejected mutation (`failed_ids`) and fails any later mutation in the same push whose `dependencies()` name it. So when a `product.update` for P is rejected (`validation_error`, `entity_deleted`, `forbidden`, ...), a `sale.create` with a line for P later in the same batch comes back `dependency_failed` and is NOT recorded, although P exists (or existed) on the server. That breaks the accept-always rule for sales (section 4.1): the money was taken at the till. Please only fail dependents of a rejected `create` (the only case where the referenced row does not exist), or never fail a `sale.create` / `sale.refund` on a dependency at all (keep the line with a warning, like `product_missing`). **Client workaround in place (Phase 3 fix wave):** mobile now treats a `dependency_failed` as `retry` when none of the row's dependencies has an open local create, so the sale is re-sent alone in the next batch of the same run and is recorded once (pinned by `catalog_push_results_test` "BE finding 1"; the convergence test reaches the case). This costs an extra round trip per affected push and still relies on the BE answering the lone retry `applied`; please fix the BE anyway, because older app versions and any client without this workaround still lose the sale until a manual retry.
- **(MONEY) Category rename uniqueness uses the request's parent, not the row's.** The name check for `category.update` compares against siblings of `payload.parent` (None when the request does not send `parent`), so renaming a child category is compared against the ROOT categories: a valid rename can be refused `conflict_unique`, and a real duplicate under the same parent can be accepted. Please use `payload.get("parent", obj.parent_id)`. (Labelled money because a wrong refusal blocks the catalog edit the till depends on; no amount changes.) Verified against the BE code: `apps/sync/handlers.py` `_unique_conflict` (lines 182-185) filters `parent_id=data.get("parent") or None`, and `catalog_update` (line 256) passes the update payload, which carries `parent` only when it changed. Mobile does not work around it: always sending the current `parent` on a rename could overwrite another device's move of that category.
- **`image_pending` on create.** Mobile sends `image_pending: true` in a product/category create payload when an image is staged and will be PUT once the create is confirmed. Please accept the key (ignore or store it) and echo it in `server_state`/the feed if stored, so other devices can show "image coming" instead of no image.
- **`PUT .../image/` must honour `Idempotency-Key` and return `version`.** Mobile sends `Idempotency-Key: <sha256>` and `X-Content-SHA256`; a lost response is retried with the same key and must not store a second image (the fake and today's BE treat same bytes as `unchanged`; please make it explicit on the key). The response must carry the row's new `version` (mobile adopts it so the next edit's `base_version` is right).
- **`conflict_entity_id` for category and vendor name collisions.** `conflict_unique` carries `conflict_entity_id` for product SKU / barcode only. Category (name per parent) and vendor (name, case-insensitive) collisions should carry it too: mobile offers "Merge into existing" only when the id is present (the UI keys off the field), so today those two only get "Edit and retry" / "Discard".
- **Cashier catalog rule.** The sync push refuses every catalog mutation from a cashier (`forbidden`, CASHIER_ALLOWED), while the legacy REST views allowed some catalog actions to cashiers. Mobile now follows the stricter push rule (writes hidden and refused locally for cashiers). Please confirm this is intended and align the REST permissions (or document the difference) so both paths agree.
- **Category delete rule.** Please document what `category.delete` does when the category still has products or child categories: refuse (protected) or cascade (deactivate them / set NULL). Mobile refuses locally while it has active products or active children (safe default) and shows the server's rejection otherwise; if the BE cascades, mobile must mirror that locally.
- **Cleared product fields (confirmed, keep stable).** On `product.update` mobile clears `cost_price` with `"0"` (NOT NULL, default 0), `barcode` with `""` (blank allowed, skipped by the unique check), and `expiry_alert_days` with `null`. Please keep these accepted.

## Follow-ups found by the mobile Phase 4 work

- **`customer.update` must accept `is_active`.** Mobile deactivates/reactivates a customer as `customer.update {is_active}` (the REST PATCH did the same). Please confirm the sync apply path accepts it (not only `customer.delete`), and that an update carrying `is_active` bumps `version`.
- **`sale.refund` shape mobile sends:** `{sale_id, reference (client UUID), items:[{sale_item_id, quantity}], method, reason?, occurred_at}`, mutation `entity_id` = the sale id. The refund row in the feed (`ser_refund`) must keep echoing the client `reference`: mobile replaces its local pending copy of a refund with the pulled server row by matching `(sale, reference)`, so a refund counts once. Please keep `reference`, `sale`, `shop`, `total`, `method`, `items[].sale_item/quantity/amount` stable.
- **Refund `method` for cash drawer:** mobile splits refund cash/bankak by the refund's own `method` (falling back to the sale's method for old rows). Please confirm refunds of split-payment sales: mobile sends `cash` when the sale was split; say if the BE wants something else.
- **Provisional refund total:** mobile computes the refund total locally (line_total x qty / sold qty, half-up to cents) and replaces it with the server's `refund_total` on `applied`. Please keep the server rounding rule documented so the two can agree.
- **Duplicate customer phone (`conflict_unique`)** returns `conflict_entity_id`; mobile now offers "Merge into existing" for customers as it does for catalog entities (sales of the copy move to the existing customer); it keys off `conflict_entity_id`, so please keep it on every `customer.create` collision.

## Acceptance checklist for the BE agent

Mobile will test against these. Please add backend tests for each.

- [ ] Replaying the same `mutation_id` twice returns `duplicate` and changes nothing.
- [ ] A batch of 200 mixed mutations applies in `seq` order, one failing item does not affect others, dependents of a failed item return `dependency_failed`.
- [ ] Two devices push `stock.add +5` and `sale of 3` concurrently, final quantity is exact, no lost update.
- [ ] A sale with insufficient stock / deactivated product / changed price is **accepted** with warnings.
- [ ] Client-supplied UUID on create becomes the PK; same id from another tenant is rejected without leaking.
- [ ] `sync/pull` returns upserts and delete tombstones in `seq` order, paginated, role-scoped for cashier, `full_resync_required` on stale cursor.
- [ ] Snapshot cursor taken before bootstrap pages prevents missed writes during the download.
- [ ] Refresh-token retry after a lost response does not log the user out.
- [ ] Deactivated user's next sync returns `account_disabled`.
- [ ] `sync/ping` answers in < 10 ms without auth.
- [ ] Image upload retry with same hash is a no-op; hash changes only when bytes change.
- [ ] Concurrent refund of the same line from two devices: exactly one wins, the other gets `refund_exceeds_sold` with `server_state`.
- [ ] Throttle scope `sync` does not 429 a 200-mutation catch-up burst after outage.

## Suggested delivery order for the BE

1. Section 1 + 2 + 3 + 4 (push, client ids, stock deltas, sale semantics). Mobile can already queue and sync with this.
2. Section 5 + 6 (change feed, ping). Enables multi-device and the "dashboard updates instantly" local reads.
3. Section 8.1 + 10 (auth tolerance, conflict policy).
4. Sections 7, 9, 11, 12, 13.

Mobile will build against this contract with a fake server in tests, so the BE agent can ship in the order above and mobile switches on feature by feature (capabilities are advertised in `sync/ping`: add `"capabilities": ["push","pull","bootstrap_paged","image_hash","devices","checksum"]` so the app enables only what the server supports).

---

## Follow-ups found by the mobile Phase 5 work

- **`user.create` duplicate phone**: `conflict_unique` already returns `conflict_entity_id` for a phone inside the tenant. Mobile parks it and shows "a member with this phone exists"; Dismiss is the merge (the invite references nothing else locally). Please keep `conflict_entity_id` stable.
- **Role/shop via `update`**: `update` only checks `base_version` when it is sent. Mobile always sends it for role/shop, but a client that omits it is applied silently. Recommend requiring `base_version` whenever `role` or `default_shop_id` is in an `update` payload (same rule as `set_role`/`set_shop`).
- **Version bumps by `deactivate` / reactivate**: both bump `version` and are not guarded. Mobile re-bases its own queued role/shop edits when `version == base + 1`; please keep one bump per applied mutation so that rule stays valid.
- **Cashier feed**: confirm a cashier's feed carries exactly their own `user` row, including a `delete` tombstone if they are deactivated (the device then gets `account_disabled` anyway).
- **`last_login_at` freshness**: the feed row only changes when something else bumps the version; the "Last sign in" line can be stale on other devices. Acceptable, or bump version on login?

---

## Consolidated open list for the BE agent (mobile Phases 1-5)

One list, most important first. Detail for each is in the "Follow-ups found by the mobile Phase N work" sections above.

**Money / correctness (do first)**
1. A sale must never fail because a product edit in the same push was rejected (`dependency_failed` on a sale line). Mobile retries alone, older clients lose the sale (Phase 3).
2. Category rename uniqueness must use the row's parent when `parent` is not in the payload (Phase 3).
3. Dashboard revenue basis: `total_amount` vs `net_amount`, and payment breakdown by `payment_method` vs `payments[]` (Phase 1).
4. Document the refund rounding rule and confirm the refund `method` for split-payment sales; keep echoing the client `reference` in the refund feed row (Phase 4).
5. `update` carrying `role` or `default_shop_id` must require `base_version` (same as `set_role`/`set_shop`); keep exactly one version bump per applied mutation, including `deactivate` and reactivate (Phase 5).

**Missing fields / behaviour mobile is waiting on**
6. `stock.add` accepts `expiry_date` / `batch_number` (creates a batch). Until then dated adds need a connection; this cannot be done on mobile alone (Phase 1).
7. `conflict_entity_id` on category and vendor name collisions (and keep it on customer / user / product collisions) (Phases 3-5).
8. `customer.update` accepts `is_active` and bumps `version` (Phase 4).
9. `image_pending` accepted on create; image `PUT` honours `Idempotency-Key` and returns `version` (Phase 3).
10. Per-variant image hash and size of the SERVED files; backfill empty `image_hash` (Phase 2).
11. `stock_after` omitted (or null) when no stock level changed (Phase 2).

**Nice to have**
12. `bootstrap_page` / manifest answer `full_resync_required` for a stale snapshot; row counts per entity in the manifest (Phase 2).
13. Confirm the cashier catalog rule (push is stricter than REST) and the `category.delete` rule (Phase 3).
14. Feed row for a cashier carries exactly their own `user` row; `last_login_at` freshness (Phase 5).
15. Checksum: keep `created_at` as the `since` window field and `max_seq` a per-entity number; confirm `sum_total` basis vs the dashboard (Phase 6, items 15-17 above).

## Follow-ups found by the mobile Phase 6 work (checksum audit)

- **15. Checksum window**: `sync/checksum?since=N` filters sale by `created_at >= now - N days`; the app compares by the sale's `received_at` (your `created_at`). A row within 5 min of the cutoff is treated as inconclusive. Please document `since` as integer days (it is) and keep `created_at` as the window field.
- **16. `max_seq`**: the app uses it as an "did the server move during the audit" probe (two calls per entity, equal `max_seq` required). Please keep it a number (int) and per-entity (it is today). A global seq works but makes the audit inconclusive more often.
- **17. `sum_total` basis**: sale `sum_total` is `net_amount` over all statuses, while `dashboard-summary` sums `total_amount` (item 3). The audit compares raw synced totals, so it is unaffected, but the debug dashboard parity log will show a difference whenever sales carry a sale discount or exclusive tax until item 3 is answered.

## FINAL STATUS (BE closed out 2026-11-17, local only: migrated, server restarted)

Implemented in the BE repo (tests in `apps/sync/tests/test_mobile_gaps.py`; sync/inventory/products/offline/customers/accounts suites green, 346 tests; no model change so NO new migration, `makemigrations --check` clean, `migrate` had nothing to apply):

| # | Item | Result |
|---|------|--------|
| 1 | Sale failed by a rejected product edit | **Fixed** (`sync/services.py`): only a rejected `create` poisons dependents; a rejected update/delete/refund leaves the row, so the sale in the same push applies. |
| 2 | Category uniqueness uses the row's own parent | **Fixed** (`handlers._unique_conflict`): an update without `parent`/`name` uses the row's own value; moving under a parent is checked too. |
| 5 | `update` with `role`/`default_shop_id` | **Fixed**: requires `base_version` (like `set_role`/`set_shop`); a plain rename needs none; one version bump per applied mutation (tested incl. `deactivate`). |
| 6 | `stock.add` expiry | **Fixed**: `expiry_date` (YYYY-MM-DD) + `batch_number` (<=100) create a `ProductBatch`; bad date -> `validation_error`; replay makes one batch. Mobile side is now unblocked (open on the app). |
| 7 | `conflict_entity_id` | Already present on every unique clash (category, vendor, customer, user, product) and on "already exists"; now covered by tests. |
| 8 | `customer.update` `is_active` | Already supported (managers/owners; a cashier's `is_active` is ignored); version bump covered by a test. |
| 9 | `image_pending`, image PUT | `image_pending` is accepted (stripped) on create; the PUT already echoes `Idempotency-Key` and returns `version`. |
| 10 | Image size/hash | Feed rows now carry `image_bytes` and `thumbnail_bytes`; `backfill_image_hashes` command already exists. A separate per-variant hash would need a new column (not done, mobile does not need it). |
| 11 | `stock_after` | Omitted when empty (already) and now also when a count/adjust changes nothing. |

Confirmed / documented, no code change:
- **3 / 17** dashboard and checksum basis: the sales stats queries aggregate `net_amount`, checksum `sum_total` is `net_amount` over all statuses, `sum_revenue` is revenue statuses only. Left as is; changing the dashboard basis is a product decision, not a sync fix.
- **4** refund rounding: per line `unit_price * qty` quantized to 0.01 (Decimal default half-even), summed; the client `reference` is echoed as `refund_reference`.
- **13** cashiers: push allows a cashier only sale create/refund/cancel, customer create/update, stock add/remove/adjust, notifications (stricter than REST); `category.delete` is manager+ (soft delete + tombstone).
- **14** pull for a cashier carries exactly their own `user` row (`pull.py` excludes other users).
- **15 / 16** checksum: `since` is integer days on `created_at`; `max_seq` is an int per entity.

Deliberately NOT done:
- **12** `full_resync_required` from `bootstrap_page` and per-entity counts in the manifest: the mobile bootstrapper does not read that flag on pages, so answering it there would make the app treat an empty page as a finished bootstrap. Today the first `pull` after the bootstrap detects a stale snapshot safely. Do this only together with mobile support.

**Item 6 mobile side (done 2026-11-17):** the BE advertises capability `stock_add_expiry` in the ping; the app then queues a dated add as a normal offline `stock.add` with `expiry_date` (and optional `batch_number`). Without the capability (older BE) the previous online-only REST path stays. Checklist item 21 in docs/offline.md.
