# Phase 2 legacy reader audit (Task 1, read-only)

Date: 2026-11-16. No source file was changed. Sources read: `lib/core/offline/**`, every `OfflineLocalCache` consumer, `lib/core/sync/**` (appliers, engine, coordinator, state store), `lib/utilities/dependencies_provider.dart`, `lib/common/auth_bloc/auth_bloc.dart`, BE `apps/sync/feed.py`, `pull.py`, `apps/core/image_service.py`, `apps/products/image_services.py` (READ ONLY).

Line numbers are of the tree at the time of audit (DB v10, 74-issue analyzer baseline).

## 0. Findings that change the plan (read first)

1. **BLOCKER for Task 9 (sha256 verify):** BE `image_hash` is the sha256 of the **uploaded** bytes (`set_entity_image`, `digest = sha256_hex(data)`), but the stored `image`/`thumbnail` files are re-processed WebP (`process_and_upload_image` -> `_process_image` -> `original.webp`, `thumb.webp`). A downloaded file's sha256 will therefore NOT equal `image_hash` for any newly uploaded image, and a thumbnail can never match (it is a different, resized file). The feed carries no hash of the stored bytes and no `image_bytes`. As specified ("compute sha256, compare with expected_hash, mismatch -> discard") every download would be rejected and retried forever. Fix options (decide in Task 9, needs BE_GAPS entry): (a) BE adds `stored_hash`/`image_bytes`/`thumbnail_bytes` to `ser_product`/`ser_category`; (b) client treats `image_hash` only as a change token ("re-download when `image_hash` differs from the one we stored with the file"), verifying integrity by successful image decode + `Content-Length`. Until BE changes, (b) is the only implementable behavior. Record in `docs/BE_GAPS.md`.
2. **Business row must not be inserted into the legacy `businesses` table.** `auth_bloc.dart:235-250` reads `getBusinesses()` first and, when non-empty, sets `defaultBusiness` from it and returns WITHOUT the REST call. `BusinessData` needs keys the feed does not carry (`owner`, `logo`, `active_subscription`, `shop_count`, `counts`, `shops[]`, `created_at`). If the applier fills `businesses` from a bootstrap, the first login loses subscription data (`offline_preparation_listener.dart:216-250` expiry logic reads `activeSubscription`), `counts` (Home manage list), `shops` (POS shop pickers, `pos_screen.dart:154,164`). Decision: the business applier writes `synced_entities` and only MERGES scalar keys (name, slug, business_type, address, phone, email, tax_*, is_active, updated_at) into an ALREADY existing `businesses.json`; it never inserts (the REST path in `AuthBloc` / `BusinessBloc` stays the inserter until Phase 5).
3. **`shops.business_id` has no feed source.** `ser_shop` has no `business`/`business_id`. `SaleLocalStore.visibleShopSql` (`sale_local_store.dart:36`) filters `shops WHERE business_id = ? OR business_id IS NULL`; every dashboard / sales-history read depends on it. Applier must set `business_id` = tenant part of `SyncScope.current` (`userId|tenantId`, split on `|`, see `dependencies_provider.dart` SaleService wiring) or, equivalently, the id of the single `business` row of the same bootstrap. A NULL would make the shop visible to EVERY tenant on this device (sales are never wiped on logout). Never write NULL.
4. **Wipe vs cursor mismatch (Task 12 must fix):** `AuthBloc` calls `clearAllOnLogout()` on business change (`auth_bloc.dart:66,123`) and logout (`:183`), wiping catalog tables. `SyncCoordinator._clearSyncStateIfOutboxEmpty` (`sync_coordinator.dart:147,161-164`) clears the cursor only when that scope's outbox is empty. With unsynced rows the cursor survives while the tables are empty; signing back into that scope finds a cursor (no bootstrap) and an EMPTY catalog. The new `bootstrapped` flag and cursor of the wiped scope must be cleared in the same step as the table wipe (or wipe must become scope-aware). The logout gate (`auth_bloc.dart:170-180`) blocks on unsynced rows so only the business-switch path (`:66,123`) hits this, but it does.
5. **Existing `StockApplier` rows lack names the stock UI reads.** `StockLocalStore._write` (`stock_local_store.dart:~296-312`) writes json `{product, shop, quantity, is_out_of_stock, updated_at}` only. `StockData.fromJson` consumers read `product_name`, `product_sku`, `shop_name`, `is_low_stock` (`inventory_screen.dart:143`, `product_stock_panel.dart:27,178`, `inventory_bloc`, `premium_inventory_bloc.dart:42`). The feed (`ser_stock`) has only `id, product_id, shop_id, quantity, updated_at`. Pulled/bootstrapped stock rows will render blank names until the REST refresh overwrites them. Applier must derive from the local `products` (name, sku, min_stock_level) and `shops` (name) tables at write time (or Task 5 changes the reader to join). Same for `InboundApplier`: feed has ids only; legacy json wants `vendor_name`, `shop_name`, `created_by_name`.
6. **`StockLocalStore._writeProduct` is a no-op when the product row is missing** (`stock_local_store.dart:~331`: `if (rows.isEmpty) return;`). Entity order puts `product` before `stock` so bootstrap is fine, but a pulled stock change that precedes its product (cashier scope, product pulled later) leaves `products.stock_level = 0`. The product applier must compute `stock_level` as the sum of local `stock.quantity` for that product on every upsert (see section 3).
7. **`getCustomers()` has NO caller** in `lib/` (customer screens are REST-only today). `customers` is a legacy table with only a writer (`saveBootstrap`) and a dead reader; it still stays a typed table (Phases 4-5 readers), but no current screen regresses.
8. **Refund date column ambiguity:** the dashboard query (`local_dashboard_queries.dart:433-447`) filters `r.occurred_at`, but its own comment (`:411-412`) says the endpoint windows refunds on `created_at`. The feed has both. Store both columns; Task 5 must confirm which one the BE dashboard uses and align the single query (the dashboard test `local_dashboard_queries_test.dart` pins the contract `sale_refunds(id, sale_id, shop_id, total TEXT, occurred_at TEXT UTC ISO)`).
9. **REST-refreshing blocs still write the legacy tables** (`saveProductsToCache`, `saveCategoriesToCache`, `saveStockToCache`, `saveVendors`, `saveInboundTransactions`, `saveBusinessesToCache`). They overwrite applier output with REST shapes (no `version`, `image_hash`). Non-goal says they keep doing so; the appliers must therefore treat a row with NULL `version` as "older than any feed version" and never fail on it, and REST writers must not delete synced-only columns (see section 7 on `saveVendors`/`saveInboundTransactions` delete-all behavior).
10. **Kill switch:** with `SYNC_ENGINE=false` (`sync_flags.dart`, `main.dart:70-75`, `dependencies_provider.dart:599`) there is no engine. Once legacy bootstrap is retired a flag-off build has NO way to fill the catalog. Task 12 must either remove the flag's effect on bootstrap/first setup or document that flag-off = no first setup.

## 1. Legacy local schema (DB v10, `offline_db.dart`)

| Table | Columns (onCreate) | Notes |
|---|---|---|
| `businesses` | `id PK, json NOT NULL, updated_at` | only `getJsonList`, no typed columns (`:201-207`) |
| `shops` | `id PK, business_id, json, updated_at` | `business_id` used by `visibleShopSql` (`:209-216`) |
| `categories` | `id PK, tenant_id, parent_id, name, json, updated_at` | (`:218-227`) |
| `products` | `id PK, category_id, name, sku, barcode, price TEXT, stock_level REAL, thumbnail_url, image_url, json, updated_at`; idx category/name/barcode/(category,name)/sku/updated_at | (`:229-249`, `:162-190`) |
| `customers` | `id PK, name, phone, email, json, updated_at`; idx name, phone, (phone,name) | |
| `stock` | `id PK, product_id, shop_id, quantity REAL, base_quantity TEXT, json, updated_at, UNIQUE(product_id, shop_id)` | |
| `vendors` | `id PK, json, updated_at` | (`:127-134`, created in v3) |
| `inbound_transactions` | `id PK, shop_id, json, created_at`; idx shop, created | |
| `premium_summary` | `shop_id PK, json, updated_at` | REST-only summary, no feed entity |
| `offline_assets` | `id, type, url, hash, updated_at, local_path, downloaded_at, PK(id,type)`; idx url | |
| `sync_metadata` | `key PK, value, updated_at` | only legacy writers (bootstrap/asset-manifest version, last synced); no reader of the values exists (`getMetadata` has no caller) |
| `sale_refunds` | does not exist yet | dashboard probes `sqlite_master` and returns 0 |

Columns missing for the new design: no table has `version`; `products`/`categories` have no `image_hash`, `is_active`, `unit`, `expiry_alert_days`, `min_stock_level` columns (JSON only); `shops.business_id` has no feed source. DB v11 (Task 3) adds only what readers filter/sort on.

## 2. Readers, per entity (file:line, columns/JSON each reader needs)

Legend: `[col]` = typed column read in SQL, `{json}` = whole json decoded by the legacy DTO `fromJson`.

### business
| Reader | Needs |
|---|---|
| `auth_bloc.dart:235` `getBusinesses().first` -> `defaultBusiness` (also `xTenantID` save `:238`) | `{json}` -> `BusinessData.fromJson`: id, name, slug, business_type, owner{...}, logo, address, phone, email, tax_enabled, tax_name, tax_rate (string), tax_inclusive, active_subscription{id,name,max_*,features{pos,reports,customers,inventory,api_access,staff_management},is_free,price,currency,start_date,end_date,days_remaining,billing_cycle_days,billing_period}, is_active, shop_count, counts{shops_active,products_active,products_inactive,users_active,cashiers_active,managers_active}, shops[], created_at, updated_at |
| `business_bloc.dart:45` (cache first), `:100` `saveBusinessesToCache` (REST writer, also writes `shops` rows), `:104` re-read | same json |
| `offline_local_cache.dart:228` `getBusinesses`; `offline_db.dart:311` `hasBootstrapCache` counts rows | row count only |
| Writers besides REST: none (legacy `saveBootstrap` does NOT write `businesses`; `OfflineBootstrapDto.businesses` is parsed and dropped, `offline_local_cache.dart:38-202`) |

### shop
| Reader | Needs |
|---|---|
| `main_bottom_area.dart:146` `getShops()` (checkout shop fallback, `:143-160`) | `{json}` -> `ShopData`: id, business, name, address, phone, is_active, created_at, updated_at |
| `sale_local_store.dart:36` `visibleShopSql` (used by `local_dashboard_queries.dart` + `local_sales_history.dart`, and refunds `:436`) | `[id]`, `[business_id]` (`business_id = ? OR IS NULL`) |
| `local_dashboard_queries.dart:84` watches table `shops`; `offline_db.dart:361,383`, `offline_local_cache.dart:201,756,788` notify `{'shops'}` | table name only |
| `offline_local_cache.dart:425` `getStockFallbackFromProducts` uses `getShops().first` | id, name |
| `business_bloc` / `pos_screen.dart:154,164` use `defaultBusiness.shops` (inside business json, not the `shops` table) | `BusinessData.shops` |

### category
| Reader | Needs |
|---|---|
| `product_bloc.dart:71,136` `getCategories()` | `{json}` -> `CategoryData`: id, tenant, parent, name, description, image, thumbnail_url, is_active, sort_order, product_count, children[], created_at, updated_at; ordered by `[name] COLLATE NOCASE` |
| `category_bloc.dart:54` `getCategories()` ; UI: `category_row.dart:101` `productCount`, `category_form_screen.dart:205-207`, `category_detail_screen.dart:225` `productCount`; `category_bloc.dart:151,249` `children` | `product_count`, `children` |
| `product_bloc.dart:133,568` `saveCategoriesToCache` (REST writer) |

Legacy behavior to preserve: `getCategories()` returns EVERY row flat (children are saved as their own rows AND nested in the parent's json `children`, `offline_local_cache.dart:67-91`), so a child shows both nested and as a top-level row. After the REST refresh the bloc replaces the list with the REST tree.

### product
| Reader | Needs |
|---|---|
| `product_bloc.dart:70,135,176,254,274,360,380,465,534` `getProducts({categoryId, search})` | SQL `[category_id]`, `[name|sku|barcode] LIKE`, order `[name] NOCASE`; then `{json}` -> `ProductData`: id, category, category_name, name, description, sku, barcode, price, cost_price, image, unit, is_active, track_inventory, min_stock_level (num), stock_level (num), expiry_alert_days (num), created_at, thumbnail_url |
| `category_bloc.dart:266` `getProducts(categoryId:)` | same |
| `product_bloc.dart:470` inactive filter in Dart on `isActive == false` (cache holds inactive rows; BE bootstrap includes them, deviation 21) | `is_active` in json |
| `local_dashboard_queries.dart:281` `LEFT JOIN products p` | `[p.id]`, `[p.name]`, `[p.thumbnail_url]` |
| `stock_local_store.dart:~331-362` `_writeProduct` | `[products.id]`, json `stock_level`, `[stock_level]` |
| `product_row.dart:94`, `product_detail_screen.dart:181`, `product_form_screen.dart:559` | `categoryName` |
| `product_bloc.dart:871` `deleteProductFromCache` (deletes product + its stock) | |
| images: `product_row.dart:51`, `pos_product_list.dart:271`, `cart_line.dart:338`, `home_top_sellers.dart:135`, `product_form_widgets.dart:136` via `OfflineCachedImage` (section 6) | `thumbnail_url` / `image` strings |
| `pos_screen.dart:386` `product.isActive ?? true` | |

### customer
| Reader | Needs |
|---|---|
| `offline_local_cache.dart:281` `getCustomers` (NO caller) | `[name|phone|email] LIKE`, `{json}` -> `CustomerData`: id, tenant, name, phone, email, address, loyalty_points (int), notes, is_active, total_purchases, created_at, updated_at |

### vendor
| Reader | Needs |
|---|---|
| `vendors_bloc.dart:37` `getVendors()`; `premium_inventory_bloc.dart:40` | `{json}` -> `VendorData` (`id,name,phone,email,address,notes,is_active`; reads `d['data'] ?? json`) |
| REST writers `vendors_bloc.dart:69,112,155,196` `saveVendors` (delete ALL rows then insert) | |
| inbound display needs vendor name | derive from `vendors` |

### stock
| Reader | Needs |
|---|---|
| `inventory_bloc.dart:58` `getStock()`; fallback `:75` `getStockFallbackFromProducts`; `premium_inventory_bloc.dart:42` | `[shop_id]` filter; `{json}` -> `StockData`: id, product, product_name, product_sku, shop, shop_name, quantity (string), is_low_stock, is_out_of_stock, updated_at, expiry_date, is_expired, expires_in_days, expiry_status, batch_id, batch_number |
| `inventory_bloc.dart:366,370,518,544` `getStockQuantity` | `[product_id,shop_id]` -> `[quantity]` |
| `stock_local_store.dart` (all `currentUnits`/`_write`) | `[base_quantity]`, `[quantity]`, UNIQUE(product,shop) |
| `inventory_bloc.dart:134,198` `saveStockToCache` (REST writer) |
| `product_stock_panel.dart:27,178`, `inventory_screen.dart:143` | `product_name`, `shop_name` |

### expiry_batch
No legacy reader (`ExpiryReportBloc` is REST). `StockData.expiryDate/batchId/batchNumber` fields exist but `stock` json never receives them from sync.

### sale / refund / inbound
- `sale`: reader is `SaleLocalStore` + `local_sales_history.dart` + `local_dashboard_queries.dart` (own tables `sales`, `sale_items`, `sale_payments`; already filled by `SaleApplier`).
- `refund`: only `local_dashboard_queries.dart:75,85,427-447` (`sale_refunds r LEFT JOIN sales s`, columns `r.total` (TEXT, cents-parsed), `r.occurred_at`, `r.shop_id`, `r.sale_id`, `s.payment_method`).
- `inbound`: `inbound_bloc.dart:36,139` `getInboundTransactions(limit)`, `premium_inventory_bloc.dart:41`, `stock_service.dart:360` (writes local receipt row); `{json}` -> `InboundTransactionData` (id, reference, notes, shop, shop_name, vendor_id, vendor_name, total_quantity, created_by_name, item_count, items[{product,quantity,unit_cost,expiry_date,batch_number,...}], created_at); order `[created_at] DESC`; `[shop_id]`.

### user, subscription, notification, bankak_account
No reader of any local table. Team/notifications/bankak screens are REST-only (`bankak_screen.dart`, `notification_bloc`). `sale_history_item.dart`/`profile` carry bankak text only.

## 3. Mapping feed row (`ser_*`) -> legacy column / JSON key

"ignored" = feed key no reader needs; "derive" = legacy key the feed lacks and how the applier produces it. All JSON stored is the legacy DTO shape so the existing `fromJson` keeps working.

### business (`ser_business`)
| Feed key | Target | Note |
|---|---|---|
| id | `synced_entities.id`; merge target `businesses.id` | |
| version | `synced_entities.version` | versioned entity |
| name, slug, business_type, address, phone, email, tax_enabled, tax_name, tax_rate (string), tax_inclusive, is_active, updated_at | merged into existing `businesses.json` same keys | only when row exists |
| currency, timezone | `synced_entities` json only | no DTO field; dashboard timezone comes from elsewhere |
| NOT in feed: owner, logo, active_subscription, shop_count, counts, shops, created_at | preserved from existing json (merge); never invented | `active_subscription` could be derived from the `subscription` row later (id, name=plan.name, max_*, features, is_free, price, currency, start/end_date, days_remaining, billing_cycle_days=plan.duration_days) but is Phase 5 |

### shop (`ser_shop`)
| Feed key | Column / JSON key |
|---|---|
| id | `shops.id` |
| version | new column `version` |
| name, address, phone, is_active, updated_at | json same keys; `updated_at` column |
| is_main | ignored (no DTO field); keep in json harmlessly |
| derive `business` / column `business_id` | tenant of the scope (finding 3) |
| derive `created_at` | not in feed; leave null (DTO accepts null) |

### category (`ser_category`)
| Feed key | Column / JSON key |
|---|---|
| id | `categories.id` |
| version | new `version` |
| parent | column `parent_id` AND json `parent` |
| name | column `name` + json `name` |
| description, sort_order, is_active, updated_at | json same keys; `updated_at` column |
| image, thumbnail_url | json `image`, `thumbnail_url` (absolute URLs incl. `?v=<hash12>`) |
| image_hash | new column `image_hash` (not in legacy json; asset sync) |
| derive `tenant` / column `tenant_id` | tenant of scope (feed has no tenant) |
| derive `product_count` | `COUNT(*) FROM products WHERE category_id = id` (active only is what the REST list reports? not verified; match REST: count all non-deleted) recomputed when a product applies (Task 3) or computed at read time |
| derive `children` | not in feed; `CategoryData.children` is only consumed by `category_bloc` patch logic and the REST tree. Write `children: null` and keep rows flat (legacy flat reader already tolerates it); do not synthesize. Document: category tree shape returns after REST refresh |
| derive `created_at` | not in feed; null |

### product (`ser_product`)
| Feed key | Column / JSON key |
|---|---|
| id | `products.id` |
| version | new `version` |
| shop | ignored for legacy readers (product shop scope: null = shared); store in json `shop` for Phase 3 |
| category | column `category_id` + json `category` |
| name, sku, barcode, price (string), description, cost_price (string), unit, is_active, track_inventory, min_stock_level (int), expiry_alert_days (int|null) | same-named columns where they exist (`name`,`sku`,`barcode`,`price`) + json same keys. Keep price/cost_price as strings |
| image | column `image_url` + json `image` |
| thumbnail_url | column `thumbnail_url` + json `thumbnail_url` |
| image_hash | new column `image_hash` |
| updated_at | column `updated_at` (legacy bootstrap wrote `created_at` here; indexed `idx_products_updated_at` unused by readers) |
| derive `category_name` | NOT in feed; `product_row.dart:94`, `product_detail_screen.dart:181`, `product_form_screen.dart:559` read it. Applier: `SELECT name FROM categories WHERE id = category_id` at write time; category rename must also refresh affected products' json (Task 3: after a category upsert, `UPDATE products SET json=... WHERE category_id=?`) or reader joins |
| derive `stock_level` (json + column `stock_level`) | NOT in feed. Applier: `SUM(stock.quantity) WHERE product_id = id` (exact via `Decimal3`, same as `StockLocalStore._writeProduct`) on every product upsert; stock applier already refreshes it on stock changes |
| derive `created_at` | not in feed; null |

### customer (`ser_customer`)
| Feed key | Column / JSON key |
|---|---|
| id | `customers.id`; version -> new `version` |
| name, phone, email | columns + json |
| address, notes, loyalty_points (int), is_active, updated_at | json same keys; `updated_at` column |
| derive `tenant` | scope tenant (json only) |
| derive `total_purchases` | NOT in feed; leave null (the customer screens are REST) |
| derive `created_at` | null |

### vendor (`ser_vendor`)
| Feed key | Column / JSON key |
|---|---|
| id | `vendors.id`; version -> new `version` |
| name, phone, email, address, notes, is_active | json keys identical to `VendorData.toJson` (`is_active` required: `d['is_active'] == true`) |
| updated_at | column `updated_at` |

### stock (`ser_stock`) (existing `StockApplier`)
| Feed key | Column / JSON key |
|---|---|
| id | `stock.id` (change.id; applier uses `change.id`) |
| product_id, shop_id | `product_id`, `shop_id`; json `product`, `shop` |
| quantity (string) | `base_quantity`; `quantity` = base + pending deltas |
| updated_at | ignored by `StockLocalStore._write` (it stamps `now`) |
| derive `product_name`, `product_sku` | products table (finding 5) |
| derive `shop_name` | shops table |
| derive `is_low_stock` | `quantity > 0 && quantity <= products.min_stock_level` (legacy `getStockFallbackFromProducts:443` uses the same rule) |

### expiry_batch (`ser_expiry_batch`): no reader -> `synced_entities` (id, product, shop, quantity, expiry_date, batch_number, updated_at).

### sale (`ser_sale`) (existing `SaleApplier`): fully mapped by `_fromFeed` (`sale_applier.dart:145-219`); ignored feed keys: `client_sale_id`, `bankak_account_snapshot`, `notes`, `occurred_at_suspect` (used only to pick the date), `created_at` (date fallback), `updated_at`, `refunded_amount`, item `returned_quantity`. `refunded_amount` and `returned_quantity` have no local column (sales history shows REST values); flag for Phase 4.

### refund (`ser_refund`) -> new table `sale_refunds`
| Feed key | Column |
|---|---|
| id | `id PK` |
| sale | `sale_id` |
| shop | `shop_id` |
| total (string) | `total TEXT` (dashboard `_cents('r.total')`) |
| occurred_at | `occurred_at TEXT` UTC ISO (dashboard filter; finding 8) |
| created_at | `created_at TEXT` (add; BE windows by it) |
| method, notes, reference, refunded_by | columns/json for Phase 4 |
| items[{sale_item, quantity, amount}] | json (`items_json`); no reader yet |

### inbound (`ser_inbound`) (existing `InboundApplier`)
Maps to `inbound_transactions(id, shop_id, json, created_at)`; json built by `_fromFeed` (`inbound_applier.dart:107-140`): reference, notes, shop, vendor_id (from `vendor`), total_quantity (summed with `Decimal3`), item_count, items, created_at. Ignored: `created_by` (id only). Derive `vendor_name` from `vendors`, `shop_name` from `shops`, `created_by_name` from `user` row (finding 5).

### user, subscription, notification, bankak_account -> `synced_entities` (no legacy reader). Keys stored verbatim; `user.version` used for older/equal guard.

## 4. Entities with no legacy reader -> generic `synced_entities`

`synced_entities(entity TEXT, id TEXT, version INTEGER, data TEXT json, updated_at TEXT, PK(entity,id))`, scope-wiped with the catalog:

- `expiry_batch`, `user`, `subscription`, `notification`, `bankak_account` (no reader at all).
- `business` (scalar keys only; legacy `businesses` row is merge-only, finding 2).
- `refund` ALSO goes to `sale_refunds` (it has a reader, the dashboard; `synced_entities` not needed).
- `customer`: legacy `customers` table (dead reader today, kept for Phases 4-5; no `synced_entities` copy).

All appliers write inside the page `txn` only. `delete` of a `synced_entities` row = row delete.

## 5. Wrapper-only fields existing appliers read from `PullChange` (bootstrap items have none)

A bootstrap item is the feed row's `data` (no `seq`, `origin_device_id`, `shop_id`, `op`). The synthetic change uses `seq=0`, `op='upsert'`, `originDeviceId=null`, `id` and `version` from the item.

| Applier | Wrapper fields used | Fallback / risk |
|---|---|---|
| `StockApplier.apply` (`stock_applier.dart:36-58`) | `change.op` (delete branch), `change.id` (the StockLevel id passed to `upsertServerBase`/`deleteByServerId`), `change.shopId` only as 3rd fallback after `d['shop_id']`/`d['shop']` | OK: item has `id`, `product_id`, `shop_id`, `quantity`. `version` unused (null). `localVersion` null |
| `SaleApplier.apply` (`sale_applier.dart:54-76`, `_fromFeed:145`) | `change.op`, `change.id` (sale id), `change.version` (stored as `Sale.version`; BE sales are unversioned so feed `version` is 0/absent -> null/0, handled), `c.shopId` only as fallback after `d['shop']` | OK. Item carries no `version`: bootstrap `Sale.version` becomes null, a later pull with a version applies normally. Nested `items[].id` required (`_line`) |
| `InboundApplier.apply` (`inbound_applier.dart:43-65`, `_fromFeed:107`) | `change.op`, `change.id`, `c.shopId` fallback after `d['shop']` | OK (`ser_inbound` has `shop`) |
| Engine pipeline (not appliers) | `origin_device_id` own-echo filter, `seq`, `skipWhenLocalPending` deferred rule, `deferred_pull` | Bootstrapper must call the same pending-outbox check itself (design section 2 item 7) because it bypasses `_applyPage`; `skipWhenLocalPending` is on `ChangeApplier` (`change_applier.dart:42`) and `localVersion` (`:47`) |

Required item-shape contract test per entity: copy one real `ser_*` row (section 3) through the applier.

## 6. Image readers and `offline_assets`

- `OfflineCachedImage.build` (`offline_cached_image.dart:75-107`): `getIt<OfflineLocalCache>().getLocalAssetPathByUrl(_stripQuery(url))` -> `offline_assets WHERE url = ?` -> file exists -> `Image.file`, else `Image.network`. It keys by URL with the query stripped; the feed URLs contain `?v=<hash12>`, so Task 10 should keep the lookup keyed by the stripped URL (or by `(type,id,variant)` resolved via product id) and must not match by full URL.
- Callers: `product_row.dart:51`, `pos_product_list.dart:271`, `cart_line.dart:338`, `home_top_sellers.dart:135`, `product_form_widgets.dart:136`; plus `local_dashboard_queries.dart:281` selects `p.thumbnail_url` for top sellers.
- Writers: `saveAssetManifest*` (`offline_local_cache.dart:204,449`), `markAssetDownloaded:524`, `saveProductsToCache:618-633` (nulls `local_path` when thumbnail URL changed), `clearAllOnLogout:779` (+ file delete `_deleteOfflineAssetsDirectory:896`), `OfflineDb.clearBootstrapCache/clearAllLocalOfflineData`.
- Legacy file name is `${type}_${id}_${hash ?? url.hashCode}${ext}` (`offline_asset_downloader.dart:108`) in `<appSupport>/offline_assets`.

## 7. Where the hooks are (e)

- **OfflinePreparationListener** (`offline_preparation_listener.dart`): mounted by `MainScreen` (`main_screen.dart:38`). `_syncSession` (`:56-72`, on `AuthBloc.sessionId` change) resets 12 blocs. Blocking overlay logic is `_handleOfflineStateChange` (`:165-212`): shows `PreparingOfflineScreen.show(context)` only when `bootstrapStatus == loading` and no cache; closes when `bootstrapStatus == success || hasCache || canUseAppOffline`. Listener 91-97 listens to `OfflineStatusBloc` (`bootstrapStatus`, `hasCache`, `canUseAppOffline`); listener 108-121 loads business/unread count when `connectionStatus` becomes online. Task 11 swaps the source of these three signals to sync state (`bootstrapped` flag + bootstrap progress) but keeps this slot.
- **OfflineStatusBloc._onStarted** (`offline_status_bloc.dart:38-85`): `hasCache = localCache.hasBootstrapCache()` (counts businesses/products/categories, `offline_db.dart:310`); offline + no cache -> failure with hardcoded English message `:70`; online + no cache -> `_refreshAll` (`:127-195`) = `offlineFirstManager.refreshBootstrap()` + `refreshAssetManifest()` + `_syncSales`; has cache + online -> `_backgroundRefresh` (-> `OnOfflineStatusRefreshRequested` again). `_onConnectionChanged:101-118` re-runs `_backgroundRefresh` + `_backgroundSyncSales` on reconnect. Triggered by `AuthBloc` `OnOfflineStatusStarted` at `auth_bloc.dart:249,290,320,333,343` (every end of `_onLoadBusinessEvent`) and reset by `OnOfflineStatusResetRequested` at `:203` (logout). The login init hook in practice IS `_onLoadBusinessEvent` -> `OnOfflineStatusStarted`; there is no separate `initializeAfterLogin` caller (see section 8).
- **Login hook for sync**: `SyncCoordinator._apply` (`sync_coordinator.dart:139-154`) on a ready `SyncSession` (profile id + `defaultBusiness.id`, `dependencies_provider.dart:~625 _syncSessionOf`) sets `SyncScope.current`, `_triggers.start()` and device registration. Bootstrap start belongs here (or in `SyncTriggers` on `SyncOutcome.needsBootstrap`, `sync_triggers.dart:321-324` currently schedules nothing; `background_sync.dart:174` reports success). Foreground only.
- **Logout hook**: `AuthBloc` logout `auth_bloc.dart:170-210`: gate on unsynced count `:170-180`, `clearAllOnLogout():183`, token wipe, vault clear, `OfflineStatusResetRequested:203`. Coordinator clears the scope cursor later, async and only if outbox empty (`sync_coordinator.dart:144-149,161-168`). Business-switch wipe: `auth_bloc.dart:66,123`.
- **Circularity to preserve:** the sync scope exists only after `defaultBusiness` is known (`AuthBloc` via REST/`businesses` cache). So first-setup bootstrap always starts after the business REST call; keep `businesses` inserter = REST (finding 2).

## 8. Everything Task 12 must remove, and what still depends on it (f)

| Item | Location | Who still calls it (must be rewired before deletion) |
|---|---|---|
| `OfflineFirstManager` class + enums `OfflineFirstStatus/Result` | `offline_first_manager.dart:1-179` | only `OfflineStatusBloc` (ctor `:27`, `_refreshAll:155,168`) and DI. `initializeAfterLogin:59` has NO caller (dead). `dispose:176` no caller |
| DI: `OfflineFirstManager` | `dependencies_provider.dart:178-185`; used `:385` | OfflineStatusBloc DI |
| DI: `OfflineAssetDownloader` | `dependencies_provider.dart:158-163`; used `:183` | OfflineFirstManager only |
| DI: `OfflineRemoteDataSource` | `dependencies_provider.dart:165-167`; used `:182` | OfflineFirstManager only |
| `OfflineAssetDownloader` + `OfflineAssetDownloadProgress` | `offline_asset_downloader.dart` (160 lines) | OfflineFirstManager only; test none |
| `OfflineRemoteDataSource.getBootstrap` (`/api/v1/offline/bootstrap/`), `getAssetManifest` (`/api/v1/offline/assets/manifest/`) | `offline_remote_data_source.dart:10-33` | OfflineFirstManager only |
| `OfflineBootstrapDto`, `OfflineAssetManifestDto`, `OfflineAssetRecord` | `offline/models/*` | cache + downloader + manager |
| `OfflineLocalCache.saveBootstrap` | `offline_local_cache.dart:38-202` | manager only |
| `saveAssetManifest`, `saveAssetManifestPreservingDownloads`, `getAssetsMissingLocalFiles`, `getAllAssets`, `markAssetDownloaded` | `:204,449,501,516,524` | manager/downloader; `getAllAssets` no caller |
| `hasBootstrapCache` (cache `:36`, db `:310`) | | `OfflineStatusBloc._onStarted:42`, manager `:60` |
| `getLocalAssetPathByUrl` (KEEP until Task 10 replaces it) | `:542` | `OfflineCachedImage:77` |
| `saveProductsToCache` thumbnail-asset invalidation | `:610-634` | REST product writers; touches `offline_assets` which Task 9 reshapes (v12) |
| `OfflineDb.clearBootstrapCache` | `offline_db.dart:349` | only `local_dashboard_queries_test.dart:620`; `clearAllLocalOfflineData:367` used by 3 tests (`offline_db_v10_test`, `logout_gate_test`, `local_sales_wipe_test`) |
| `sync_metadata` table + `setMetadata/getMetadata/getJsonList` | `offline_db.dart:318-347` | `getJsonList` is used by `getBusinesses/getShops/getVendors` (KEEP); `setMetadata/getMetadata` have no caller; `sync_metadata` written only by saveBootstrap/saveAssetManifest |
| Network-reconnect triggers: `OfflineFirstManager._startNetworkWatcherOnce:162-174` and `OfflineStatusBloc._onConnectionChanged:101-118` / `_backgroundRefresh:243-259` (which dispatches `OnOfflineStatusRefreshRequested` -> `_refreshAll`) | | replaced by `SyncTriggers` (`sync_triggers.dart:113`, connectivity) |
| `OnOfflineStatusRefreshRequested` | `footer_status.dart:56` (refresh button), `offline_status_bloc.dart:31,87,255` | footer button must call the new bootstrap/sync trigger |
| `OfflineStatusBloc` fields `offlineFirstManager`, `localCache`; state fields `bootstrapStatus`, `assetStatus`, `lastBootstrapSyncAt`, `lastAssetSyncAt`, `hasCache`, `canUseAppOffline` | `offline_status_state.dart` | read by `offline_preparation_listener.dart:91-97,165-212`, `preparing_offline_screen.dart:83,145`, `preparation_steps.dart:12`, `footer_status.dart:13`, `sync_pill.dart:13,104`, `pos_app_bar.dart:45`, `settings_screen.dart:202` |
| `OfflineStatusBloc` DI args | `dependencies_provider.dart:381-388` | |
| Tests touching legacy API | `test/common/auth_bloc/auth_bloc_wipe_test.dart`, `test/core/offline/logout_gate_test.dart`, `test/features/dashboard/local_dashboard_queries_test.dart` (use `OfflineStatusBloc`/`clearBootstrapCache`/`clearAllLocalOfflineData`); no test imports `OfflineFirstManager`/downloader/`saveBootstrap` |

Keep (not legacy writers of server data, still needed): `getProducts/getCategories/getStock/getVendors/getBusinesses/getShops/getInboundTransactions/getStockQuantity`, `saveBusinessesToCache`, REST-refresh savers (Phase 3-5 retire them), `clearAllOnLogout` (rewire per finding 4), `getStockFallbackFromProducts`, `premium_summary` get/save (no feed entity).

Break-risks when removing:
- `AuthBloc.offlineLocalCache.clearAllOnLogout()` must also clear the scope's `bootstrapped`/cursor (finding 4) and now also `synced_entities`, `sale_refunds`, new asset table, and the image directory.
- `hasBootstrapCache` replacement must be scope-aware (`SyncStateStore.forScope(scope).bootstrapped`); a business-wide row count is wrong for a second user on the device.
- `OfflineDb.clearAllLocalOfflineData` deletes `sync_metadata` but must keep `outbox`/`sync_state` (3 tests pin this).
- Flag-off build (finding 10).
- Image fallback: `OfflineCachedImage` falls back to `Image.network` when no local file, so removing the downloader degrades gracefully, never blocks.

## 9. Per-task consumption checklist

- Task 3 (DB v11 + catalog appliers): add `version` to `shops, categories, products, customers, vendors`; `image_hash` to `products, categories`; `synced_entities`; applier derivations in section 3 (`business_id`, `tenant_id`, `category_name`, `stock_level`, `product_count`); business = merge-only.
- Task 4: customers -> `customers`; vendors -> `vendors` (and stop `saveVendors` delete-all from erasing synced rows, or accept REST authoritative); user/subscription/notification/bankak/expiry_batch -> `synced_entities`.
- Task 5: `sale_refunds(id, sale_id, shop_id, total, occurred_at, created_at, method, ...)`; derive names for stock/inbound json (findings 5, 6).
- Task 9/10: finding 1 (hash semantics) before any code; `OfflineCachedImage` URL-without-query lookup.
- Task 11/12: sections 7 and 8.
