import 'tax_config.dart';

/// Thrown by `SaleService.createSale` before anything is written.
class SaleValidationException implements Exception {
  const SaleValidationException(this.message);

  final String message;

  @override
  String toString() => 'SaleValidationException: $message';
}

/// One cart line handed to `SaleService.createSale`. Money and quantity are
/// decimal strings (never doubles).
class SaleDraftLine {
  /// A catalog product line (decrements local stock).
  const SaleDraftLine.product({
    required String this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.unitCost,
    this.discount = '0',
    this.snapshot = const {},
  }) : isCustom = false,
       note = null;

  /// A free amount (keypad) line: no product, no stock effect.
  const SaleDraftLine.custom({
    required String name,
    required this.unitPrice,
    this.quantity = '1',
  }) : productId = null,
       productName = name,
       isCustom = true,
       unitCost = null,
       discount = '0',
       note = name,
       snapshot = const {};

  final String? productId;
  final String productName;
  final bool isCustom;
  final String quantity;
  final String unitPrice;
  final String? unitCost;
  final String discount;
  final String? note;

  /// Product fields at sale time, kept with the line so it renders after the
  /// product is edited or deleted.
  final Map<String, dynamic> snapshot;
}

class SalePaymentPart {
  const SalePaymentPart({required this.method, required this.amount});

  final String method;

  /// Decimal string, 2 decimals once stored.
  final String amount;

  Map<String, dynamic> toJson() => {'method': method, 'amount': amount};
}

class SaleDraft {
  const SaleDraft({
    required this.shopId,
    required this.paymentMethod,
    required this.lines,
    this.customerId,
    this.discountAmount = '0',
    this.taxConfig = const TaxConfig.disabled(),
    this.payments,
  });

  final String shopId;
  final String? customerId;

  /// Used when [payments] is null: one part of the full net amount.
  final String paymentMethod;
  final List<SaleDraftLine> lines;
  final String discountAmount;
  final TaxConfig taxConfig;

  /// Explicit parts (split payment). Must add up to the net (±0.01).
  final List<SalePaymentPart>? payments;
}

class SaleLine {
  const SaleLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.isCustom,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.discount,
    required this.lineTotal,
    required this.note,
    required this.snapshot,
  });

  final String id;
  final String? productId;
  final String productName;
  final bool isCustom;
  final String quantity;
  final String unitPrice;
  final String? unitCost;
  final String discount;
  final String lineTotal;
  final String? note;
  final Map<String, dynamic> snapshot;
}

/// A sale as stored locally (`sales` + `sale_items` + `sale_payments`).
class Sale {
  const Sale({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.cashierId,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    required this.netAmount,
    required this.taxRate,
    required this.taxInclusive,
    required this.taxName,
    required this.receiptNumber,
    required this.localReceiptNumber,
    required this.occurredAt,
    required this.version,
    required this.syncState,
    required this.warnings,
    required this.items,
    required this.payments,
    this.deviceId,
    this.receivedAt,
  });

  final String id;
  final String shopId;
  final String? deviceId;

  /// Server receive time (pulled sales only).
  final DateTime? receivedAt;
  final String? customerId;
  final String? cashierId;
  final String status;
  final String paymentMethod;
  final String subtotal;
  final String discount;
  final String taxAmount;
  final String netAmount;
  final String taxRate;
  final bool taxInclusive;
  final String taxName;

  /// Server receipt number; null until the sale is synced.
  final String? receiptNumber;
  final String? localReceiptNumber;
  final DateTime occurredAt;
  final int? version;

  /// `pending` | `synced` | `rejected`.
  final String syncState;
  final List<String> warnings;
  final List<SaleLine> items;
  final List<SalePaymentPart> payments;

  /// What a receipt shows: the server number once known, else the local one.
  String? get displayReceiptNumber => receiptNumber ?? localReceiptNumber;
}
