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


class SaleHistoryLineItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const SaleHistoryLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleHistoryLineItem.fromDto(SaleItemDto dto) => SaleHistoryLineItem(
    productId: dto.productId,
    productName: dto.productName,
    quantity: dto.quantityDouble,
    unitPrice: dto.unitPriceDouble,
    subtotal: dto.subtotalDouble,
  );

  factory SaleHistoryLineItem.fromOfflineRow(Map<String, dynamic> row) =>
      SaleHistoryLineItem(
        productId: row['product_id']?.toString()  ?? '',
        productName: row['product_name']?.toString() ?? 'Item',
        quantity: (row['quantity']   as num?)?.toDouble() ?? 1,
        unitPrice: double.tryParse(row['unit_price']?.toString() ?? '') ?? 0,
        subtotal: double.tryParse(row['line_total']?.toString() ?? '') ?? 0,
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
  final int itemCount;
  final SaleHistoryStatus status;
  final DateTime createdAt;
  final bool isOfflinePending;
  final String? offlineErrorMessage;
  final List<SaleHistoryLineItem> items;

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
    required this.itemCount,
    required this.status,
    required this.createdAt,
    required this.isOfflinePending,
    required this.offlineErrorMessage,
    required this.items,
  });


  factory SaleHistoryItem.fromDto(SaleDto dto) {
    final total = _parseAmount(dto.netAmount) ?? _parseAmount(dto.totalAmount) ?? 0.0;

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
      itemCount: dto.items.length,
      status: SaleHistoryStatus.fromString(dto.status),
      createdAt: dto.createdAt,
      isOfflinePending: false,
      offlineErrorMessage: null,
      items: dto.items.map(SaleHistoryLineItem.fromDto).toList(),
    );
  }

  factory SaleHistoryItem.fromOfflineRow(
      Map<String, dynamic> row,
      List<Map<String, dynamic>> itemRows,
      ) =>
      SaleHistoryItem(
        id: row['server_sale_id']?.toString(),
        clientSaleId: row['client_sale_id']?.toString() ?? '',
        receiptNumber: row['receipt_number']?.toString(),
        shopId: row['shop_id']?.toString(),
        shopName: null,
        customerId: row['customer_id']?.toString(),
        customerName: null,
        paymentMethod: row['payment_method']?.toString() ?? 'cash',
        total: _parseAmount(row['total']?.toString()) ?? 0,
        itemCount: itemRows.length,
        status: SaleHistoryStatus.fromString(row['status']?.toString()),
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
        isOfflinePending: row['status'] != 'synced',
        offlineErrorMessage: row['error_message']?.toString(),
        items: itemRows.map(SaleHistoryLineItem.fromOfflineRow).toList(),
      );


  String get displayRef =>
      (receiptNumber?.isNotEmpty == true)
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

  /// A sale can only be returned when it is fully synced and completed.
  bool get canBeReturned =>
      !isOfflinePending && id != null && status == SaleHistoryStatus.completed;


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
    itemCount: itemCount,
    status: status ?? this.status,
    createdAt: createdAt,
    isOfflinePending: isOfflinePending,
    offlineErrorMessage: offlineErrorMessage,
    items: items,
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
  const SalesHistoryPage({required this.items, required this.hasMore});
}