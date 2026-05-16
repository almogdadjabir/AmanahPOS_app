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
  final String? vendorId;
  final String? vendorName;
  final String? totalQuantity;
  final String? createdByName;
  final int itemCount;
  final List<InboundTransactionItemData> items;
  final String? createdAt;

  const InboundTransactionData({
    this.id,
    this.reference,
    this.notes,
    this.shop,
    this.shopName,
    this.vendorId,
    this.vendorName,
    this.totalQuantity,
    this.createdByName,
    this.itemCount = 0,
    this.items = const [],
    this.createdAt,
  });

  factory InboundTransactionData.fromJson(Map<String, dynamic> json) {
    // vendor arrives as a nested object {"id":...,"name":...} or null
    final vendorObj = json['vendor'] as Map<String, dynamic>?;
    return InboundTransactionData(
      id: json['id']?.toString(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      shop: json['shop']?.toString(),
      shopName: json['shop_name']?.toString(),
      vendorId: (vendorObj?['id'] ?? json['vendor_id'])?.toString(),
      vendorName: (vendorObj?['name'] ?? json['vendor_name'])?.toString(),
      totalQuantity: json['total_quantity']?.toString(),
      createdByName: json['created_by_name']?.toString(),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'notes': notes,
    'shop': shop,
    'shop_name': shopName,
    'vendor_id': vendorId,
    'vendor_name': vendorName,
    'total_quantity': totalQuantity,
    'created_by_name': createdByName,
    'item_count': itemCount,
    'items': items.map((i) => i.toJson()).toList(),
    'created_at': createdAt,
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product,
    'product_name': productName,
    'quantity': quantity,
    'unit_cost': unitCost,
    'expiry_date': expiryDate,
    'batch_number': batchNumber,
  };
}

class InboundListResponseDto {
  final int count;
  final int totalPages;
  final List<InboundTransactionData> results;

  const InboundListResponseDto({
    required this.count,
    required this.totalPages,
    required this.results,
  });

  factory InboundListResponseDto.fromJson(Map<String, dynamic> json) {
    return InboundListResponseDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      results: (json['results'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(InboundTransactionData.fromJson)
              .toList() ??
          const [],
    );
  }
}
