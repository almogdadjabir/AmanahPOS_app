# Mobile Tax Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface the backend's business-level tax system (VAT-style, single rate per business, inclusive or exclusive) in the Flutter POS app — cart preview, receipts, sales history, reports KPI, settings card — while never sending tax fields to the server and keeping everything working offline.

**Architecture:** A central `TaxConfig` value object + pure `TaxCalculator` implement the backend's formulas (docs/TAX_SUPPORT.md §2) exactly once. The 4 tax fields are added to `BusinessData` (cached offline automatically via the raw-JSON `businesses` table). `PosState` carries the config and derives tax/net totals; widgets only render. The sale request and offline-sync payloads stop sending `tax_amount` — the server computes tax. Server response values are preferred for receipts; local previews are used for offline sales.

**Tech Stack:** Flutter, flutter_bloc, Equatable, sqflite (existing offline DB — no schema change), flutter gen-l10n (en + ar), flutter_test.

**Spec:** `docs/superpowers/specs/2026-06-12-mobile-tax-support-design.md`

**Conventions for every task:**
- Run tests with `flutter test <path>` from the repo root (`/Users/almogdadjabir/StudioProjects/amana_pos`).
- Commit messages end with: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Strings shown to users go through l10n (`context.tr.<key>`); Task 3 adds all needed keys, so later UI tasks compile.

---

### Task 1: Add tax fields to BusinessData

**Files:**
- Modify: `lib/features/business/data/models/responses/business_response_dto.dart`
- Test: `test/features/business/data/models/business_response_dto_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/features/business/data/models/business_response_dto_test.dart`:

```dart
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessData tax fields', () {
    test('parses tax fields from json', () {
      final data = BusinessData.fromJson({
        'id': 'b1',
        'name': 'Main Shop',
        'tax_enabled': true,
        'tax_name': 'VAT',
        'tax_rate': '15.00',
        'tax_inclusive': false,
      });

      expect(data.taxEnabled, true);
      expect(data.taxName, 'VAT');
      expect(data.taxRate, '15.00');
      expect(data.taxInclusive, false);
    });

    test('missing tax fields parse to null (stale offline cache)', () {
      final data = BusinessData.fromJson({'id': 'b1', 'name': 'Old Shop'});

      expect(data.taxEnabled, isNull);
      expect(data.taxName, isNull);
      expect(data.taxRate, isNull);
      expect(data.taxInclusive, isNull);
    });

    test('toJson round-trips tax fields', () {
      final data = BusinessData.fromJson({
        'id': 'b1',
        'tax_enabled': true,
        'tax_name': 'GST',
        'tax_rate': '7.50',
        'tax_inclusive': true,
      });
      final json = data.toJson();

      expect(json['tax_enabled'], true);
      expect(json['tax_name'], 'GST');
      expect(json['tax_rate'], '7.50');
      expect(json['tax_inclusive'], true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/business/data/models/business_response_dto_test.dart`
Expected: FAIL — `taxEnabled` getter not defined.

- [ ] **Step 3: Add the fields to BusinessData**

In `lib/features/business/data/models/responses/business_response_dto.dart`, class `BusinessData`:

Add the field declarations after `String? email;`:

```dart
  bool? taxEnabled;
  String? taxName;
  String? taxRate;
  bool? taxInclusive;
```

Add to the constructor parameter list (after `this.email,`):

```dart
        this.taxEnabled,
        this.taxName,
        this.taxRate,
        this.taxInclusive,
```

In `BusinessData.fromJson`, after `email = json['email'];`:

```dart
    taxEnabled = json['tax_enabled'];
    taxName = json['tax_name'];
    taxRate = json['tax_rate']?.toString();
    taxInclusive = json['tax_inclusive'];
```

In `toJson()`, after `data['email'] = email;`:

```dart
    data['tax_enabled'] = taxEnabled;
    data['tax_name'] = taxName;
    data['tax_rate'] = taxRate;
    data['tax_inclusive'] = taxInclusive;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/business/data/models/business_response_dto_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/business/data/models/responses/business_response_dto.dart test/features/business/data/models/business_response_dto_test.dart
git commit -m "feat(tax): parse business tax config fields"
```

---

### Task 2: TaxConfig value object + TaxCalculator

**Files:**
- Create: `lib/features/pos/domain/tax_config.dart`
- Test: `test/features/pos/domain/tax_config_test.dart` (create)

- [ ] **Step 1: Write the failing tests**

Create `test/features/pos/domain/tax_config_test.dart`. The expected numbers come straight from docs/TAX_SUPPORT.md §2 (rate 15%, taxable 90.00).

```dart
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaxConfig.fromBusiness', () {
    test('maps fields and parses rate', () {
      final business = BusinessData.fromJson({
        'tax_enabled': true,
        'tax_name': 'GST',
        'tax_rate': '7.50',
        'tax_inclusive': true,
      });
      final config = TaxConfig.fromBusiness(business);

      expect(config.enabled, true);
      expect(config.name, 'GST');
      expect(config.rate, 7.5);
      expect(config.inclusive, true);
      expect(config.isActive, true);
    });

    test('null business and missing fields default to disabled', () {
      expect(TaxConfig.fromBusiness(null).isActive, false);

      final config = TaxConfig.fromBusiness(BusinessData.fromJson({}));
      expect(config.enabled, false);
      expect(config.name, 'VAT');
      expect(config.rate, 0);
      expect(config.inclusive, false);
      expect(config.isActive, false);
    });

    test('enabled with zero rate is not active', () {
      final config = TaxConfig.fromBusiness(BusinessData.fromJson({
        'tax_enabled': true,
        'tax_rate': '0.00',
      }));
      expect(config.isActive, false);
    });
  });

  group('formatTaxRate', () {
    test('whole rates drop decimals', () {
      expect(formatTaxRate(15.0), '15');
    });
    test('fractional rates keep significant decimals', () {
      expect(formatTaxRate(7.5), '7.5');
    });
  });

  group('TaxCalculator.compute', () {
    const exclusive = TaxConfig(
      enabled: true, name: 'VAT', rate: 15, inclusive: false);
    const inclusive = TaxConfig(
      enabled: true, name: 'VAT', rate: 15, inclusive: true);

    test('exclusive: tax added on top (spec example)', () {
      final r = TaxCalculator.compute(taxableAmount: 90.00, config: exclusive);
      expect(r.taxAmount, 13.50);
      expect(r.netAmount, 103.50);
    });

    test('inclusive: tax extracted from price (spec example)', () {
      final r = TaxCalculator.compute(taxableAmount: 90.00, config: inclusive);
      expect(r.taxAmount, 11.74);
      expect(r.netAmount, 90.00);
    });

    test('disabled: zero tax, net = taxable', () {
      final r = TaxCalculator.compute(
        taxableAmount: 90.00, config: const TaxConfig.disabled());
      expect(r.taxAmount, 0);
      expect(r.netAmount, 90.00);
    });

    test('rounds to 2 decimals half-up', () {
      // 33.33 * 0.15 = 4.9995 → 5.00
      const cfg = TaxConfig(enabled: true, name: 'VAT', rate: 15, inclusive: false);
      final r = TaxCalculator.compute(taxableAmount: 33.33, config: cfg);
      expect(r.taxAmount, 5.00);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/pos/domain/tax_config_test.dart`
Expected: FAIL — `tax_config.dart` does not exist.

- [ ] **Step 3: Implement TaxConfig + TaxCalculator**

Create `lib/features/pos/domain/tax_config.dart`:

```dart
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:equatable/equatable.dart';

/// "15" for 15.00, "7.5" for 7.50 — used in labels like "Tax (VAT 15%)".
String formatTaxRate(double rate) {
  if (rate % 1 == 0) return rate.toStringAsFixed(0);
  final s = rate.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

/// Snapshot of the business's tax settings (docs/TAX_SUPPORT.md §1).
class TaxConfig extends Equatable {
  final bool enabled;
  final String name;

  /// Percentage 0–100, e.g. 15.0 for 15%.
  final double rate;
  final bool inclusive;

  const TaxConfig({
    required this.enabled,
    required this.name,
    required this.rate,
    required this.inclusive,
  });

  const TaxConfig.disabled()
      : enabled = false,
        name = 'VAT',
        rate = 0,
        inclusive = false;

  factory TaxConfig.fromBusiness(BusinessData? business) {
    if (business == null) return const TaxConfig.disabled();
    final name = business.taxName?.trim();
    return TaxConfig(
      enabled: business.taxEnabled ?? false,
      name: (name == null || name.isEmpty) ? 'VAT' : name,
      rate: double.tryParse(business.taxRate ?? '') ?? 0,
      inclusive: business.taxInclusive ?? false,
    );
  }

  /// Tax applies only when enabled with a positive rate.
  bool get isActive => enabled && rate > 0;

  String get rateLabel => formatTaxRate(rate);

  @override
  List<Object?> get props => [enabled, name, rate, inclusive];
}

class TaxComputation {
  final double taxAmount;
  final double netAmount;

  const TaxComputation({required this.taxAmount, required this.netAmount});
}

/// Mirrors the backend's create_sale() math (docs/TAX_SUPPORT.md §2).
/// Preview only — the server's numbers are always authoritative.
class TaxCalculator {
  static TaxComputation compute({
    required double taxableAmount,
    required TaxConfig config,
  }) {
    if (!config.isActive) {
      return TaxComputation(taxAmount: 0, netAmount: _round2(taxableAmount));
    }
    final rate = config.rate / 100;
    if (config.inclusive) {
      final tax = _round2(taxableAmount - (taxableAmount / (1 + rate)));
      return TaxComputation(taxAmount: tax, netAmount: _round2(taxableAmount));
    }
    final tax = _round2(taxableAmount * rate);
    return TaxComputation(
      taxAmount: tax,
      netAmount: _round2(taxableAmount + tax),
    );
  }

  // Dart's round() is half-away-from-zero, which equals ROUND_HALF_UP for
  // the non-negative amounts we deal with.
  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/pos/domain/tax_config_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/pos/domain/tax_config.dart test/features/pos/domain/tax_config_test.dart
git commit -m "feat(tax): add TaxConfig and TaxCalculator (spec §2 formulas)"
```

---

### Task 3: Localized strings (en + ar)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`
- Generated: `lib/l10n/app_localizations*.dart` (via `flutter gen-l10n`)

- [ ] **Step 1: Add keys to app_en.arb**

In `lib/l10n/app_en.arb`, before the final closing `}` (after the `"searchSalesHistoryHint"` entry — add a comma to that line first):

```json
  "taxLabel": "Tax",
  "taxWithRate": "Tax ({taxName} {taxRate}%)",
  "@taxWithRate": {
    "placeholders": {
      "taxName": {"type": "String"},
      "taxRate": {"type": "String"}
    }
  },
  "taxWithRatePercent": "Tax ({taxRate}%)",
  "@taxWithRatePercent": {
    "placeholders": {
      "taxRate": {"type": "String"}
    }
  },
  "totalInclTax": "Total (incl. {taxName} {taxRate}%)",
  "@totalInclTax": {
    "placeholders": {
      "taxName": {"type": "String"},
      "taxRate": {"type": "String"}
    }
  },
  "taxIncluded": "Tax included",
  "taxCollected": "Tax Collected",
  "taxDisabled": "Tax disabled",
  "pricesIncludeTax": "Prices include tax",
  "pricesExcludeTax": "Prices exclude tax"
```

- [ ] **Step 2: Add the same keys to app_ar.arb**

In `lib/l10n/app_ar.arb`, before the final closing `}` (comma on the previous entry):

```json
  "taxLabel": "الضريبة",
  "taxWithRate": "الضريبة ({taxName} {taxRate}%)",
  "taxWithRatePercent": "الضريبة ({taxRate}%)",
  "totalInclTax": "الإجمالي (شامل {taxName} {taxRate}%)",
  "taxIncluded": "الضريبة المشمولة",
  "taxCollected": "الضرائب المحصلة",
  "taxDisabled": "الضريبة غير مفعلة",
  "pricesIncludeTax": "الأسعار شاملة الضريبة",
  "pricesExcludeTax": "الأسعار غير شاملة الضريبة"
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: no errors; `lib/l10n/app_localizations.dart` now contains `taxWithRate(String taxName, String taxRate)` etc.

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/l10n`
Expected: No issues found (pre-existing repo-wide warnings are out of scope).

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat(tax): add en/ar strings for tax display"
```

---

### Task 4: Golden rule — stop sending tax, compute local preview for offline queue

The app currently sends `tax_amount` in both the online sale request and the offline-sync payload. Remove it everywhere. The offline queue keeps storing a **local preview** of tax/net (displayed by the pending-sync screen) computed via `TaxCalculator`, but it is never sent.

**Files:**
- Modify: `lib/features/pos/data/model/requests/create_sale_request_dto.dart`
- Modify: `lib/features/pos/data/model/offline/offline_sale_dto.dart`
- Modify: `lib/features/pos/domain/repositories/pos_repository.dart`
- Modify: `lib/features/pos/domain/usecases/pos_usecase.dart`
- Modify: `lib/features/pos/data/repository_impl/pos_repo_impl.dart`
- Modify: `lib/features/pos/presentation/bloc/pos_bloc.dart` (remove `taxAmount: '0'` argument only)
- Test: `test/features/pos/data/model/sale_payload_no_tax_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/features/pos/data/model/sale_payload_no_tax_test.dart`:

```dart
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CreateSaleRequestDto.toJson never contains tax fields', () {
    const dto = CreateSaleRequestDto(
      clientSaleId: 'c1',
      shop: 's1',
      customer: null,
      paymentMethod: 'cash',
      discountAmount: '0',
      items: [CreateSaleItemDto(productId: 'p1', quantity: '1', unitPrice: '50.00')],
    );

    final json = dto.toJson();
    expect(json.containsKey('tax_amount'), false);
    expect(json.containsKey('tax_rate'), false);
    expect(json.containsKey('tax_inclusive'), false);
  });

  test('OfflineSaleDto.toSyncJson never contains tax fields', () {
    final dto = OfflineSaleDto(
      clientSaleId: 'c1',
      shopId: 's1',
      customerId: null,
      paymentMethod: 'cash',
      discountAmount: '0',
      taxAmount: '13.50', // local preview — stored, never sent
      subtotal: '90.00',
      total: '103.50',
      createdAt: DateTime.utc(2026, 6, 12),
      items: [
        OfflineSaleItemDto(
          productId: 'p1',
          productName: 'Item',
          quantity: 1,
          unitPrice: '90.00',
          lineTotal: '90.00',
          productSnapshot: ProductData.fromJson(const {'id': 'p1'}),
        ),
      ],
    );

    final json = dto.toSyncJson();
    expect(json.containsKey('tax_amount'), false);
    expect(json.containsKey('tax_rate'), false);
    expect(json.containsKey('tax_inclusive'), false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/pos/data/model/sale_payload_no_tax_test.dart`
Expected: FAIL — `CreateSaleRequestDto` still requires `taxAmount`, and both `toJson` maps contain `'tax_amount'`.

- [ ] **Step 3: Remove taxAmount from CreateSaleRequestDto**

In `lib/features/pos/data/model/requests/create_sale_request_dto.dart`, delete these three lines:

```dart
  final String taxAmount;
```

```dart
    required this.taxAmount,
```

```dart
      'tax_amount': taxAmount,
```

- [ ] **Step 4: Stop sending tax in the offline-sync payload**

In `lib/features/pos/data/model/offline/offline_sale_dto.dart`, in `toSyncJson()`, delete the line:

```dart
      'tax_amount': taxAmount,
```

Keep the `taxAmount` field itself — it stores the local preview shown by the pending-sync screen. Update its doc position by adding a comment on the field:

```dart
  /// Local preview only (computed via TaxCalculator at queue time).
  /// Displayed on the pending-sync screen — NEVER sent to the server,
  /// which recomputes tax at sync time (docs/TAX_SUPPORT.md §4).
  final String taxAmount;
```

- [ ] **Step 5: Change the submitSale signature from taxAmount to taxConfig**

`lib/features/pos/domain/repositories/pos_repository.dart` — replace the whole file with:

```dart
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:fpdart/fpdart.dart';

abstract class PosRepository {
  Future<Either<String?, PosSubmitResult>> submitSale({
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    String discountAmount,
    TaxConfig taxConfig,
  });
}
```

`lib/features/pos/domain/usecases/pos_usecase.dart` — replace `submitSale` with:

```dart
  Future<Either<String?, PosSubmitResult>> submitSale({
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    String discountAmount = '0',
    TaxConfig taxConfig = const TaxConfig.disabled(),
  }) {
    return repository.submitSale(
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      items: items,
      discountAmount: discountAmount,
      taxConfig: taxConfig,
    );
  }
```

and add the import:

```dart
import 'package:amana_pos/features/pos/domain/tax_config.dart';
```

- [ ] **Step 6: Update PosRepoImpl**

In `lib/features/pos/data/repository_impl/pos_repo_impl.dart`:

Add the import:

```dart
import 'package:amana_pos/features/pos/domain/tax_config.dart';
```

In `submitSale`, replace the parameter `String taxAmount = '0',` with:

```dart
    TaxConfig taxConfig = const TaxConfig.disabled(),
```

Remove `taxAmount: taxAmount,` from the `_buildCreateSaleDto(...)` call and replace `taxAmount: taxAmount,` with `taxConfig: taxConfig,` in both `_queueOfflineSale(...)` calls.

Replace `_queueOfflineSale`'s parameter `required String taxAmount,` with `required TaxConfig taxConfig,` and its `taxAmount: taxAmount,` forward with `taxConfig: taxConfig,`.

In `_buildCreateSaleDto`, remove the `required String taxAmount,` parameter and the `taxAmount: taxAmount,` argument.

Replace `_buildOfflineSaleDto` entirely with:

```dart
  OfflineSaleDto _buildOfflineSaleDto({
    required String clientSaleId,
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    required String discountAmount,
    required TaxConfig taxConfig,
  }) {
    final subtotal = items.fold<double>(
      0,
          (sum, item) => sum + item.lineTotal,
    );

    final discount = double.tryParse(discountAmount) ?? 0;
    // Local preview of what the server will compute at sync time.
    final computation = TaxCalculator.compute(
      taxableAmount: subtotal - discount,
      config: taxConfig,
    );

    return OfflineSaleDto(
      clientSaleId: clientSaleId,
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      discountAmount: discountAmount,
      taxAmount: computation.taxAmount.toStringAsFixed(2),
      subtotal: subtotal.toStringAsFixed(2),
      total: computation.netAmount.toStringAsFixed(2),
      createdAt: DateTime.now().toUtc(),
      items: items.map((cartItem) {
        final price = cartItem.price;
        final quantity = cartItem.quantity.toDouble();

        return OfflineSaleItemDto(
          productId: cartItem.product.id!.trim(),
          productName: cartItem.product.name ?? '',
          quantity: quantity,
          unitPrice: price.toStringAsFixed(2),
          lineTotal: (price * quantity).toStringAsFixed(2),
          productSnapshot: cartItem.product,
        );
      }).toList(),
    );
  }
```

- [ ] **Step 7: Remove the dead argument in PosBloc**

In `lib/features/pos/presentation/bloc/pos_bloc.dart`, `_onCheckoutSubmitted`, delete the line:

```dart
          taxAmount: '0',
```

(The bloc starts passing the real config in Task 6 — the default `TaxConfig.disabled()` keeps behavior identical until then.)

- [ ] **Step 8: Run the test and the analyzer**

Run: `flutter test test/features/pos/data/model/sale_payload_no_tax_test.dart`
Expected: PASS (2 tests).

Run: `flutter analyze lib/features/pos`
Expected: no new errors.

- [ ] **Step 9: Commit**

```bash
git add lib/features/pos test/features/pos/data/model/sale_payload_no_tax_test.dart
git commit -m "feat(tax): never send tax fields; queue local preview offline"
```

---

### Task 5: Parse server tax values from the sale response

**Files:**
- Modify: `lib/features/pos/data/model/pos_submit_result.dart`
- Modify: `lib/features/pos/data/datasources/pos_remote_data_source.dart`

- [ ] **Step 1: Extend PosSubmitResult**

Replace `lib/features/pos/data/model/pos_submit_result.dart` with:

```dart
class PosSubmitResult {
  final bool synced;
  final bool queued;
  final String? saleId;
  final String clientSaleId;
  final String? receiptNumber;

  // Server-computed tax snapshot (docs/TAX_SUPPORT.md §3). Null when the
  // sale was queued offline — callers fall back to the local preview.
  final String? taxAmount;
  final String? taxRate;
  final bool? taxInclusive;
  final String? netAmount;

  const PosSubmitResult._({
    required this.synced,
    required this.queued,
    required this.clientSaleId,
    this.saleId,
    this.receiptNumber,
    this.taxAmount,
    this.taxRate,
    this.taxInclusive,
    this.netAmount,
  });

  factory PosSubmitResult.synced({
    required String clientSaleId,
    String? saleId,
    String? receiptNumber,
    String? taxAmount,
    String? taxRate,
    bool? taxInclusive,
    String? netAmount,
  }) {
    return PosSubmitResult._(
      synced: true,
      queued: false,
      clientSaleId: clientSaleId,
      saleId: saleId,
      receiptNumber: receiptNumber,
      taxAmount: taxAmount,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
      netAmount: netAmount,
    );
  }

  factory PosSubmitResult.offlineQueued(String clientSaleId) {
    return PosSubmitResult._(
      synced: false,
      queued: true,
      clientSaleId: clientSaleId,
    );
  }
}
```

- [ ] **Step 2: Parse the fields in PosRemoteDataSource.createSale**

In `lib/features/pos/data/datasources/pos_remote_data_source.dart`, replace the `return PosSubmitResult.synced(...)` block with:

```dart
      return PosSubmitResult.synced(
        clientSaleId: dto.clientSaleId,
        saleId: saleData['id']?.toString(),
        receiptNumber: saleData['receipt_number']?.toString(),
        taxAmount: saleData['tax_amount']?.toString(),
        taxRate: saleData['tax_rate']?.toString(),
        taxInclusive:
            saleData['tax_inclusive'] is bool ? saleData['tax_inclusive'] as bool : null,
        netAmount: saleData['net_amount']?.toString(),
      );
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/pos`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/pos/data/model/pos_submit_result.dart lib/features/pos/data/datasources/pos_remote_data_source.dart
git commit -m "feat(tax): parse server tax snapshot from sale response"
```

---

### Task 6: PosState tax config, derived totals, and receipt snapshot

**Files:**
- Modify: `lib/features/pos/presentation/bloc/pos_state.dart`
- Modify: `lib/features/pos/presentation/bloc/pos_event.dart`
- Modify: `lib/features/pos/presentation/bloc/pos_bloc.dart`

- [ ] **Step 1: Add taxConfig + snapshot fields to PosState**

In `lib/features/pos/presentation/bloc/pos_state.dart` (it is `part of 'pos_bloc.dart'` — the import goes in the bloc file, Step 3):

After `final String? selectedShopName;` add:

```dart
  final TaxConfig taxConfig;
```

After `final bool lastSaleWasOffline;` add:

```dart
  final double lastSubtotal;
  final double lastTaxAmount;
  final String lastTaxName;
  final double lastTaxRate;
  final bool lastTaxInclusive;
```

In the constructor, after `this.selectedShopName,` add:

```dart
    this.taxConfig = const TaxConfig.disabled(),
```

and after `this.lastSaleWasOffline = false,` add:

```dart
    this.lastSubtotal = 0,
    this.lastTaxAmount = 0,
    this.lastTaxName = 'VAT',
    this.lastTaxRate = 0,
    this.lastTaxInclusive = false,
```

Replace the two getters

```dart
  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  double get total => subtotal;
```

with:

```dart
  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  /// Local tax preview (docs/TAX_SUPPORT.md §2) — server stays authoritative.
  double get taxAmount =>
      TaxCalculator.compute(taxableAmount: subtotal, config: taxConfig)
          .taxAmount;

  /// Net payable total: subtotal + tax when exclusive, subtotal when
  /// inclusive or tax disabled.
  double get total =>
      TaxCalculator.compute(taxableAmount: subtotal, config: taxConfig)
          .netAmount;
```

In `copyWith`, add parameters after `String? selectedShopName,`:

```dart
    TaxConfig? taxConfig,
```

and after `bool? lastSaleWasOffline,`:

```dart
    double? lastSubtotal,
    double? lastTaxAmount,
    String? lastTaxName,
    double? lastTaxRate,
    bool? lastTaxInclusive,
```

In the `PosState(...)` body of `copyWith`, after the `selectedShopName:` line add:

```dart
      taxConfig: taxConfig ?? this.taxConfig,
```

and after `lastSaleWasOffline: ...,` add:

```dart
      lastSubtotal: lastSubtotal ?? this.lastSubtotal,
      lastTaxAmount: lastTaxAmount ?? this.lastTaxAmount,
      lastTaxName: lastTaxName ?? this.lastTaxName,
      lastTaxRate: lastTaxRate ?? this.lastTaxRate,
      lastTaxInclusive: lastTaxInclusive ?? this.lastTaxInclusive,
```

In `props`, append after `lastSaleWasOffline,`:

```dart
    taxConfig, lastSubtotal, lastTaxAmount, lastTaxName, lastTaxRate,
    lastTaxInclusive,
```

- [ ] **Step 2: Add the PosTaxConfigChanged event**

In `lib/features/pos/presentation/bloc/pos_event.dart`, append:

```dart
class PosTaxConfigChanged extends PosEvent {
  final TaxConfig taxConfig;
  const PosTaxConfigChanged(this.taxConfig);
  @override List<Object?> get props => [taxConfig];
}
```

- [ ] **Step 3: Wire the bloc**

In `lib/features/pos/presentation/bloc/pos_bloc.dart`:

Add the import:

```dart
import 'package:amana_pos/features/pos/domain/tax_config.dart';
```

Register the handler in the constructor (after `on<PosSessionReset>(_onSessionReset);`):

```dart
    on<PosTaxConfigChanged>(_onTaxConfigChanged);
```

Add the handler (next to `_onShopSelected`):

```dart
  void _onTaxConfigChanged(PosTaxConfigChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(taxConfig: event.taxConfig));
  }
```

In `_onCheckoutSubmitted`, replace the snapshot block

```dart
    // Snapshot BEFORE clearing
    final cartSnapshot = [...state.items];
    final saleTotal = state.total;
    final salePaymentMethod = state.paymentMethod;
    final soldQuantities = state.currentSoldQuantities;
```

with:

```dart
    // Snapshot BEFORE clearing
    final cartSnapshot = [...state.items];
    final saleSubtotal = state.subtotal;
    final salePreviewTax = state.taxAmount;
    final saleTotal = state.total;
    final saleTaxConfig = state.taxConfig;
    final salePaymentMethod = state.paymentMethod;
    final soldQuantities = state.currentSoldQuantities;
```

In the `useCase.submitSale(...)` call, after `discountAmount: '0',` add:

```dart
          taxConfig: saleTaxConfig,
```

In the success branch, replace

```dart
            lastCartSnapshot: cartSnapshot,
            lastTotal: saleTotal,
            lastPaymentMethod: salePaymentMethod,
```

with:

```dart
            lastCartSnapshot: cartSnapshot,
            lastSubtotal: saleSubtotal,
            // Online sales: server values are authoritative; offline-queued
            // sales fall back to the local preview.
            lastTaxAmount:
                double.tryParse(result.taxAmount ?? '') ?? salePreviewTax,
            lastTotal: double.tryParse(result.netAmount ?? '') ?? saleTotal,
            lastTaxName: saleTaxConfig.name,
            lastTaxRate:
                double.tryParse(result.taxRate ?? '') ?? saleTaxConfig.rate,
            lastTaxInclusive: result.taxInclusive ?? saleTaxConfig.inclusive,
            lastPaymentMethod: salePaymentMethod,
```

In `_onSessionReset`, replace the emitted state with:

```dart
    emit(PosState(
      selectedShopId: state.selectedShopId,
      selectedShopName: state.selectedShopName,
      taxConfig: state.taxConfig,
    ));
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/features/pos`
Expected: no new errors.

Run: `flutter test test/features/pos`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/pos/presentation/bloc/
git commit -m "feat(tax): carry tax config in PosState, snapshot tax for receipts"
```

---

### Task 7: PosScreen dispatches the business tax config

**Files:**
- Modify: `lib/features/pos/presentation/pos_screen.dart`

- [ ] **Step 1: Add imports**

In `lib/features/pos/presentation/pos_screen.dart` add:

```dart
import 'package:amana_pos/features/pos/domain/tax_config.dart';
```

(`auth_bloc.dart` and `business_bloc.dart` are already imported.)

- [ ] **Step 2: Add the dispatch helper to _PosScreenState**

Add this method to `_PosScreenState` (next to `_loadDashboardSummary`):

```dart
  void _dispatchTaxConfig() {
    if (!mounted) return;
    // BusinessBloc has the freshest copy after a refresh; AuthBloc's
    // defaultBusiness covers cold offline starts (loaded from SQLite cache).
    final businessList = context.read<BusinessBloc>().state.businessList;
    final business = (businessList != null && businessList.isNotEmpty)
        ? businessList.first
        : context.read<AuthBloc>().state.defaultBusiness;
    context
        .read<PosBloc>()
        .add(PosTaxConfigChanged(TaxConfig.fromBusiness(business)));
  }
```

- [ ] **Step 3: Dispatch on init**

In `initState`, inside the existing `addPostFrameCallback`, add a call before `_autoSelectShop();`:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchTaxConfig();
      _autoSelectShop();
      _loadDashboardSummary();
    });
```

- [ ] **Step 4: Re-dispatch when business data changes**

In `build`, wrap the existing `BlocListener<PosBloc, PosState>` in a `MultiBlocListener` so settings changes (e.g. owner toggles tax, then the list refreshes) propagate:

```dart
    return MultiBlocListener(
      listeners: [
        BlocListener<BusinessBloc, BusinessState>(
          listenWhen: (prev, curr) => prev.businessList != curr.businessList,
          listener: (_, __) => _dispatchTaxConfig(),
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.defaultBusiness != curr.defaultBusiness,
          listener: (_, __) => _dispatchTaxConfig(),
        ),
        BlocListener<PosBloc, PosState>(
          listenWhen: (prev, curr) =>
              prev.submitStatus != curr.submitStatus ||
              prev.submitError != curr.submitError,
          listener: (context, state) {
            // ... existing listener body unchanged ...
          },
        ),
      ],
      child: Scaffold(
        // ... existing Scaffold unchanged ...
      ),
    );
```

Move the existing PosBloc `listenWhen`/`listener` content into the third listener verbatim; the `child:` stays the existing `Scaffold`.

- [ ] **Step 5: Verify**

Run: `flutter analyze lib/features/pos`
Expected: no new errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/pos/presentation/pos_screen.dart
git commit -m "feat(tax): feed business tax config into PosBloc"
```

---

### Task 8: Cart totals show the tax preview

`TotalsSection` is shared by the mobile expanded cart and the desktop cart panel — one change covers both.

**Files:**
- Modify: `lib/features/cart/presentation/totals_section.dart`

- [ ] **Step 1: Render the three modes**

In `lib/features/cart/presentation/totals_section.dart`, replace the inner `Column` (the one with the two `TotalRow`s and `_DashedDivider`) with:

```dart
        child: Column(
          children: [
            if (state.taxConfig.isActive && state.taxAmount > 0 &&
                !state.taxConfig.inclusive) ...[
              // Exclusive: Subtotal → Tax (VAT 15%) → Total
              TotalRow(
                label: context.tr.subtotal,
                value: money(state.subtotal),
              ),
              const SizedBox(height: AppDims.s3),
              TotalRow(
                label: context.tr.taxWithRate(
                  state.taxConfig.name,
                  state.taxConfig.rateLabel,
                ),
                value: money(state.taxAmount),
              ),
              const SizedBox(height: AppDims.s3),
              _DashedDivider(color: colors.border),
              const SizedBox(height: AppDims.s3),
              TotalRow(
                label: context.tr.total,
                value: money(state.total),
                isTotal: true,
              ),
            ] else if (state.taxConfig.isActive && state.taxAmount > 0) ...[
              // Inclusive: Total (incl. VAT 15%) → Tax included
              TotalRow(
                label: context.tr.totalInclTax(
                  state.taxConfig.name,
                  state.taxConfig.rateLabel,
                ),
                value: money(state.total),
                isTotal: true,
              ),
              const SizedBox(height: AppDims.s3),
              _DashedDivider(color: colors.border),
              const SizedBox(height: AppDims.s3),
              TotalRow(
                label: context.tr.taxIncluded,
                value: money(state.taxAmount),
              ),
            ] else ...[
              // Tax disabled — unchanged layout
              TotalRow(
                label: context.tr.subtotal,
                value: money(state.subtotal),
              ),
              const SizedBox(height: AppDims.s3),
              _DashedDivider(color: colors.border),
              const SizedBox(height: AppDims.s3),
              TotalRow(
                label: context.tr.total,
                value: money(state.total),
                isTotal: true,
              ),
            ],
          ],
        ),
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/features/cart`
Expected: no new errors.

Run: `flutter test test/features/cart`
Expected: PASS (existing desktop cart panel test still green — tax disabled by default keeps the old layout).

- [ ] **Step 3: Commit**

```bash
git add lib/features/cart/presentation/totals_section.dart
git commit -m "feat(tax): show tax line in cart totals (exclusive + inclusive)"
```

---

### Task 9: Receipt sheet shows tax (rendered + shared text)

**Files:**
- Modify: `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`
- Modify: `lib/features/cart/presentation/expanded_cart.dart` (callsite)
- Modify: `lib/features/cart/presentation/desktop_cart_panel.dart` (callsite)

- [ ] **Step 1: Add tax parameters to SaleReceiptSheet**

In `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`, add fields after `final String businessName;`:

```dart
  final double subtotal;
  final double taxAmount;
  final String taxName;
  final String taxRateLabel;
  final bool taxInclusive;
```

Add to the constructor after `required this.businessName,`:

```dart
    this.subtotal = 0,
    this.taxAmount = 0,
    this.taxName = 'VAT',
    this.taxRateLabel = '0',
    this.taxInclusive = false,
```

Mirror the same five optional parameters in the static `show(...)` method signature and pass them through to the `SaleReceiptSheet(...)` constructor inside it:

```dart
  static void show(
    BuildContext context, {
    required String? receiptNumber,
    required String clientSaleId,
    required List<PosCartItem> items,
    required double total,
    required String paymentMethod,
    required bool isOffline,
    required String businessName,
    double subtotal = 0,
    double taxAmount = 0,
    String taxName = 'VAT',
    String taxRateLabel = '0',
    bool taxInclusive = false,
  }) {
    showAdaptivePanel(
      context,
      desktopWidth: 360,
      builder: (_) => SaleReceiptSheet(
        receiptNumber: receiptNumber,
        clientSaleId: clientSaleId,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        isOffline: isOffline,
        businessName: businessName,
        subtotal: subtotal,
        taxAmount: taxAmount,
        taxName: taxName,
        taxRateLabel: taxRateLabel,
        taxInclusive: taxInclusive,
      ),
    );
  }
```

- [ ] **Step 2: Add tax lines to the shared text receipt**

In `_buildReceiptText()`, replace:

```dart
    sb.writeln('─────────────────────────');
    sb.writeln('TOTAL:   ${AppFormat.moneyWithUnit(total)}');
```

with:

```dart
    sb.writeln('─────────────────────────');
    if (taxAmount > 0 && !taxInclusive) {
      sb.writeln('Subtotal: ${AppFormat.moneyWithUnit(subtotal)}');
      sb.writeln('Tax ($taxName $taxRateLabel%): ${AppFormat.moneyWithUnit(taxAmount)}');
    }
    sb.writeln('TOTAL:   ${AppFormat.moneyWithUnit(total)}');
    if (taxAmount > 0 && taxInclusive) {
      sb.writeln('Incl. $taxName $taxRateLabel%: ${AppFormat.moneyWithUnit(taxAmount)}');
    }
```

- [ ] **Step 3: Add tax rows to the rendered sheet**

In `build`, directly before the `// Total row` `Padding` widget, insert:

```dart
                  // Tax breakdown (exclusive mode)
                  if (taxAmount > 0 && !taxInclusive) ...[
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppDims.s1),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr.subtotal,
                                  style: AppTextStyles.bs100(context).copyWith(
                                      color: colors.textSecondary)),
                              Text(AppFormat.moneyWithUnit(subtotal),
                                  style: AppTextStyles.bs200(context).copyWith(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: AppDims.s2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  context.tr.taxWithRate(
                                      taxName, taxRateLabel),
                                  style: AppTextStyles.bs100(context).copyWith(
                                      color: colors.textSecondary)),
                              Text(AppFormat.moneyWithUnit(taxAmount),
                                  style: AppTextStyles.bs200(context).copyWith(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDims.s3),
                  ],
```

And directly after the `// Total row` `Padding` widget (before `const SizedBox(height: AppDims.s6),`), insert:

```dart
                  // Tax included note (inclusive mode)
                  if (taxAmount > 0 && taxInclusive) ...[
                    const SizedBox(height: AppDims.s2),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppDims.s1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${context.tr.totalInclTax(taxName, taxRateLabel)} · ${context.tr.taxIncluded}',
                              style: AppTextStyles.sm100(context)
                                  .copyWith(color: colors.textHint)),
                          Text(AppFormat.moneyWithUnit(taxAmount),
                              style: AppTextStyles.bs100(context).copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
```

- [ ] **Step 4: Pass snapshot values from both callsites**

In `lib/features/cart/presentation/expanded_cart.dart`, `_showReceiptSheet`, add to the `SaleReceiptSheet.show(...)` call after `businessName: businessName,`:

```dart
      subtotal: state.lastSubtotal,
      taxAmount: state.lastTaxAmount,
      taxName: state.lastTaxName,
      taxRateLabel: formatTaxRate(state.lastTaxRate),
      taxInclusive: state.lastTaxInclusive,
```

and add the import:

```dart
import 'package:amana_pos/features/pos/domain/tax_config.dart';
```

Make the identical two changes in `lib/features/cart/presentation/desktop_cart_panel.dart`.

- [ ] **Step 5: Verify**

Run: `flutter analyze lib/features/pos lib/features/cart`
Expected: no new errors.

Run: `flutter test test/features/cart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/pos/presentation/widgets/sale_receipt_sheet.dart lib/features/cart/presentation/expanded_cart.dart lib/features/cart/presentation/desktop_cart_panel.dart
git commit -m "feat(tax): show tax on sale receipt sheet and shared text"
```

---

### Task 10: Sales history parses and shows the tax snapshot

**Files:**
- Modify: `lib/features/sales_history/data/models/sales_list_response_dto.dart`
- Modify: `lib/features/sales_history/data/models/sale_history_item.dart`
- Modify: `lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart`

- [ ] **Step 1: Parse tax fields in SaleDto**

In `lib/features/sales_history/data/models/sales_list_response_dto.dart`, class `SaleDto`:

Add fields after `final String netAmount;`:

```dart
  final String taxAmount;
  final String taxRate;
  final bool taxInclusive;
```

Add to the constructor after `required this.netAmount,`:

```dart
    this.taxAmount = '0',
    this.taxRate = '0',
    this.taxInclusive = false,
```

In `fromJson`, after `netAmount: json['net_amount']?.toString() ?? '0',`:

```dart
      taxAmount: json['tax_amount']?.toString() ?? '0',
      taxRate: json['tax_rate']?.toString() ?? '0',
      taxInclusive: json['tax_inclusive'] == true,
```

- [ ] **Step 2: Carry tax on SaleHistoryItem**

In `lib/features/sales_history/data/models/sale_history_item.dart`, class `SaleHistoryItem`:

Add fields after `final double total;`:

```dart
  // Historical snapshot from the sale (docs/TAX_SUPPORT.md §3) — never the
  // business's live settings. 0 for pre-tax sales.
  final double taxAmount;
  final double taxRate;
  final bool taxInclusive;
```

Add to the constructor after `required this.total,`:

```dart
    this.taxAmount = 0,
    this.taxRate = 0,
    this.taxInclusive = false,
```

In `fromDto`, after `total: total,`:

```dart
      taxAmount: _parseAmount(dto.taxAmount) ?? 0,
      taxRate: _parseAmount(dto.taxRate) ?? 0,
      taxInclusive: dto.taxInclusive,
```

In `fromOfflineRow`, after `total: _parseAmount(row['total']?.toString()) ?? 0,`:

```dart
        // Local preview stored at queue time; the server recomputes on sync.
        taxAmount: _parseAmount(row['tax_amount']?.toString()) ?? 0,
```

In `copyWith`, after `total: total,`:

```dart
    taxAmount: taxAmount,
    taxRate: taxRate,
    taxInclusive: taxInclusive,
```

- [ ] **Step 3: Show the tax line in the sale detail sheet**

In `lib/features/sales_history/presentation/widgets/sale_detail_sheet.dart`, class `_ItemsCard`, in the `Column.children`, insert between the items `Divider` and `_TotalRow(total: item.total),`:

```dart
            if (item.taxAmount > 0) ...[
              _TaxLineRow(item: item),
              Divider(
                height: 1,
                color: colors.border.withValues(alpha: 0.6),
              ),
            ],
```

Add this widget at the end of the file (after `_TotalRow`):

```dart
class _TaxLineRow extends StatelessWidget {
  const _TaxLineRow({required this.item});

  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final label = item.taxInclusive
        ? context.tr.taxIncluded
        : item.taxRate > 0
            ? context.tr.taxWithRatePercent(
                item.taxRate % 1 == 0
                    ? item.taxRate.toStringAsFixed(0)
                    : item.taxRate.toStringAsFixed(2))
            : context.tr.taxLabel;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Text(
            AppFormat.moneyWithUnit(item.taxAmount),
            textDirection: ui.TextDirection.ltr,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/features/sales_history`
Expected: no new errors.

Run: `flutter test test/features/sales_history`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/sales_history
git commit -m "feat(tax): show tax snapshot in sales history detail"
```

---

### Task 11: Receipt PDF includes the tax line

**Files:**
- Modify: `lib/features/sales_history/services/sale_receipt_pdf_service.dart`

- [ ] **Step 1: Add the tax label string**

In `lib/features/sales_history/services/sale_receipt_pdf_service.dart`, class `SaleReceiptPdfStrings`:

Add a field next to `final String totalUpper;`:

```dart
  final String taxUpper;
```

Add it to the constructor (`required this.taxUpper,` next to `required this.totalUpper,`).

In `fromContext`, next to the `totalUpper:` assignment:

```dart
      taxUpper: languageCode == 'ar' ? tr.taxLabel : 'TAX',
```

- [ ] **Step 2: Render a tax row before the total**

In `_totalRow(...)` (around line 388), wrap the existing `pw.Row` in a `pw.Column` with a tax row above it. Replace the method body with:

```dart
  static pw.Widget _totalRow(
      SaleHistoryItem item,
      SaleReceiptPdfStrings strings,
      ) {
    return pw.Column(
      children: [
        if (item.taxAmount > 0) ...[
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: strings.isRtl
                      ? pw.CrossAxisAlignment.end
                      : pw.CrossAxisAlignment.start,
                  children: [
                    _t(
                      strings.taxUpper,
                      color: _muted,
                      size: 7.5,
                      bold: true,
                      spacing: strings.isRtl ? 0 : 1.0,
                      strings: strings,
                    ),
                  ],
                ),
              ),
              _ltrText(
                AppFormat.moneyWithUnit(item.taxAmount),
                color: _muted,
                size: 10,
                bold: true,
                align: pw.TextAlign.right,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: strings.isRtl
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: [
                  _t(
                    strings.totalUpper,
                    color: _muted,
                    size: 7.5,
                    bold: true,
                    spacing: strings.isRtl ? 0 : 1.0,
                    strings: strings,
                  ),
                  pw.SizedBox(height: 3),
                  _t(
                    strings.paidVia(strings.paymentLabel(item.paymentLabel)),
                    color: _muted,
                    size: 8.5,
                    strings: strings,
                  ),
                ],
              ),
            ),
            _ltrText(
              AppFormat.moneyWithUnit(item.total),
              color: _accentGreen,
              size: 26,
              bold: true,
              align: pw.TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/sales_history`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/sales_history/services/sale_receipt_pdf_service.dart
git commit -m "feat(tax): include tax line on receipt PDF"
```

---

### Task 12: Reports "Tax Collected" KPI

**Files:**
- Modify: `lib/features/sales_history/data/models/sales_report_dto.dart`
- Modify: `lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart`
- Test: `test/features/sales_history/data/models/sales_report_dto_test.dart` (extend)

- [ ] **Step 1: Write the failing test**

In `test/features/sales_history/data/models/sales_report_dto_test.dart`, add `'total_tax_collected': 750.0,` to the existing `'summary'` map, and add this test inside the group:

```dart
    test('parses total tax collected', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.summary.totalTaxCollected, 750.0);
    });

    test('missing total_tax_collected defaults to 0', () {
      final report = SalesReportDto.fromJson({'summary': <String, dynamic>{}})
          .toDomain();
      expect(report.summary.totalTaxCollected, 0.0);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/sales_history/data/models/sales_report_dto_test.dart`
Expected: FAIL — `totalTaxCollected` not defined.

- [ ] **Step 3: Add the field**

In `lib/features/sales_history/data/models/sales_report_dto.dart`, class `SalesReportSummary`:

Add after `final double netSalesAmount;`:

```dart
  final double totalTaxCollected;
```

Add to the constructor after `required this.netSalesAmount,`:

```dart
    this.totalTaxCollected = 0,
```

In `toDomain()`, after the `netSalesAmount:` line:

```dart
        totalTaxCollected: (_summaryDouble(summaryJson, 'total_tax_collected')),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/sales_history/data/models/sales_report_dto_test.dart`
Expected: PASS.

- [ ] **Step 5: Add the KPI card**

In `lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart`, in the `cards` list, insert after the "Net Sales" `_KpiCard` (the one with `label: context.tr.reportsNetSales`) and before the refunds card:

```dart
      if (summary.totalTaxCollected > 0)
        _KpiCard(
          label: context.tr.taxCollected,
          value: AppFormat.moneyWithUnit(summary.totalTaxCollected),
          forceValueLtr: true,
          background: AppColors.warningLight,
          valueColor: AppColors.warning,
          labelColor: AppColors.warning,
          icon: SolarIconsOutline.documentText,
        ),
```

(Hidden when zero/disabled — per spec §5.)

- [ ] **Step 6: Verify**

Run: `flutter analyze lib/features/sales_history`
Expected: no new errors.

Run: `flutter test test/features/sales_history`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/sales_history
git commit -m "feat(tax): add Tax Collected KPI to sales reports"
```

---

### Task 13: Read-only tax card on the business detail screen

**Files:**
- Modify: `lib/features/business/presentation/widgets/info_section.dart`

- [ ] **Step 1: Add the tax row**

In `lib/features/business/presentation/widgets/info_section.dart`:

Add the import:

```dart
import 'package:amana_pos/features/pos/domain/tax_config.dart';
```

In the `rows` list, insert before the `bizShopsLabel` `_InfoItem`:

```dart
      _InfoItem(
        icon: Icons.percent_rounded,
        label: context.tr.taxLabel,
        value: _taxSummary(context, business),
      ),
```

Add this helper at the bottom of the file (top-level function):

```dart
String _taxSummary(BuildContext context, BusinessData business) {
  final config = TaxConfig.fromBusiness(business);
  if (!config.isActive) return context.tr.taxDisabled;
  final mode = config.inclusive
      ? context.tr.pricesIncludeTax
      : context.tr.pricesExcludeTax;
  return '${config.name} · ${config.rateLabel}% · $mode';
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/features/business`
Expected: no new errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/business/presentation/widgets/info_section.dart
git commit -m "feat(tax): show read-only tax settings on business detail"
```

---

### Task 14: Full verification

- [ ] **Step 1: Analyzer over the whole repo**

Run: `flutter analyze`
Expected: no **new** issues versus the baseline before this work (run `git stash && flutter analyze && git stash pop` to compare if unsure).

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all tests pass, including the new tax_config, business DTO, payload, and report DTO tests.

- [ ] **Step 3: Manual smoke checklist (run the app if a device/simulator is available)**

1. Business with `tax_enabled: false` → cart shows only Subtotal/Total, receipt unchanged, no tax row anywhere.
2. Business with VAT 15% exclusive → cart shows Subtotal / Tax (VAT 15%) / Total; checkout button charges the net total; receipt shows the breakdown.
3. Airplane mode → make a sale → receipt shows locally computed tax; pending-sync screen shows the Tax line; sync → server values appear in sales history.

- [ ] **Step 4: Final commit (if any stragglers)**

```bash
git status --short
# commit anything intentionally remaining
```

---

## Self-review notes (already applied)

- **Spec coverage:** §1 data layer → Tasks 1–2; §2 domain → Task 2; §3 golden rule → Task 4; §4 POS flow → Tasks 5–7; §5 UI → Tasks 3, 8–13; §6 offline → Tasks 4, 10 (pending-sync screen needs no change — it already renders `tax_amount` when > 0); §7 edge cases → defaults in Tasks 1–2, 10; §8 testing → Tasks 1, 2, 4, 12 + full run in Task 14.
- **Type consistency:** `TaxConfig` / `TaxCalculator.compute` / `TaxComputation` / `formatTaxRate` / `PosTaxConfigChanged` / `state.taxConfig` / `state.taxAmount` / `state.total` / `last*` snapshot names are used identically across Tasks 2, 4, 6, 7, 8, 9.
- **Order matters:** Task 3 (l10n) must land before Tasks 8–13 (they reference `context.tr.tax*` keys). Task 2 before 4/6/7/13. Task 6 before 9.
