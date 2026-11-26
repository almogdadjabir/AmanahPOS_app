import 'package:amana_pos/features/sales_history/data/models/sales_list_response_dto.dart';

enum SaleHistoryStatus {
  pending,
  completed,
  cancelled,
  refunded,
  partialRefund,
  failed,
  unknown;

  static SaleHistoryStatus fromString(String? v) => switch (v) {
    'completed' => completed,
    'cancelled' => cancelled,
    'refunded' => refunded,
    'partial_refund' => partialRefund,
    'pending' => pending,
    'failed' => failed,
    _ => unknown,
  };

  String get label => switch (this) {
    completed => 'Completed',
    cancelled => 'Cancelled',
    refunded => 'Refunded',
    partialRefund => 'Part. refund',
    pending => 'Pending sync',
    failed => 'Sync failed',
    unknown => 'Unknown',
  };
}

class SaleHistoryRefund {
  final String reference;
  final double total;
  final DateTime createdAt;

  /// `pending` (not confirmed by the server yet), `synced`, or `rejected`
  /// (voided: the server refused it, e.g. `refund_exceeds_sold`; the money
  /// is NOT counted as returned).
  final String syncState;
  final String? errorMessage;

  /// How the money went back (`cash`, `bankak`...). Empty when unknown.
  final String method;

  const SaleHistoryRefund({
    required this.reference,
    required this.total,
    required this.createdAt,
    this.syncState = 'synced',
    this.errorMessage,
    this.method = '',
  });

  bool get isRejected => syncState == 'rejected';
  bool get isPending => syncState == 'pending';

  factory SaleHistoryRefund.fromDto(SaleRefundDto dto) => SaleHistoryRefund(
    reference: dto.reference,
    total: double.tryParse(dto.total) ?? 0,
    createdAt: dto.createdAt,
  );
}

/// One payment part of a sale (a split sale has several).
class SaleHistoryPayment {
  final String method;
  final double amount;

  const SaleHistoryPayment({required this.method, required this.amount});
}

class SaleHistoryLineItem {
  /// Server id of the sale line. Empty for offline (not yet synced) sales.
  final String lineId;
  final bool isCustom;
  final double returnedQuantity;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  /// Discount taken off this line (money). 0 when none.
  final double discount;

  const SaleHistoryLineItem({
    this.lineId = '',
    this.isCustom = false,
    this.returnedQuantity = 0,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.discount = 0,
  });

  /// What can still be returned on this line.
  double get returnableQuantity =>
      (quantity - returnedQuantity).clamp(0, double.infinity).toDouble();

  factory SaleHistoryLineItem.fromDto(SaleItemDto dto) => SaleHistoryLineItem(
    lineId: dto.id,
    isCustom: dto.isCustom,
    returnedQuantity: dto.returnedQuantityDouble,
    productId: dto.productId,
    productName: dto.productName,
    quantity: dto.quantityDouble,
    unitPrice: dto.unitPriceDouble,
    subtotal: dto.subtotalDouble,
  );
}

class SaleHistoryItem {
  final String? id;
  final String clientSaleId;
  final String? receiptNumber;
  final String? shopId;
  final String? shopName;
  final String? customerId;
  final String? customerName;
  final String paymentMethod;

  final double total;
  // Historical snapshot from the sale (docs/TAX_SUPPORT.md §3) — never the
  // business's live settings. 0 for pre-tax sales.
  final double taxAmount;
  final double taxRate;
  final bool taxInclusive;
  final int itemCount;
  final SaleHistoryStatus status;
  final DateTime createdAt;
  final bool isOfflinePending;
  final String? offlineErrorMessage;
  final List<SaleHistoryLineItem> items;
  final String? cashierName;
  final double discount;
  final String? notes;
  final String? bankakSnapshot;
  final List<SaleHistoryRefund> refunds;

  /// Sale subtotal before discount and tax. 0 when the source has none.
  final double subtotal;
  final String taxName;
  final List<SaleHistoryPayment> payments;

  const SaleHistoryItem({
    required this.id,
    required this.clientSaleId,
    required this.receiptNumber,
    required this.shopId,
    required this.shopName,
    required this.customerId,
    required this.customerName,
    required this.paymentMethod,
    required this.total,
    this.taxAmount = 0,
    this.taxRate = 0,
    this.taxInclusive = false,
    required this.itemCount,
    required this.status,
    required this.createdAt,
    required this.isOfflinePending,
    required this.offlineErrorMessage,
    required this.items,
    this.cashierName,
    this.discount = 0,
    this.notes,
    this.bankakSnapshot,
    this.refunds = const [],
    this.subtotal = 0,
    this.taxName = '',
    this.payments = const [],
  });

  factory SaleHistoryItem.fromDto(SaleDto dto) {
    final total =
        _parseAmount(dto.netAmount) ?? _parseAmount(dto.totalAmount) ?? 0.0;

    return SaleHistoryItem(
      id: dto.id,
      clientSaleId: dto.clientSaleId ?? dto.id,
      receiptNumber: dto.receiptNumber,
      shopId: dto.shopId,
      shopName: dto.shopName,
      customerId: dto.customerId,
      customerName: dto.customerName,
      paymentMethod: dto.paymentMethod,
      total: total,
      taxAmount: _parseAmount(dto.taxAmount) ?? 0,
      taxRate: _parseAmount(dto.taxRate) ?? 0,
      taxInclusive: dto.taxInclusive,
      itemCount: dto.items.length,
      status: SaleHistoryStatus.fromString(dto.status),
      createdAt: dto.createdAt,
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: dto.items.map(SaleHistoryLineItem.fromDto).toList(),
      cashierName: dto.cashierName,
      discount: double.tryParse(dto.discountAmount) ?? 0,
      notes: dto.notes,
      bankakSnapshot: dto.bankakSnapshot,
      refunds: dto.refunds.map(SaleHistoryRefund.fromDto).toList(),
    );
  }

  String get displayRef => (receiptNumber?.isNotEmpty == true)
      ? receiptNumber!
      : 'TMP-${clientSaleId.substring(0, clientSaleId.length.clamp(0, 8)).toUpperCase()}';

  String get paymentLabel => switch (paymentMethod) {
    'cash' => 'Cash',
    'bankak' => 'Bankak',
    'card' => 'Card',
    'bank_transfer' => 'Bank Transfer',
    'mobile_wallet' => 'Mobile Wallet',
    _ => paymentMethod,
  };

  /// A sale can be returned when it is completed (or partly returned), even
  /// while its own sync is pending: the refund queues behind the sale.
  bool get canBeReturned =>
      id != null &&
      (status == SaleHistoryStatus.completed ||
          status == SaleHistoryStatus.partialRefund);

  double get refundedTotal =>
      refunds.where((r) => !r.isRejected).fold(0.0, (a, r) => a + r.total);

  bool get hasRejectedRefund => refunds.any((r) => r.isRejected);

  SaleHistoryItem copyWith({SaleHistoryStatus? status}) => SaleHistoryItem(
    id: id,
    clientSaleId: clientSaleId,
    receiptNumber: receiptNumber,
    shopId: shopId,
    shopName: shopName,
    customerId: customerId,
    customerName: customerName,
    paymentMethod: paymentMethod,
    total: total,
    taxAmount: taxAmount,
    taxRate: taxRate,
    taxInclusive: taxInclusive,
    itemCount: itemCount,
    status: status ?? this.status,
    createdAt: createdAt,
    isOfflinePending: isOfflinePending,
    offlineErrorMessage: offlineErrorMessage,
    items: items,
    cashierName: cashierName,
    discount: discount,
    notes: notes,
    bankakSnapshot: bankakSnapshot,
    refunds: refunds,
    subtotal: subtotal,
    taxName: taxName,
    payments: payments,
  );

  /// Returns null instead of 0.0 so callers can chain fallbacks.
  static double? _parseAmount(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final v = double.tryParse(raw);
    return (v == null || v == 0.0) ? null : v;
  }
}

class SalesHistoryPage {
  final List<SaleHistoryItem> items;
  final bool hasMore;

  /// Server count for the current filters (sales not yet synced are extra).
  final int? totalCount;
  const SalesHistoryPage({
    required this.items,
    required this.hasMore,
    this.totalCount,
  });
}
