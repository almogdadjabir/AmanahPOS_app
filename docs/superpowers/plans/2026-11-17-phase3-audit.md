# Phase 3 audit (catalog writes) - 2026-11-17

Report only. Source of truth for Tasks 3, 4, 7, 8. All paths relative to the repo root. DB version at audit time: 13 (`OfflineDb._dbVersion`); Phase 3 bumps to 14.

## (a) REST catalog writers and their callers

### Cache writers (must not survive Phase 3)

Defined in `lib/core/offline/data/offline_local_cache.dart`:

| Method | Def | Writes | Callers |
|---|---|---|---|
| `saveCategoriesToCache(List<CategoryData>)` | L142 | `categories` (id, tenant_id, parent_id, name, json, updated_at) | `ProductBloc._init` L133 (REST bootstrap list); `ProductBloc._createCategory` L568 (after REST add) |
| `saveProductsToCache(List<ProductData>)` | L290 | `products` (+ `stock` rows via `_stockStore.recompute` for `stock.product`) | `ProductBloc._init` L132; `_onCategorySelected` L252/L272; `_loadMore` L358/L378; `_loadAll` L531 |
| `saveVendors(List<VendorData>)` | L506 | `vendors` (id, json, updated_at), upsert only | `VendorsBloc._onStarted` L69 (REST list), `_onCreate` L112, `_onUpdate` L155 |
| `removeVendorFromCache(id)` | L533 | delete from `vendors` | `VendorsBloc._onDelete` L196 |
| `deleteProductFromCache(productId)` | L638 | delete `products` row and every `stock` row of the product | `ProductBloc._deleteProduct` L871 |

Tests that pin these (to delete/replace): `test/core/offline/save_vendors_test.dart` (saveVendors, removeVendorFromCache). No other lib/test callers.

### REST calls of the three entities (repository -> use case -> owner)

Products (`lib/features/products/data/repository_impl/product_repo_impl.dart`, use case `lib/features/products/domain/usecases/product_usecase.dart`):

| Call | Endpoint | Owner |
|---|---|---|
| `addProduct` (JSON or multipart `image_upload`) | POST `api/v1/products/` | `ProductBloc._addProduct` L599, `_addProductWithAutoCategory` L695 |
| `editProduct` (JSON or multipart) | PATCH `api/v1/products/{id}/` | `ProductBloc._updateProduct` L807 |
| `deactivateProduct` | DELETE `api/v1/products/{id}/` | `ProductBloc._deleteProduct` L858 |
| `getProducts` / `getProductsByCategory` / `getCategories` (reads, REST paging) | GET `api/v1/products/`, `.../categories/{id}/products/`, `.../categories/` | `ProductBloc` (L98-99, 211-212, 331-332, 429, 508-509) |
| `getCategoryProducts` (read) | GET `api/v1/products/categories/{id}/products/` | `CategoryBloc` L296, L375 |

Categories (`lib/features/category/data/repository_impl/category_repo_impl.dart`, use case `lib/features/category/domain/usecases/category_usecase.dart`):

| Call | Endpoint | Owner |
|---|---|---|
| `addCategory` | POST `api/v1/products/categories/` | `CategoryBloc._addCategory` L134; `ProductBloc._createCategory` L557 (category picker sheet); `ProductBloc._addProductWithAutoCategory` L661 (auto "General") |
| `editCategory` | PATCH `api/v1/products/categories/{id}/` | `CategoryBloc._editCategory` L198 |
| `deleteCategory` | DELETE `api/v1/products/categories/{id}/` | `CategoryBloc._deleteCategory` L421 |
| `getCategories` (read) | GET `api/v1/products/categories/` | `CategoryBloc._init` L73 |

Vendors (`lib/features/inventory/data/repository_impl/inventory_repo_impl.dart` L232-282, use case in `inventory/domain`):

| Call | Endpoint | Owner |
|---|---|---|
| `createVendor` | POST `api/v1/inventory/vendors/` | `VendorsBloc._onCreate` L96 |
| `updateVendor` | PATCH `api/v1/inventory/vendors/{id}/` | `VendorsBloc._onUpdate` L137 |
| `deleteVendor` | DELETE `api/v1/inventory/vendors/{id}/` | `VendorsBloc._onDelete` L180 |
| `getVendors` / `getVendorById` (reads) | GET `api/v1/inventory/vendors/...` | `VendorsBloc._onStarted` L49; (`getVendorById` no caller in lib) |

Not catalog writers but adjacent: `inventory_repo_impl.dart` `_restAdd` (POST `api/v1/inventory/stock/add/`) is only the dated-expiry stock add (`_addWithExpiryOnline`), unrelated to catalog writes and stays.

Local readers that already exist and Phase 3 keeps: `OfflineLocalCache.getProducts/getCategories/getVendors` (used by `ProductBloc` L70-71/135-136/176/254/274/360/380/465/534, `CategoryBloc` L54/266, `VendorsBloc` L37, `PremiumInventoryBloc` L40).

## (b) Tables / columns holding product, category or vendor ids

Legend for "how written": SYNC = pull/bootstrap applier; LOCAL = local write path (`LocalWriter`/store); REST = legacy REST cache writer (removed in Phase 3); OUTBOX = payload built when enqueuing.

### Real columns

| Table | Column | Holds | Written by |
|---|---|---|---|
| `products` | `id` (PK) | product id | SYNC `ProductApplier` (`product_applier.dart`); REST `saveProductsToCache` |
| `products` | `category_id` | category id | SYNC `ProductApplier` L65 (`'category_id': category`); REST `saveProductsToCache` L325; indexes `idx_products_category`, `idx_products_category_name` |
| `categories` | `id` (PK) | category id | SYNC `CategoryApplier`; REST `saveCategoriesToCache` |
| `categories` | `parent_id` | category id (parent) | SYNC `CategoryApplier` L88; REST L155 |
| `stock` | `product_id` (NOT NULL) | product id | SYNC `StockApplier` (`upsertServerBase`, L57); LOCAL `StockLocalStore.recompute` (via `StockService`, `SaleService`, receiveInbound); REST `saveProductsToCache` L371. `UNIQUE(product_id, shop_id)`; indexes `idx_stock_product`, `idx_stock_product_shop`. `stock.id` may be `'$productId-$shopId'` (L370) |
| `vendors` | `id` (PK) | vendor id | SYNC `VendorApplier`; REST `saveVendors` |
| `sale_items` | `product_id` (nullable; NULL for custom lines) | product id | LOCAL `SaleLocalStore._insertChildren` L301 (from `SaleService.create`); SYNC `SaleApplier` (L208 maps `it['product']`) |
| `synced_assets` | `id` (part of PK `type,id,variant`; `type` in product/category) | product / category id | SYNC `registerRowAssets`/`registerAsset` (applier_support); `AssetSync` reads/updates |
| `outbox` | `entity_id` (`entity` = product/category/vendor) | the entity's own id (create/edit/delete rows) | LOCAL `OutboxStore.enqueue` (via `LocalWriter`); index `idx_outbox_entity(entity, entity_id)`, `idx_outbox_entity_seq` |
| `outbox` | `depends_on_entity_id` | product/category/vendor id this row waits on (mechanism exists in `OutboxStore`; no stock/sale/inbound writer sets it today, Phase 3 uses it for sale/stock/inbound -> product and product -> category) | LOCAL `OutboxStore.enqueue(dependsOnEntityId:)`; `OutboxStore` L242/L277 unblock/fail dependents |

### JSON blobs and payload keys (no column; must be rewritten by Task 8 too)

| Table | Column | JSON path | Holds | Written by |
|---|---|---|---|---|
| `products` | `json` | `id`, `category`, `category_name` (name only) | product id, category id | SYNC `ProductApplier` L58-74; REST `saveProductsToCache` |
| `categories` | `json` | `id`, `parent`, (`children[].id` is null-ed by SYNC; REST may carry nested children) | category id, parent id | SYNC `CategoryApplier` L82-90; REST |
| `stock` | `json` | `product_id` (+ `product`) | product id | SYNC `StockApplier`; LOCAL `StockLocalStore.recompute`; REST L206/370 |
| `vendors` | `json` | `id` | vendor id | SYNC `VendorApplier`; REST `saveVendors` |
| `inbound_transactions` | `json` | `vendor_id` (`InboundTransactionData.vendorId`), `items[].product` | vendor id, product ids | LOCAL `StockService.receiveInbound` L359-369; SYNC `InboundApplier` (`_fromFeed`: `d['vendor']`, `items[].product`) |
| `sale_items` | `snapshot_json` | `id`, `category` (+ name/sku/...) | product id, category id | LOCAL `PosRepoImpl` L101-112 snapshot -> `SaleLocalStore._insertChildren` L310 (`keepSnapshots` preserves it across a sale re-apply) |
| `synced_entities` | `json` (`entity,id` key) | `expiry_batch.product`; others per entity | product id | SYNC `ExpiryBatchApplier` (validates `d['product']`) |
| `outbox` | `payload_json` | `stock.*`: `product_id`; `inbound.create`: `vendor_id`, `items[].product_id` (+ `client_inbound_id` = entity id); `sale.create`: `items[].product_id` (non-custom); product create/edit: `category`; category create/edit: `parent` | product / vendor / category ids | LOCAL `StockService._enqueue` L182 (`product_id`), `receiveInbound` L333, `SaleService._payload` (sale_local_store.dart L289-322 area / sale_service.dart L147), future Task 3/4 writers |
| `dashboard_summary_cache` | `json` | top-products `product_id` | product id (derived cache) | LOCAL `DashboardLocalDataSource`; transient, safe to clear on merge |

Read-side consumers that depend on those columns (useful to keep consistent): `StockLocalStore.pendingDeltaUnits/saleCreateDelta/...` (matches `payload_json` LIKE `%productId%` and `payload['product_id']`, `items[].product_id`), `LocalDashboardQueries` (L274-283: `sale_items.product_id` LEFT JOIN `products`), `LocalSalesHistory` L188, `refreshProductsCategoryName`/`refreshCategoryProductCount` (applier_support L92/108-117).

### Table list for Task 8's "merge rewrites every id" test

A merge of local product P -> server product S, local category C -> S_C, local vendor V -> S_V must leave no row naming the dropped id in any of the following (table.column / json path):

Product id: `products.id`, `products.json$.id`, `stock.product_id`, `stock.id` (when `'$productId-$shopId'`), `stock.json$.product_id`, `sale_items.product_id`, `sale_items.snapshot_json$.id`, `inbound_transactions.json$.items[].product`, `synced_assets.id` (type=product), `synced_entities.json$.product` (entity expiry_batch), `outbox.entity_id` (entity=product), `outbox.depends_on_entity_id`, `outbox.payload_json$.product_id` (stock), `outbox.payload_json$.items[].product_id` (sale.create, inbound.create).

Category id: `categories.id`, `categories.json$.id`, `categories.parent_id`, `categories.json$.parent`, `products.category_id`, `products.json$.category`, `sale_items.snapshot_json$.category`, `synced_assets.id` (type=category), `outbox.entity_id` (entity=category), `outbox.depends_on_entity_id`, `outbox.payload_json$.category` (product create/edit), `outbox.payload_json$.parent` (category create/edit).

Vendor id: `vendors.id`, `vendors.json$.id`, `inbound_transactions.json$.vendor_id`, `outbox.entity_id` (entity=vendor), `outbox.depends_on_entity_id`, `outbox.payload_json$.vendor_id` (inbound.create).

Tables with NO product/category/vendor id (verified): `sales`, `sale_payments`, `sale_refunds` (sale/shop ids only), `customers`, `businesses`, `shops`, `premium_summary` (shop_id; json is aggregate), `sync_state`. `premium_summary.json` aggregates may embed vendor/product ids inside summaries: derived cache, refresh not rewrite.

Task 8's schema-grep test should enumerate columns via `PRAGMA table_info` for every table and fail on any `*product*`/`*category*`/`*vendor*`/`parent*` column not in the lists above, so a new id column cannot be added silently.

### Deliberately NOT rewritten by a merge

- `sale_refunds.json`: the raw feed payload, which may embed `items[].product`. Written only by the sync `RefundApplier`, so it holds server ids only; a local (unsynced) id can never appear in it.
- `sales.warnings_json`: server-produced warning text/codes for a sale, not a reference used for lookups. It is display history, so it keeps the original ids.

Task 8's schema-grep test must whitelist both so they do not trip it.

## (c) Entry points for add / edit / delete

### Products

| Action | UI | Event | Notes |
|---|---|---|---|
| Add | Products screen FAB / empty-state action: `product_screen.dart` L267, L343 -> `openProductForm(context)` (`product_form_screen.dart` L35); category detail "add product": `category_detail_screen.dart` L117 -> `openProductForm(context, initialCategory:)` | `OnAddProduct` (category chosen) / `OnAddProductWithAutoCategory` (none chosen -> creates "General" via REST first) | submit at `_submit` L296-396 |
| Edit | Product detail "edit": `product_detail_screen.dart` L146 -> `openProductForm(context, product:)`; swipe/row action in product list | `OnUpdateProduct` (L325) | edit dto carries NO `sku` (immutable) and the category from the existing product |
| Delete | Form `_delete` (`product_form_screen.dart` L396-410, confirm sheet) and list row action `product_screen.dart` L239 -> `confirmDeleteProduct` (`widgets/product_delete.dart` L12 -> L45) | `OnDeleteProduct` | REST soft-delete (`deactivateProduct`) then `deleteProductFromCache` |

All three live in `ProductBloc` (`lib/features/products/presentation/bloc/product_bloc.dart`).

### Categories

| Action | UI | Event |
|---|---|---|
| Add | Category screen: empty-state action `category_screen.dart` L147 and add tile L209 -> `openCategoryForm(context)` (`category_form_screen.dart` L19); product-form category picker "new" -> `category_picker_sheet.dart` L72; auto "General" on product add without a category | `OnAddCategory` (L159 of form), `OnCreateProductCategory` (picker), auto path inside `_addProductWithAutoCategory` |
| Edit | `category_row.dart` L66, `category_detail_screen.dart` L123 -> `openCategoryForm(context, category:)` | `OnEditCategory` (form L145; name + description) |
| Delete | `category_row.dart` L72, `category_detail_screen.dart` L125, form L190 -> `confirmDeleteCategory` (`category_form_screen.dart` L47) | `OnDeleteCategory` |

Active toggle: `OnToggleCategoryActive` exists but `CategoryBloc._toggleActive` is a no-op ("MVP: category active toggle disabled"); no UI dispatches it. Out of scope.

### Vendors

All in `lib/features/inventory/presentation/premium/sheets/vendors_sheet.dart` (opened from `inventory_screen.dart` L690 `showVendorsSheet`): add -> `_VendorFormSheet()` (`OnVendorCreate`, L284), edit -> `_VendorFormSheet(existing:)` (`OnVendorUpdate`, L200 toggle-active path and L272 form), delete -> `OnVendorDelete` (events handled in `VendorsBloc`, `inventory/presentation/bloc/vendors_bloc.dart`).

### Does the add-product form carry an initial stock quantity?

Yes. `_ProductFormScreenState` has `_startStockCtrl` (L87, field at L649) and a shop picker (`_shop`, default `_shops.first`, L101/120/241). In `_submit` L362-369: `hasOpening = tracking && startRaw non-empty && double.tryParse > 0 && _shop != null`; then `openingStock = startRaw` and `openingShopId = _shop.id` are passed on `OnAddProduct` / `OnAddProductWithAutoCategory`. `ProductBloc._recordOpeningStock` (L749-793) runs AFTER the REST create succeeds: `inventoryUseCase.addStock(AddStockRequestDto(productId, shopId, quantity, movementType: MovementType.opening))`. That goes through `InventoryRepoImpl.addStock` -> `StockService.add` (OUTBOX `stock.add`, `reason` = request.reference = null -> `''`; the `MovementType.opening` is NOT carried in the payload), because no expiry date is set. A stock failure is a non-fatal `submitWarning`, and the list card is patched with `stockLevel: qty`.

Consequences for Task 4: the product create must enqueue first (entity `product`, depends: category), then `stock.add` with `depends_on_entity_id` = the new product id (Review Focus 1), in the same transaction when both are local. The result for the list card must read quantity from local `stock`, not `copyWith(stockLevel:)`. Cashiers cannot reach the form's cost field (`_isCashier`), but the BE refuses catalog writes for cashiers anyway (Global Constraint 9).

## Notes / hazards for later tasks

- `ProductBloc` couples the three REST paths (products, categories, opening stock). The auto-"General" category add (L661) is a second entity create inside one user action: Task 4 must enqueue category create + product create (depends on category) + stock.add (depends on product) in ONE `LocalWriter.write`.
- `ProductBloc._init`/`_loadAll` use the REST list as a refresh and write it through `saveProductsToCache`: this is the path that today could overwrite an unsynced local edit (Review Focus 4). After Phase 3 the list must be read only from local tables.
- `deleteProductFromCache` deletes `stock` rows only; it leaves `sale_items.product_id`/`snapshot_json` alone (a line outlives its product, see `SaleLocalStore.createTables` doc), and Task 3 must keep that.
- `StockLocalStore.pendingDeltaUnits` finds pending rows via `payload_json LIKE %productId%`; a merge (Task 8) that rewrites payloads must keep this working (it matches the new id afterwards).
- `OfflineDb` has no `vendor`/`product` foreign keys anywhere; no FK cascade will help, every rewrite is explicit.
