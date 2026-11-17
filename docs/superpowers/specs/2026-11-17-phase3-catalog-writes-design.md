# Phase 3: catalog writes (categories, products, vendors, images)

Date: 2026-11-17. Status: **implemented** (Tasks 1-9, 2026-11-17; whole-branch review and `/code-review` pending). Parent spec: [2026-11-16-offline-first-sync-design.md](2026-11-16-offline-first-sync-design.md). BE contract (read only): `amanaPOS-be/docs/sync-contract.md`, `sync-contract-deviations.md`, `docs/BE_GAPS.md` §2, §7, §10.

## Intent

Phases 0-2 made sales and stock work offline and made every server row arrive by bootstrap and pull. The catalog is still REST-first: adding a category, a product or a vendor, editing or deleting one, and uploading an image all need the server. The owner or manager must be able to do all of it with no connection (Sudan, server down for hours) and have it sync later without loss, duplication or silent overwrite. A product created offline must be sellable at once.

## Goals

- Create / update / delete for category, product and vendor are one local transaction (row + outbox) through `LocalWriter`; the UI updates instantly and never waits for the network.
- Client-generated UUID v4 ids; payload fields are exactly the existing REST request DTOs (money as strings); `base_version` = the local row version on update/delete.
- A freshly picked product/category image shows immediately from a local file and uploads in the background, retried until it succeeds, idempotently.
- Every push outcome is handled: applied/duplicate (adopt version), merged (take `server_state`), `conflict_unique`, `entity_deleted`, `forbidden`, `limit_exceeded`, `validation_error`, `dependency_failed`.
- Anything that references a catalog row with an unsent create (a product's category, a sale line, stock/inbound line) is never sent before that create is confirmed.
- Tests: red-first unit tests per applier and service, FakeSyncServer extended for these entities, convergence test extended with catalog actions, lifecycle scenarios.

## Non-goals / anti-goals

- No customers (Phase 4), no refunds/returns, no team, no shop writes.
- No expiry-dated `stock.add`, no F3 ghost-row sweep, no checksum: separate work.
- No silent rewriting of rows that carry money. Anti-goal: a sale, stock or inbound row ever pointing at an id the server will never know, without the user seeing it.
- No UI redesign (Nile Ledger stays); only data sources and a few new states (pending/failed markers, image pending, conflict actions).

## Constraints

- Zero users, no data migration; DB version bump allowed (v14).
- BE permission rule: catalog writes (category, product, vendor, all deletes) are owner/manager only. Cashier attempts are refused locally with a clear message (like `StockValidationException`), because the server would reject them with `forbidden`.
- Plan limits are server-checked (`limit_exceeded`); the app cannot know them offline and handles the rejection.
- `LocalWriter.write` cannot nest; bodies use `scope.txn` only; run tests in the foreground.
- The BE repo is never edited; BE needs go to `docs/BE_GAPS.md`.

## Approaches considered

1. **Service layer per entity on `LocalWriter`, local-only reads (chosen).** `CategoryService`, `ProductService`, `VendorService` mirror `StockService` / `SaleService`: validate, write the row, enqueue, return. Repos delegate to them; blocs read the local tables only. Matches the pattern already proven in Phases 1-2.
2. REST-first with a write-through queue fallback. Smaller diff, but it is the explicit anti-goal ("cache with write-through"), keeps two write paths and cannot make a new product sellable offline cleanly. Rejected.
3. One generic "catalog mutation recorder" instead of three services. Less code, but the entities differ in derived data (category counts/names, product stock level, image jobs, vendor names on inbound). A shared helper for id/base_version/enqueue is fine inside the services; a single generic writer is not. Rejected.

## Design

### Writes

Each service method is one `LocalWriter.write`: validate (role, required fields, decimal format), update the local row and its derived fields (same ones the appliers derive: product `category_name`, category `product_count`, product `stock_level` untouched), then `scope.enqueue`.

- **create**: id = new UUID; local row gets `version = null` (unsent), `entity` marked pending through the outbox (UI "waiting to sync" marker derived from open outbox rows, as for sales). Payload = `AddProductRequestDto.toJson()` / category / vendor DTO plus `id`, and for products `image_pending: true` when an image was picked.
- **update**: payload = only changed fields (the DTOs already skip nulls); `base_version` = local version. A second edit of a row whose create/update is still unsent is a new outbox row (per-entity order is already enforced by the claim rule); no coalescing in this phase.
- **delete**: local row is marked inactive (is_active=false, hidden from lists) rather than removed; enqueue `delete` with `base_version`. The pull tombstone later removes it. Delete of a row with an unsent create that was never sent may be dropped locally together with its outbox rows in one transaction (nothing on the server to delete); if dependents exist (sale lines, stock) it is sent normally.
- Local refusals (`CatalogValidationException`): cashier, empty name, bad money format, category cycle (parent), duplicate SKU/barcode against local rows (best effort; the server stays authoritative).

### Dependencies (outbox)

The outbox has one `depends_on_entity_id` column and no caller sets it today. A sale with three offline-created products needs several. Change: replace the column's use by a list (`depends_on` JSON array of entity ids, DB v14) with the same semantics: a row is `blocked` while ANY listed entity has an open `create` in the same scope; `unblockDependents` re-checks the remaining list; `failDependents` cascades (existing). Callers that must set it:

- `product.create` / `product.update` -> its category (if that category's create is open); `category.create` -> parent category.
- `sale.create` lines, `stock.add|remove|adjust`, `inbound.create` lines -> every product with an open create.
- `inbound.create` -> vendor with an open create.

Why it matters for money: per-entity ordering alone does not stop a sale from being pushed in a later batch than the product create that returned `retry`; the server would then keep the line with `product = NULL`.

### Push results (appliers' `onPushResult`)

| Result | Action |
|---|---|
| `applied`, `duplicate` | write `version` onto the local row; clear the pending marker. |
| `applied` + `merged` (+ `server_state`) | replace local fields with `server_state` (version too). |
| `rejected: conflict_unique` | **Approach A (your decision):** row stays local, outbox row `rejected` with the code and `conflict_entity_id`; user sees it on the pending-sync screen with two actions: *Merge into existing* (see below) and *Edit and retry*. Nothing is rewritten automatically. |
| `rejected: entity_deleted` (update) | the row was deleted on the server: keep local row inactive/read-only, mark rejected, user can discard. (`delete` + `entity_deleted` already converges in the engine.) |
| `rejected: forbidden / limit_exceeded / validation_error / not_found` | row stays, shown with the server message; `errors{}` mapped to the first message; retry = edit and re-enqueue; discard = revert local row to the last server state (see below). |
| `dependency_failed` (from `failDependents`) | dependents rejected with the dependency's name in the message. |

*Merge into existing* (user-initiated, one transaction): rewrite the local id to `conflict_entity_id` in `products`, `stock`, `sale_items`, open outbox payloads and `depends_on` lists, then drop the rejected create. This is the one place ids are rewritten, only on an explicit user action, with a confirmation that shows the count of affected rows.

*Discard of a rejected create*: delete the local row (and its pending stock rows via the existing `StockLocalStore.recompute`); dependents were already failed. *Discard of a rejected update*: restore the row from `synced_entities`-style last server state; the BE returns `server_state` on conflicts, otherwise the next pull restores it (the row is flagged "stale" until then). The builder decides the exact storage of the last server state (a `server_json` column vs. re-fetch); mark as builder's call.

Pulled changes keep using `skipWhenLocalPending` (local edit wins until confirmed) and `localVersion` (never roll back).

### Reads become local-only

`ProductBloc`, `CategoryBloc`, `VendorsBloc` still refresh from REST and `saveProductsToCache` / `saveCategoriesToCache` use `ConflictAlgorithm.replace`, which would overwrite or erase unsynced local rows. In Phase 3 these screens read the local tables only (the feed is the sole source, as in Phase 2): remove the REST refresh and the REST cache writers for these three entities, page from SQLite, and watch via `DbChangeNotifier` so a pull or a local write refreshes the list. "Waiting to sync" / "Sync failed" markers come from the outbox. Inactive rows are hidden from product pickers but stay resolvable for history.

### Images

- Pick -> copy bytes into `<appSupport>/pending_images/<entityId>` (a file we own, not the picker's temp path), compute `sha256` of the bytes, generate a small thumbnail (e.g. 160 px) for lists. New table `pending_uploads(entity, entity_id, local_path, sha256, bytes, state, attempts, next_attempt_at, last_error)` (DB v14).
- The local row shows the thumbnail/file through `OfflineCachedImage` (extended: a pending upload's local file wins over `synced_assets`).
- Create: push `product.create` / `category.create` with `image_pending: true`, no binary. Update with a new image: normal update plus a `pending_uploads` row (state `waiting`).
- Upload job (new `ImageUploader`, run by `SyncEngine` after push, and by the OS worker is NOT included: images are foreground only): for each upload whose entity has no open outbox `create`/`update` (so the row exists on the server and its version is current), `PUT api/v1/products/<id>/image/` or `products/categories/<id>/image/`, multipart field `image`, headers `X-Content-SHA256: <sha256>` and `Idempotency-Key: <sha256>`. Success -> response has `image`, `thumbnail_url`, new `version`: update the row, set `image_hash = sha256` (change token), `registerAsset`, delete the pending file only after the first verified download of the served image (or immediately, builder's call: the served image is re-processed WebP so the local file is not needed once the row shows the server image). Network/5xx/timeout: backoff (reuse AssetSync backoff constants), never give up. 400 `hash_mismatch`: recompute from the file; if the file is unreadable, mark failed and surface it. 403 / 404 / 413: park as failed with a message, retry-able from the pending-sync screen. 401 `token_expired`: refresh through the same authed path as the engine.
- Idempotent by hash, so a lost response then retry is a no-op; the `image_hash` the feed later returns equals the local sha256 (a test asserts this against the FakeSyncServer).

### Sync plumbing

`ProductApplier` / `CategoryApplier` / `VendorApplier.onPushResult` implement the table above; `tables` already include what they touch. `pending-sync` screen and `PendingSyncBloc` gain the new entity labels and the conflict actions. `FakeSyncServer` gets catalog create/update/delete with `base_version`, `conflict_unique` (with `conflict_entity_id`), `entity_deleted`, `limit_exceeded`, merge semantics and image PUT (idempotent by hash). The convergence test adds catalog actions on 3 devices.

### Carry-overs

- **F6 (`authedFor` duplication)**: a small separate task done first, since the image uploader needs the same authenticated-call helper.
- **Not in this phase**: Phase 4 (customers, refunds: MUST precede real money), F3 ghost rows, expiry-dated `stock.add` (waiting on a BE field, already in BE_GAPS), on-device checklist (Android 11 vs 12+ `getSdkInt`, iOS background).
- New BE asks for `docs/BE_GAPS.md` (to write with the work): confirm `image_pending` is accepted and echoed on create; confirm `PUT image` accepts `Idempotency-Key` and returns `version`; ask for `conflict_entity_id` on category/vendor unique collisions (name per tenant) not only product SKU/barcode.

## Left to the builder

Exact column sets and indexes for `pending_uploads` and the `depends_on` migration; thumbnail size and encoder; file naming; backoff constants; where last server state is stored for discard-restore; pending-sync screen layout (Nile Ledger); how the form screens show pending/failed states; task order within the plan.

## Calls I made (check these)

1. Cashiers are refused locally for all catalog writes (BE is stricter than today's REST).
2. Delete is a local deactivation plus an outbox `delete`; an unsent create is simply dropped.
3. No coalescing of repeated edits in this phase.
4. Multi-dependency list replaces the single column; sale/stock/inbound declare product dependencies.
5. Image uploads are foreground-only (the OS worker does not upload).
6. Catalog screens go local-only now (REST list refresh removed), not later.
7. Merge-into-existing is the only id rewrite and is user-triggered.

## Builder-check resolutions (added 2026-11-17)

Answered by the contract/repo (no change to the design):
- **`depends_on` is local only.** On the wire `depends_on` is a RESULT key of `dependency_failed` (deviation 8), not a request field. The BE applies a batch in `seq` order and fails dependents of a rejected row itself; the client-side gate exists for the case the BE cannot see: a dependent pushed in a LATER batch than a create that returned `retry`. The FakeSyncServer must mirror the BE: in-batch ordering, `dependency_failed` for dependents of a rejected create, `product = NULL` + `product_missing` warning for a sale line whose product is unknown.
- **`image_hash` = sha256 of the UPLOADED bytes** (deviation 23, ruling T1-a): it is the original-upload hash, never the re-processed WebP. Local sha256 therefore equals the feed `image_hash`; the downloaded file is never compared against it.
- **Role offline:** the role/default shop come from local auth state already used by `StockService`; no live fetch.
- **Dev-device outbox:** destructive rebuild of the outbox column is fine (zero users; dev devices reinstall, as for v11/v12).

My calls on the rest (builder may refine, must keep the intent):
1. **Delete rules.** Category delete is refused locally while it has active products or active child categories (safe default; the server stays authoritative and its rejection is shown like any other). Product delete with pending dependents is allowed (sale lines keep their snapshot, accept-always). If a create is later rejected, its dependents are already failed by `failDependents`, and a queued `delete` for that id is dropped in the same transaction (moot). An unsent create plus dependents is NOT dropped locally; it is sent.
2. **Merge into existing: scope and availability.** The rewrite covers every local table that stores a product/category/vendor id: `products` (category_id), `categories` (parent_id), `stock`, `sale_items`, `inbound_transactions`/lines (product, vendor), `stock_batches`/expiry rows, `synced_assets`, `pending_uploads`, open outbox payloads and `depends_on`, plus any persisted cart/draft. The builder inventories them with a schema grep and a test that fails when a table with a matching column is not covered. Until the BE returns `conflict_entity_id` for category/vendor name collisions, those two only get *Edit and retry* / *Discard*; Merge is offered only when the id is present (UI keys off the field, not the entity).
3. **Initial stock / branch scope.** A product created offline has no stock row until a `stock.add` exists (a dependent of the create, via the dependency list). If the add-product form carries an initial quantity today, it becomes a dependent `stock.add`. Outbox scope is the user|tenant scope as everywhere; catalog rows are tenant-level, so `depends_on` checks inside that scope (documented limitation of Phase 0).
4. **Image state machine.** One `pending_uploads` row per entity: a second pick replaces the row (old file deleted); an edit while an upload is `waiting` just enqueues its normal update (the upload waits for the open rows, then runs); delete of the entity cancels its upload and removes the file; merge re-keys the upload to the surviving id (a merged create already has the server row, so the upload proceeds). The PUT response `version` is adopted as the row version.
5. **Cashier.** Both: the service refuses with `CatalogValidationException`, and the add/edit/delete entry points are hidden or disabled for cashiers (the builder lists the entry points in the plan).
6. **Reads and first install.** Catalog screens show the same first-setup gate/empty state as the rest of the app while bootstrap runs; they never call REST. All remaining callers of `saveProductsToCache` / `saveCategoriesToCache` / `saveVendors` (POS grid, stock screens, search) are inventoried in plan Task 1 and migrated or deleted in the same phase; no REST catalog writer may survive.
7. **Plan limits / duplicates.** A `limit_exceeded` rejection does not block further local creates (each is tried independently; the user sees each result). The local duplicate SKU/barcode pre-check includes inactive rows (the server's unique key does).
