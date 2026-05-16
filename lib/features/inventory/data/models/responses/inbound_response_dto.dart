class InboundResponseDto {
  final bool success;
  final InboundTransactionData? data;

  const InboundResponseDto({
    required this.success,
    this.data,
  });

  factory InboundResponseDto.fromJson(Map<String, dynamic> json) {
    return InboundResponseDto(
      success: json['success'] == true,
      data: json['data'] is Map<String, dynamic>
          ? InboundTransactionData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class InboundTransactionData {
  final String? id;
  final String? reference;
  final String? notes;
  final String? shop;
  final String? shopName;
  final int itemCount;
  final List<InboundTransactionItemData> items;
  final String? createdAt;

  const InboundTransactionData({
    this.id,
    this.reference,
    this.notes,
    this.shop,
    this.shopName,
    this.itemCount = 0,
    this.items = const [],
    this.createdAt,
  });

  factory InboundTransactionData.fromJson(Map<String, dynamic> json) {
    return InboundTransactionData(
      id: json['id']?.toString(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      shop: json['shop']?.toString(),
      shopName: json['shop_name']?.toString(),
      itemCount: (json['item_count'] as num?)?.toInt() ??
          (json['items_count'] as num?)?.toInt() ??
          ((json['items'] as List?)?.length ?? 0),
      items: (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(InboundTransactionItemData.fromJson)
              .toList() ??
          const [],
      createdAt: json['created_at']?.toString(),
    );
  }
}

class InboundTransactionItemData {
  final String? id;
  final String? product;
  final String? productName;
  final String? quantity;
  final String? unitCost;
  final String? expiryDate;
  final String? batchNumber;

  const InboundTransactionItemData({
    this.id,
    this.product,
    this.productName,
    this.quantity,
    this.unitCost,
    this.expiryDate,
    this.batchNumber,
  });

  factory InboundTransactionItemData.fromJson(Map<String, dynamic> json) {
    return InboundTransactionItemData(
      id: json['id']?.toString(),
      product: (json['product'] ?? json['product_id'])?.toString(),
      productName: json['product_name']?.toString(),
      quantity: json['quantity']?.toString(),
      unitCost: (json['unit_cost'] ?? json['cost_price'])?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      batchNumber: json['batch_number']?.toString(),
    );
  }
}
