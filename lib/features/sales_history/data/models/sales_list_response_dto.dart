class SalesListResponseDto {
  final int count;
  final String? next;
  final String? previous;
  final List<SaleDto> results;

  const SalesListResponseDto({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory SalesListResponseDto.fromJson(Map<String, dynamic> json) {
    return SalesListResponseDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => SaleDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SaleDto {
  final String id;
  final String? receiptNumber;
  final String? shopId;
  final String? shopName;
  final String? customerId;
  final String? customerName;
  final String paymentMethod;
  final String totalAmount;
  final String netAmount;
  final String status;
  final String? clientSaleId;
  final List<SaleItemDto> items;
  final DateTime createdAt;

  const SaleDto({
    required this.id,
    required this.receiptNumber,
    required this.shopId,
    required this.shopName,
    required this.customerId,
    required this.customerName,
    required this.paymentMethod,
    required this.totalAmount,
    required this.netAmount,
    required this.status,
    required this.clientSaleId,
    required this.items,
    required this.createdAt,
  });

  factory SaleDto.fromJson(Map<String, dynamic> json) {
    // shop can be a string ID or a nested object
    final shopRaw = json['shop'];
    String? shopId;
    String? shopName;
    if (shopRaw is Map) {
      shopId = shopRaw['id']?.toString();
      shopName = shopRaw['name']?.toString();
    } else {
      shopId = shopRaw?.toString();
    }

    // customer can be null, string ID, or nested object
    final customerRaw = json['customer'];
    String? customerId;
    String? customerName;
    if (customerRaw is Map) {
      customerId = customerRaw['id']?.toString();
      customerName = customerRaw['name']?.toString();
    } else if (customerRaw is String) {
      customerId = customerRaw;
    }

    return SaleDto(
      id: json['id']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString(),
      shopId: shopId,
      shopName: shopName,
      customerId: customerId,
      customerName: customerName,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      totalAmount: json['total_amount']?.toString() ?? '0',
      netAmount: json['net_amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'completed',
      clientSaleId: json['client_sale_id']?.toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => SaleItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SaleItemDto {
  final String productId;
  final String productName;
  final String quantity;
  final String unitPrice;
  final String subtotal;

  const SaleItemDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItemDto.fromJson(Map<String, dynamic> json) {
    // product can be a string ID or a nested object
    final productRaw = json['product'];
    String productId = '';
    String productName = '';
    if (productRaw is Map) {
      productId = productRaw['id']?.toString() ?? '';
      productName = productRaw['name']?.toString() ?? '';
    } else {
      productId = productRaw?.toString() ?? '';
      productName = json['product_name']?.toString() ?? '';
    }

    return SaleItemDto(
      productId: productId,
      productName: productName.isNotEmpty ? productName : (json['product_name']?.toString() ?? 'Item'),
      quantity: json['quantity']?.toString() ?? '1',
      unitPrice: json['unit_price']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
    );
  }

  double get quantityDouble => double.tryParse(quantity) ?? 1;
  double get unitPriceDouble => double.tryParse(unitPrice) ?? 0;
  double get subtotalDouble => double.tryParse(subtotal) ?? 0;
}
