# Premium Inventory Command Center — Flutter Design Spec

**Date:** 2026-05-16  
**Status:** Approved  
**Feature gate:** `enabledFeatures['inventory_inbound_receiving'] == true` (existing `AppPermissions.canUseInventoryInboundReceiving`)

---

## 1. Overview

`InventoryScreen` becomes a thin router. Users with the premium feature flag get the full bento command center (`PremiumInventoryShell`). Users without it get the existing stock list (`BasicInventoryView`, extracted from the current `inventory_screen.dart`).

```
InventoryScreen
├── isPremium == false  →  BasicInventoryView   (existing code, extracted)
└── isPremium == true   →  PremiumInventoryShell (new)
```

`isPremium` = `context.read<AuthBloc>().state.permissions.canUseInventoryInboundReceiving`

---

## 2. Visual Identity

All premium surfaces use the amber-gold on deep dark-brown palette. No Material blue or teal on premium chrome.

```dart
// Premium color tokens — define as top-level constants in a new
// lib/features/inventory/presentation/premium/premium_colors.dart
const premiumHeroStart  = Color(0xFF1C0D04);
const premiumHeroPeak   = Color(0xFF2D1607);
const premiumHeroEnd    = Color(0xFF3A1E09);
const goldDeep          = Color(0xFFD97706);
const gold              = Color(0xFFFBBF24);
const goldSoft          = Color(0xFFF4DBA9);
const goldLight         = Color(0xFFFDE68A);
const premiumAmber700   = Color(0xFF92400E);
const premiumAmber900   = Color(0xFF451A03);
```

**Hero gradient:** `LinearGradient(topRight→bottomLeft, [0xFF1C0D04, 0xFF2D1607, 0xFF3A1E09], stops [0, 0.55, 1])`  
Two radial aurora overlays: top-right warm amber (`0xFFD97706` @ 18% opacity), bottom-left faint gold (`0xFFFBBF24` @ 10% opacity).

**CTA button:** `LinearGradient(top→bottom, [0xFFD97706, 0xFF92400E])`

**Bento tile:** white bg, `BorderRadius.circular(16)`, `Border.all(black @ 6%)`, subtle box shadow.

**KPI card (inside hero):** white @ 7%→3% gradient, `BorderRadius.circular(12)`, white border @ 9%.

**Premium badge:** gradient pill `[0xFFFBBF24, 0xFFD97706, 0xFF92400E]` with `Icons.auto_awesome` (size 10) + "PREMIUM" text.

**Status dot:** amber (`0xFFFBBF24`) AnimatedContainer pulse (scale + opacity, 2s repeat).

---

## 3. Architecture — Approach B

### 3.1 PremiumInventoryBloc (dashboard)

Owns the 6 parallel dashboard-level data calls. Fires on `OnPremiumInventoryStarted` and `OnPremiumInventoryRefreshed`.

**State fields:**
- `premiumSummary: PremiumSummaryData?`
- `stockPage: List<StockData>` (first page, for bento overview cards)
- `lowStockItems: List<StockData>` (top items for Restock Queue card)
- `expiryPreview: List<ExpiryReportItem>` (soonest 3–5, for Expiry Timeline card)
- `vendorSummary: VendorSummaryData?` (for Vendor Board card)
- `recentInbound: List<InboundTransactionData>` (last 50 records, 7-day window — used for both Recent Receipts card top-3 display AND Inbound Velocity bar chart daily aggregation)
- `status: PremiumInventoryStatus` (initial / loading / success / failure)
- `isFromCache: bool`
- `responseError: String?`

**Cold-start flow:**
1. Load 4 SQLite caches in parallel: `getPremiumSummary`, `getVendors`, `getInboundTransactions`, `getStock`
2. If any cache hit → emit `fromCache: true` state immediately (bento grid renders with data)
3. If online → fire 6 network calls in parallel via `Future.wait([...])`
4. On success → update caches → emit fresh state
5. If offline → remain on cached state, `connectionStatus` from `OfflineStatusBloc` drives the status dot colour

### 3.2 Per-sheet Cubits (lazy — initialise only when sheet opens)

| Cubit | Sheet | Loads |
|---|---|---|
| `StockLevelsCubit` | Stock Levels Sheet | Paginated stock, search, filter |
| `InboundCubit` | Inbound Sheet | Inbound list + form submit |
| `VendorsCubit` | Vendors Sheet | Vendor list, CRUD (online-only) |
| `ExpiryReportCubit` | Expiry Report Sheet | Filtered expiry list |

Low Stock Sheet reuses `StockLevelsCubit` pre-filtered with `lowStock: true`.  
Each sheet wraps its cubit in a `BlocProvider` created inline when the sheet is shown.  
The existing `InventoryBloc` handles stock add/adjust/transfer operations — both basic and premium share it.

---

## 4. Data Layer

### 4.1 New DTOs

**`premium_summary_dto.dart`**
```dart
class PremiumSummaryData {
  final int stockItemsCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int activeVendorsCount;
  final int inboundThisMonthCount;
  final String receivedQuantityThisMonth;
  // fromJson, toJson
}
```

**`vendor_response_dto.dart`**
```dart
class VendorData {
  final String id, name;
  final String? phone, email, address, notes;
  final bool isActive;
  // fromJson, toJson, copyWith
}

class VendorListResponseDto {
  final int count, totalPages;
  final List<VendorData> results;
}
```

**`vendor_summary_dto.dart`**
```dart
class VendorSummaryData {
  final int totalTransactions;
  final String totalQuantity;
  final List<VendorSummaryItem> vendors;
}
class VendorSummaryItem {
  final String vendorId, vendorName;
  final int transactionsCount;
  final String totalQuantity;
}
```

**`expiry_report_response_dto.dart`**
```dart
class ExpiryReportItem {
  final String id, productName;
  final String? productSku, shopName, batchNumber;
  final String quantity, expiryDate;
  final int daysRemaining;
  final bool isExpired;
}

class ExpiryReportResponseDto {
  final int count, totalPages;
  final List<ExpiryReportItem> results;
}
```

**`inbound_list_response_dto.dart`**  
Adds `vendorId`, `vendorName`, `totalQuantity`, `createdByName` fields directly to the existing `InboundTransactionData` class (all nullable — backwards compatible with the existing `createInboundTransaction` response). Adds `InboundListResponseDto` (paginated wrapper) as a new class in the same file.

**`create_vendor_request_dto.dart`** / **`update_vendor_request_dto.dart`** — simple field wrappers with `toJson()`.

### 4.2 New repository methods (added to `InventoryRepository` abstract + `InventoryRepoImpl`)

```dart
Future<Either<String?, PremiumSummaryData>> getPremiumSummary({String? shopId});
Future<Either<String?, InboundListResponseDto>> getInboundList({String? shopId, String? vendorId, int page = 1});
Future<Either<String?, VendorListResponseDto>> getVendors({bool activeOnly = true, int pageSize = 200});
Future<Either<String?, VendorData>> getVendorById(String id);
Future<Either<String?, VendorData>> createVendor(CreateVendorRequestDto request);
Future<Either<String?, VendorData>> updateVendor(String id, UpdateVendorRequestDto request);
Future<Either<String?, bool>> deleteVendor(String id);
Future<Either<String?, VendorSummaryData>> getVendorSummary({String? shopId, String? dateFrom, String? dateTo});
Future<Either<String?, ExpiryReportResponseDto>> getExpiryReport({String status = 'expiring_soon', String? shopId, int page = 1});
```

API paths match the spec exactly (section 2a–2h).

### 4.3 OfflineLocalCache additions

```dart
// Vendors (needed for offline inbound form — vendor selector)
Future<List<VendorData>> getVendors();
Future<void> saveVendors(List<VendorData> vendors);

// Premium summary (KPI cards on cold start)
Future<PremiumSummaryData?> getPremiumSummary({String? shopId});
Future<void> savePremiumSummary(PremiumSummaryData data, {String? shopId});

// Inbound transaction list (Recent Receipts card + Inbound sheet history)
Future<List<InboundTransactionData>> getInboundTransactions({int limit = 20});
Future<void> saveInboundTransactions(List<InboundTransactionData> transactions);
```

`hasBootstrapCache()` is **not changed** — vendors/premium tables are premium-only and do not gate the bootstrap check.

---

## 5. Screen Layout

### 5.1 PremiumInventoryShell

`CustomScrollView` with two slivers:
1. `SliverToBoxAdapter` → `PremiumHeroHeader` (hero gradient block + KPI scroll)
2. `SliverPadding` → `BentoGrid` (2-column `GridView`, `shrinkWrap: false`, physics: `NeverScrollableScrollPhysics` inside the outer scroll)

### 5.2 Hero Header

```
PremiumHeroHeader
├── Title row: "Inventory" + PremiumBadge + StatusDot pill (right-aligned)
├── Subtitle: "{N} shops · {total_skus} SKUs · {N} vendors"
├── Action row: [Receive Stock CTA] [Export ghost] [Scan ghost]
└── KPI scroll (horizontal): 4 KpiCard widgets
```

**4 KPI Cards:**

| # | Title | Value | Sub-label | Accent |
|---|---|---|---|---|
| 1 | Inventory Health | `{pct}%` | `{inStock} / {total} healthy` | `#5EEAD4` |
| 2 | Needs Restock | `{low + out}` | `{low} low · {out} out` | `#FCD34D` |
| 3 | Inbound This Month | `{inboundThisMonthCount}` | `{receivedQty} units received` | `#93C5FD` |
| 4 | Expiring ≤30 days | `{expiringSoonCount}` | `{expiredCount} already expired` | `#FCA5A5` |

Health % = `(stockItemsCount - lowStockCount - outOfStockCount) / stockItemsCount * 100` (clamp 0–100).

### 5.3 Bento Grid (7 cards)

| Card | Spans | Content | Opens |
|---|---|---|---|
| Health Ring | 1 col | `fl_chart` PieChart donut, centre shows pct, 3 stat chips below | Stock Levels sheet |
| Inbound Velocity | 1 col | `fl_chart` BarChart 7 bars (last 7 days), today = amber. Data derived from `recentInbound` list — group by date client-side. | Inbound sheet |
| Restock Queue | 2 col | Top 3 low/out items, badge + name + qty | Low Stock sheet |
| Expiry Timeline | 1 col | Soonest 3 batches, days-remaining chip (red ≤5, amber ≤14, green otherwise) | Expiry sheet |
| Vendor Board | 1 col | Top 3 vendors, gold/silver/bronze rank chips | Vendors sheet |
| Recent Receipts | 2 col | Last 2–3 transactions, ref + vendor + qty | Inbound sheet |
| Quick Actions | 2 col | 2×2 grid: Receive / Adjust / Vendors / Report | Respective sheets |

Loading state: each card shows a shimmer placeholder (same height as its loaded content).  
Error state: card shows a small retry icon — does not block other cards.

---

## 6. Bottom Sheets

All sheets use `showModalBottomSheet` with `isScrollControlled: true`, `useSafeArea: true`, drag handle at top. Each wraps its Cubit in `BlocProvider`.

### 6.1 Stock Levels Sheet (`StockLevelsCubit`)
- Search field + filter chips: All / Low / Out of Stock
- Paginated `ListView` (load more on scroll)
- Tap row → inline adjustment bottom card: Add / Remove / Set qty + notes → dispatches to existing `InventoryBloc` (`OnAddStock` / `OnAdjustStock`)

### 6.2 Low Stock Sheet
- Same as Stock Levels sheet but pre-filtered `?low_stock=true&out_of_stock=true`
- Each row has a `[Receive]` button that pops this sheet and opens Inbound sheet pre-filled with that product

### 6.3 Inbound Sheet (`InboundCubit`)
Two sections in one scrollable sheet:

**Section A — Receive Form:**
- Shop: pre-filled from `AuthBloc.state.profile.defaultShopId` (read-only for MVP — no shop picker, the user's default shop is used)
- Vendor selector (dropdown from cached `vendors` list — works offline) + inline "Add Vendor" that opens Vendors sheet
- Reference / Invoice field
- Notes field (optional)
- Line items: expandable list, each row: product search (from `GET /products/?shop=`) + qty + unit cost (optional) + expiry date (optional) + batch number (optional)
- `[+ Add Item]` button
- `[Record Inbound]` → `OnCreateInboundTransaction` (existing event, vendor_id added to `CreateInboundRequestDto`)
- Offline: queues via existing `OfflineInboundQueue`

**Section B — Transaction History:**
- Paginated list from `InboundCubit`
- Tap → detail modal (reference, vendor, items table)

### 6.4 Expiry Report Sheet (`ExpiryReportCubit`)
- Filter chips: Expiring Soon / Expired / All
- Optional date range row
- List: product name, batch, shop, qty, expiry date, days-remaining chip
- Chip colours: red ≤5 days, amber ≤14 days, green otherwise

### 6.5 Vendors Sheet (`VendorsCubit`) — online-only
- List of active vendors: name, phone, transaction count
- `[+ Add Vendor]` → inline form (name required, phone/email/address/notes optional)
- Tap vendor → detail with Edit and Deactivate options
- No offline queuing — operations require internet (show snackbar if offline)

---

## 7. Navigation Changes

### InventoryScreen (router)
```dart
class InventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPremium = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canUseInventoryInboundReceiving,
    );
    return isPremium ? const PremiumInventoryShell() : const BasicInventoryView();
  }
}
```

`BasicInventoryView` = current `_InventoryScreenState` body extracted verbatim.

### Bottom Nav — Premium Indicator
When `isPremium == true`, the Inventory `NavTab` gets a trailing `Icons.auto_awesome` (size 12, color `0xFFD97706`) appended to its label or icon. Achieved by adding an optional `trailingIndicator` field to `NavTab` and rendering it in `NavShell`.

---

## 8. Dependency Injection

In `providers.dart`, add:
```dart
BlocProvider(
  create: (_) => PremiumInventoryBloc(
    useCase: getIt<InventoryUseCase>(),
    offlineLocalCache: getIt<OfflineLocalCache>(),
    isOnline: () => getIt<OfflineStatusBloc>().isDeviceOnline,
  ),
),
```

Sheet Cubits (`StockLevelsCubit`, `InboundCubit`, `VendorsCubit`, `ExpiryReportCubit`) are created inline at sheet show-time, not in the global provider tree.

---

## 9. pubspec.yaml Change

```yaml
dependencies:
  fl_chart: ^0.69.0   # donut + bar charts for bento cards
```

---

## 10. What Is NOT in Scope (MVP)

- Export button — ghost/disabled
- Scan button — ghost/disabled
- Stock Movements audit log (`GET /inventory/movements/`) — not shown
- Vendor offline queuing — vendor CRUD requires internet
- Push notifications for expiry alerts
- Multi-shop filter in KPI cards (uses `defaultShopId`, no shop switcher)
