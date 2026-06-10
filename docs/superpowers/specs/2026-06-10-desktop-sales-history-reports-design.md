# Desktop Sales History + Reports & Statistics

**Date:** 2026-06-10
**Status:** Approved for planning

## Goal

Give desktop users a proper "Sales History" destination (matching the
Products/Inventory desktop control-room pattern) that combines:

1. A **Transactions** view of past sales (table, filters, search).
2. A **Reports & Statistics** dashboard (revenue trend, payment method
   breakdown, top products/categories, peak hours, day-of-week pattern)
   for a selected date range.

Mobile must remain completely unchanged — both visually and in navigation.

## Non-goals

- No changes to the mobile Sales History screen, mobile bottom nav, or the
  Settings → Sales History entry point's behavior on mobile.
- No new permission tiers — Sales History remains accessible to anyone with
  an active session, same as today.
- Export/printing of reports is out of scope for this iteration (UI may
  reserve a slot for it, but it's not implemented).

## 1. Navigation & Screen Structure

- Add `AppFeature.salesHistory` to `lib/features/main_screen/data/app_feature.dart`,
  with `AppPermissions.canAccessSalesHistory => _hasSession` (same gate as
  Products/Categories — no extra restriction).
- Add a "Sales History" destination to:
  - `desktop_navigation_rail.dart` `_buildAllTabs` — positioned right after
    Inventory.
  - `desktop_more_drawer.dart` `_buildAllTabs` (kept in sync, as today).
  - Icon: reuse `SolarIconsOutline.notebook` / bold variant (same icon used
    in Settings today).
  - Since the rail caps at `_kMaxRailDestinations = 6`, adding a 7th item
    pushes the last tab (Cashiers/Users) into the More drawer overflow —
    this is existing, expected behavior of the overflow mechanism.
- Add a case to `NavigationConfig.screenFor`:
  ```dart
  case AppFeature.salesHistory:
    return FeatureBlocProviders.salesHistory(child: const SalesHistoryScreen());
  ```
- **Mobile bottom nav is untouched**: `bottom_nav.dart`'s `buildTabs` is a
  separate function from the desktop rail's `_buildAllTabs` and is not
  modified — the new feature never appears there.
- `SalesHistoryScreen.build()` gains one branch, mirroring
  `ProductsScreen`/`BasicInventoryView`:
  ```dart
  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const DesktopSalesHistoryView();
    // ...existing mobile Scaffold/body, unchanged
  }
  ```
  The Settings → "Sales History" tile keeps pushing the same route on both
  platforms; on desktop it now renders `DesktopSalesHistoryView`, on mobile
  the existing list — no separate code paths to maintain.

## 2. Desktop Sales History View — Transactions tab

New file: `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart`

Structure mirrors `DesktopProductsView`/`DesktopInventoryView`:

- **Top bar** (`DesktopSalesHistoryTopBar`, new widget):
  - Search field (filters the loaded transaction list, like
    `_searchCtrl` in the mobile screen).
  - Refresh button.
  - Segmented **Transactions / Reports & Statistics** switch
    (`SalesViewTabSwitch`, new small widget) controlling which tab body is
    shown. Tab state lives in `_DesktopSalesHistoryViewState`.

- **Transactions tab**:
  - `DesktopSalesStatsRow` (new) — 4 KPI cards: Sales count, Revenue,
    Avg sale, Refunds — computed from `SalesHistoryBloc.state.items` the
    same way `SaleStatsRow` does today. Cards double as quick filters
    (All / Today / Completed / Refunded / Pending), reusing the existing
    `SaleFilter` enum and `_applyFilter` logic from `SalesHistoryScreen`.
  - `DesktopSalesTable` (new) — full-width table/list of transactions:
    columns Date/time, Receipt #, Customer, Items, Payment method, Total,
    Status. Row tap opens the existing `SaleDetailSheet`. Infinite scroll
    dispatches `SalesHistoryLoadMore` exactly as the mobile list does.
  - No fixed sidebar on this tab (unlike Products/Inventory) — full width
    suits tabular data better than a card grid.
  - Loading/empty/error states reuse `SaleShimmer` / `SaleEmptyState` /
    `SaleErrorView`, restyled for the table layout (e.g. row-shaped
    shimmer placeholders).
  - **No backend changes required** for this tab — it's the existing
    `SalesHistoryBloc`/`SalesHistoryUseCase` with a desktop presentation.

## 3. Reports & Statistics tab

### Backend API contract (new endpoint)

```
GET /api/v1/sales/reports/?date_from=YYYY-MM-DD&date_to=YYYY-MM-DD&shop_id=&timezone=
```

```json
{
  "range": { "from": "2026-06-01", "to": "2026-06-10" },
  "currency": "SDG",
  "summary": {
    "gross_sales_amount": 0,
    "net_sales_amount": 0,
    "sales_count": 0,
    "average_sale_amount": 0,
    "refund_amount": 0,
    "refund_count": 0
  },
  "trend": {
    "interval": "day",
    "points": [
      { "label": "2026-06-01", "gross_amount": 0, "net_amount": 0, "sales_count": 0 }
    ]
  },
  "payment_methods": [
    { "method": "cash", "amount": 0, "count": 0 }
  ],
  "top_products": [
    { "product_id": "...", "name": "...", "quantity_sold": 0, "gross_amount": 0, "thumbnail_url": null }
  ],
  "top_categories": [
    { "category_id": "...", "name": "...", "quantity_sold": 0, "gross_amount": 0 }
  ],
  "peak_hours": [
    { "hour": 0, "sales_count": 0, "amount": 0 }
  ],
  "day_of_week": [
    { "weekday": 1, "sales_count": 0, "amount": 0 }
  ]
}
```

Notes:
- `trend.interval` is `"hour"` when `date_from == date_to` (single-day
  view, e.g. Today/Yesterday), otherwise `"day"`.
- `peak_hours` always has 24 entries (`hour` 0–23).
- `day_of_week` always has 7 entries, ISO numbering (`1` = Monday … `7` =
  Sunday).
- `payment_methods`/`top_products`/`top_categories` may be empty arrays.

### Flutter data layer

- New `SalesReport` domain entity + `SalesReportDto` (and nested
  `SalesReportSummary`, `SalesTrendPoint`, `PaymentMethodBreakdown`,
  `SalesTopProduct`, `SalesTopCategory`, `PeakHourStat`, `DayOfWeekStat`)
  in `lib/features/sales_history/data/models/`.
- `getSalesReport({required DateTime from, required DateTime to, String? shopId})`
  added to `SalesHistoryRepository` / `SalesHistoryRepoImpl` /
  `SalesHistoryUseCase`.
- New `SalesReportBloc` (separate from `SalesHistoryBloc`) — state holds:
  - selected range (`Today` / `Yesterday` / custom `DateTimeRange`)
  - status (`initial` / `loading` / `loaded` / `failure`)
  - the loaded `SalesReport?`
  - error message
- `FeatureBlocProviders.salesHistory` becomes a `MultiBlocProvider`
  providing both `SalesHistoryBloc` and `SalesReportBloc`.
- DI: register the new repository method usage / `SalesReportUseCase`
  alongside the existing `SalesHistoryUseCase` registration in
  `dependencies_provider.dart`.

### Reports tab UI

New folder: `lib/features/sales_history/presentation/widgets/reports/`

- `DateRangeBar` — "Today" / "Yesterday" chips + custom range button
  (opens `showDateRangePicker`); selecting any option dispatches a
  `SalesReportRangeChanged` event.
- `ReportsKpiRow` — 4 KPI cards from `summary` (Revenue, Sales count,
  Avg sale, Refunds), styled like `DesktopSalesStatsRow` but read-only
  (no filter behavior).
- Bento grid (2-row `GridView`/`Wrap` matching the approved mockup):
  - `RevenueTrendCard` — fl_chart `LineChart` of `trend.points`
    (gross + net), spans 2 rows on the left.
  - `PaymentBreakdownCard` — fl_chart `PieChart` donut of `payment_methods`.
  - `PeakHoursCard` — fl_chart `BarChart`, 24 hourly bars from `peak_hours`.
  - `TopProductsCard` — ranked list with mini progress bars from
    `top_products`.
  - `TopCategoriesCard` — ranked list from `top_categories`.
  - `DayOfWeekCard` — fl_chart `BarChart`, 7 bars from `day_of_week`.
- `ReportsLoadingSkeleton`, `ReportsEmptyView` (no sales in range),
  `ReportsErrorView` (retry) — following the conventions of
  `_DesktopInventorySkeleton` / `InventoryErrorView`.

## 4. Visual style

- Reuse the existing desktop control-room aesthetic: `context.appColors`,
  `AppTextStyles`, `AppDims.rXl` rounded cards, `colors.surface` /
  `colors.border`, `flutter_animate` fade/slide-in stagger — same as
  `DesktopProductsView`/`DesktopInventoryView`.
- New `sales_report_colors.dart` palette: cool blues/teals/violets for an
  "analytics" feel, distinct from the warm-gold premium-inventory palette.
  Used consistently across the trend line, donut segments, and bar charts.
- Bento cards get subtle gradient backgrounds + soft shadows (lighter-weight
  version of `health_ring_card.dart`/`inbound_velocity_card.dart` styling)
  for a "futuristic" but not overly heavy look.
- Money formatting via existing `AppFormat.compactMoney` / thousands
  separators, RTL-safe via the `forceValueLtr`/`Directionality` pattern
  already used in `SaleStatsRow`.

## File summary (new/changed)

**New:**
- `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart`
- `lib/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart`
- `lib/features/sales_history/presentation/widgets/sales_view_tab_switch.dart`
- `lib/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart`
- `lib/features/sales_history/presentation/widgets/desktop_sales_table.dart`
- `lib/features/sales_history/presentation/widgets/reports/date_range_bar.dart`
- `lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart`
- `lib/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/peak_hours_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/top_products_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/top_categories_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/day_of_week_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/reports_status_views.dart`
  (loading/empty/error)
- `lib/features/sales_history/presentation/widgets/reports/sales_report_colors.dart`
- `lib/features/sales_history/presentation/bloc/sales_report_bloc.dart`
  (+ `sales_report_event.dart`, `sales_report_state.dart`)
- `lib/features/sales_history/data/models/sales_report_dto.dart` — DTOs plus
  the `SalesReport` domain model and its nested types, following the
  `sale_history_item.dart` convention of co-locating the domain model with
  its `fromDto` factory in `data/models/` (no separate `domain/entities/`
  file for this feature).

**Changed:**
- `lib/features/main_screen/data/app_feature.dart` — add `salesHistory`
  + permission mapping
- `lib/core/permissions/app_permissions.dart` — add `canAccessSalesHistory`
- `lib/features/main_screen/presentation/widgets/desktop_navigation_rail.dart`
  — add tab
- `lib/features/main_screen/presentation/widgets/desktop_more_drawer.dart`
  — add tab (kept in sync)
- `lib/features/main_screen/data/navigation_config.dart` — add screen case
- `lib/features/sales_history/presentation/sales_history_screen.dart` —
  add `if (context.isDesktop) return const DesktopSalesHistoryView();`
- `lib/features/sales_history/domain/repositories/sales_history_repository.dart`
  / `sales_history_repo_impl.dart` / `sales_history_usecase.dart` — add
  `getSalesReport(...)`
- `lib/config/providers/feature_bloc_providers.dart` — `salesHistory`
  becomes a `MultiBlocProvider`
- `lib/utilities/dependencies_provider.dart` — DI registration if a
  separate use case is introduced

## Open questions for backend implementation

- Confirm `shop_id` filtering behavior matches the existing
  `api/v1/sales/?shop=` param naming (`shop_id` vs `shop`).
- Confirm timezone handling matches `dashboard-summary`'s `timezone` param.
