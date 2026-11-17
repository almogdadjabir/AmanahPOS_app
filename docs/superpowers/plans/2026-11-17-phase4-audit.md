# Phase 4 audit (Task 1)

- **Readers of `sale_refunds`:** `LocalDashboardQueries._refunds` (count/amount/cash/bankak; payment split currently from the SALE's method, contract says `refund.method`: switch to `COALESCE(r.method, s.payment_method)`); `offline_local_cache` comment only; `catalog_conflict_service` (json not rewritten). `LocalSalesHistory` does NOT read refunds or per-line returned quantity today: Task 3 adds both.
- **REST callers to remove:** `returns_repo_impl.dart` (`POST sales/{id}/refund/`), `customer_repo_impl.dart` (all four methods).
- **Feed refund row (`ser_refund`)** carries `reference` (client reference), `sale`, `shop`, `total`, `method`, `items:[{sale_item, quantity, amount}]`, `created_at`. So the local twin is matched by `(sale_id, reference)`.
- **Stock on refund:** the BE refund restocks and the push result carries `stock_after`; local stock is re-based from it on `applied` only (same rule as sales). No local optimistic restock (ruling in ledger).
- **Line ids:** local `sale_items.id` equals the server `SaleItem` PK (BE deviation 9), so a refund can name `sale_item_id` before the sale syncs.
