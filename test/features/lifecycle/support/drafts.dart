import 'dart:math';

import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/features/pos/domain/sale_math.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';

import 'lifecycle_device.dart';

const _vatEx = TaxConfig(
  enabled: true,
  name: 'VAT',
  rate: 15,
  inclusive: false,
);
const _vatIn = TaxConfig(enabled: true, name: 'VAT', rate: 15, inclusive: true);

/// Quantities chosen so no line lands on a half-cent tie (see report: the
/// BE's DecimalField rounding mode for ties is not pinned by these tests).
const _qty = ['1', '2', '3', '0.5', '1.2', '0.333', '4'];

/// A random but reproducible cart; kinds cycle so every flavour is covered.
SaleDraft randomDraft(Random r, int i) {
  CatalogItem pick() => kCatalog[r.nextInt(kCatalog.length)];
  SaleDraftLine line(CatalogItem c, {String discount = '0'}) =>
      SaleDraftLine.product(
        productId: c.id,
        productName: c.name,
        quantity: _qty[r.nextInt(_qty.length)],
        unitPrice: c.price,
        discount: discount,
        snapshot: {'id': c.id, 'name': c.name},
      );
  final lines = [for (var k = 0; k <= r.nextInt(3); k++) line(pick())];
  switch (i % 7) {
    case 0: // single cash payment
      return SaleDraft(shopId: kShop, paymentMethod: 'cash', lines: lines);
    case 1: // tax exclusive
      return SaleDraft(
        shopId: kShop,
        paymentMethod: 'bankak',
        lines: lines,
        taxConfig: _vatEx,
      );
    case 2: // tax inclusive
      return SaleDraft(
        shopId: kShop,
        paymentMethod: 'cash',
        lines: lines,
        taxConfig: _vatIn,
      );
    case 3: // sale discount + line discount
      return SaleDraft(
        shopId: kShop,
        paymentMethod: 'card',
        lines: [
          ...lines,
          line(kCatalog[0], discount: '0.25'),
        ],
        discountAmount: '0.40',
      );
    case 4: // custom (keypad) line next to products
      return SaleDraft(
        shopId: kShop,
        paymentMethod: 'cash',
        lines: [
          ...lines,
          const SaleDraftLine.custom(name: 'Service', unitPrice: '3.25'),
        ],
      );
    case 5: // negative stock: Oil starts at 0 and Rice at 3
      return SaleDraft(
        shopId: kShop,
        paymentMethod: 'cash',
        lines: [line(kCatalog[3]), line(kCatalog[2])],
      );
    default: // split payment, parts computed like the payment sheet does
      final draft = SaleDraft(
        shopId: kShop,
        paymentMethod: 'split',
        lines: lines,
        taxConfig: _vatEx,
      );
      final net = SaleMath.compute(
        lines: [
          for (final l in lines)
            SaleMathLine(
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              discount: l.discount,
            ),
        ],
        discount: '0',
        taxRate: SaleMath.taxRateOf(_vatEx),
        taxInclusive: false,
      ).netAmount;
      final c = cents(net);
      final cash = c ~/ BigInt.two;
      String fmt(BigInt v) =>
          '${v ~/ BigInt.from(100)}.${(v % BigInt.from(100)).toString().padLeft(2, '0')}';
      return SaleDraft(
        shopId: draft.shopId,
        paymentMethod: 'split',
        lines: lines,
        taxConfig: _vatEx,
        payments: [
          SalePaymentPart(method: 'cash', amount: fmt(cash)),
          SalePaymentPart(method: 'card', amount: fmt(c - cash)),
        ],
      );
  }
}

/// Per product: Σ sold quantity (units of 0.001) of non-custom lines.
Map<String, BigInt> soldBy(SaleDraft d) {
  final out = <String, BigInt>{};
  for (final l in d.lines) {
    if (l.isCustom) continue;
    out[l.productId!] =
        (out[l.productId!] ?? BigInt.zero) + Decimal3.parse(l.quantity);
  }
  return out;
}
