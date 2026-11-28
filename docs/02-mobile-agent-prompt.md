# Prompt for the MOBILE agent (/Users/almogdadjabir/Documents/projects/amana/amana_mobile_app_pos — Flutter)

You are working on the AmanaPOS Flutter app. Read its CLAUDE.md / project docs first and follow them (do not change git state unless the owner asks).
The Django backend (/Users/almogdadjabir/Documents/projects/amana/amanaPOS-be, read-only for you) changed; read docs/handoff/_backend-changes-summary.md,
docs/readiness/04-perf-fixes-results.md and §5/§8 of docs/readiness/03-desktop-vs-backend-parity.md (the "MOBILE" recommendations). Verify every point in the real code before changing it.

## Do now
1. **Inbound is no longer plan-gated.** `lib/core/permissions/app_permissions.dart` defines `inventoryInboundReceivingFeature = 'inventory_inbound_receiving'`, `canUseInventoryInboundReceiving` and `canSeeInboundPremiumCard` based on `enabledFeatures`.
   Refactor so inbound/vendors/expiry/premium-summary availability depends only on role (manager+/owner) and business type (not restaurant), NOT on the plan feature. Keep the constant only if still referenced for display; remove paywall/upsell
   UI paths for it; update tests/l10n accordingly. Don't break the generic `enabledFeatures` mechanism for other features.
2. **Offline bootstrap (`lib/core/offline/data/offline_remote_data_source.dart`, `getBootstrap()` -> `/api/v1/offline/bootstrap/`)**:
   - The monolithic call still works unchanged but is now throttled to 12/min per user and can be 20 MB for big tenants (4 MB gzipped). Verify the HTTP client sends `Accept-Encoding: gzip` and transparently decodes (dart:io HttpClient does by default; if Dio/another adapter is used, confirm) and has a sane timeout for big payloads.
   - Handle 429 with `Retry-After` (backoff, don't hammer).
   - Preferred refactor: implement paged bootstrap using `?section=core`, then `categories`, `products`, `customers`, `stock`, `expiry_batches` with `limit=500` following `next` until null (shapes in the summary file; `core.items` is an object `{businesses, shops, active_subscription}`). Show progress, persist each page in one DB transaction per page, make it resumable (store the last cursor per section), and fall back to the monolithic call only if the sectioned call returns 400 (old backend). Keep the existing DTO mapping (`OfflineBootstrapDto`) working by assembling the sections.
3. **Debts** (`/customers/debts/`): server pagination is available (`page`, `page_size`); adopt it where a debtor list is shown and keep it working if `count` is absent.
4. **Dates**: backend `date_from/date_to` filters are UTC calendar days and are not converted to the business time zone. Audit every place the app sends date ranges (sales history/reports/inventory) and centralise a helper that maps the user's local day to the request; document the date-only limitation and list endpoints where the local day can be off by the tz offset; report it as a backend follow-up (ISO datetime bounds) instead of working around it silently. Display times in the business timezone.
5. **Prepare for pending backend changes** (last section of the summary): cashiers will get 403 on refund/cancel/stock changes/product writes — hide/disable by role and show the standard backend error message; treat `receipt_number` as an opaque string; handle push per-mutation `rejected` codes; tolerate a `deleted` flag on product/category bootstrap rows.
6. **Vocabulary/UX (parity report §5/§8)**: map `pharmacy` and restaurant units to the backend enums, use the `owner` role label, align Arabic terms with the glossary in the report, and show decimals/currency consistently with the backend (2 dp money, 3 dp quantity, currency from `business.currency`).

## Definition of done
`flutter analyze` and `flutter test` (report real output; say what you could not run), final summary of files changed and decisions, backend follow-ups wanted. Do not commit.
