class RefundResponseDto {
  final bool? success;
  final String? refundReference;
  final String? refundTotal;
  final List<ReturnedItems>? returnedItems;
  final Sale? sale;

  const RefundResponseDto({
    this.success,
    this.refundReference,
    this.refundTotal,
    this.returnedItems,
    this.sale,
  });

  factory RefundResponseDto.fromJson(Map<String, dynamic> json) {
    return RefundResponseDto(
      success: json['success'] as bool?,
      refundReference: json['refund_reference']?.toString(),
      refundTotal: json['refund_total']?.toString(),
      returnedItems: (json['returned_items'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(ReturnedItems.fromJson)
          .toList(),
      sale: json['sale'] is Map<String, dynamic>
          ? Sale.fromJson(json['sale'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'refund_reference': refundReference,
      'refund_total': refundTotal,
      'returned_items': returnedItems?.map((e) => e.toJson()).toList(),
      'sale': sale?.toJson(),
    };
  }

  bool get isPartialRefund => sale?.status == 'partial_refund';

  bool get isFullRefund => sale?.status == 'refunded';

  double get refundTotalAsDouble {
    return double.tryParse(refundTotal?.toString() ?? '0') ?? 0;
  }

  String get safeRefundReference => refundReference ?? '';
}

class ReturnedItems {
  final String? productId;
  final String? productName;
  final String? quantity;
  final String? unitPrice;
  final String? subtotal;

  const ReturnedItems({
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.subtotal,
  });

  factory ReturnedItems.fromJson(Map<String, dynamic> json) {
    return ReturnedItems(
      productId: json['product_id']?.toString(),
      productName: json['product_name']?.toString(),
      quantity: json['quantity']?.toString(),
      unitPrice: json['unit_price']?.toString(),
      subtotal: json['subtotal']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  double get quantityAsDouble {
    return double.tryParse(quantity?.toString() ?? '0') ?? 0;
  }

  double get unitPriceAsDouble {
    return double.tryParse(unitPrice?.toString() ?? '0') ?? 0;
  }

  double get subtotalAsDouble {
    return double.tryParse(subtotal?.toString() ?? '0') ?? 0;
  }

  String get safeProductName {
    final value = productName?.trim() ?? '';
    return value.isEmpty ? 'Item' : value;
  }
}

class Sale {
  final String? id;
  final String? tenant;
  final String? shop;
  final String? shopName;
  final String? cashier;
  final String? cashierName;
  final String? customer;
  final String? receiptNumber;
  final String? totalAmount;
  final String? discountAmount;
  final String? taxAmount;
  final String? netAmount;
  final String? paymentMethod;
  final String? bankakAccountSnapshot;
  final String? status;
  final String? notes;
  final int? itemCount;
  final List<Items>? items;
  final String? syncedAt;
  final String? createdAt;
  final String? updatedAt;

  const Sale({
    this.id,
    this.tenant,
    this.shop,
    this.shopName,
    this.cashier,
    this.cashierName,
    this.customer,
    this.receiptNumber,
    this.totalAmount,
    this.discountAmount,
    this.taxAmount,
    this.netAmount,
    this.paymentMethod,
    this.bankakAccountSnapshot,
    this.status,
    this.notes,
    this.itemCount,
    this.items,
    this.syncedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id']?.toString(),
      tenant: json['tenant']?.toString(),
      shop: json['shop']?.toString(),
      shopName: json['shop_name']?.toString(),
      cashier: json['cashier']?.toString(),
      cashierName: json['cashier_name']?.toString(),
      customer: json['customer']?.toString(),
      receiptNumber: json['receipt_number']?.toString(),
      totalAmount: json['total_amount']?.toString(),
      discountAmount: json['discount_amount']?.toString(),
      taxAmount: json['tax_amount']?.toString(),
      netAmount: json['net_amount']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      bankakAccountSnapshot: json['bankak_account_snapshot']?.toString(),
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
      itemCount: (json['item_count'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(Items.fromJson)
          .toList(),
      syncedAt: json['synced_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant': tenant,
      'shop': shop,
      'shop_name': shopName,
      'cashier': cashier,
      'cashier_name': cashierName,
      'customer': customer,
      'receipt_number': receiptNumber,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'net_amount': netAmount,
      'payment_method': paymentMethod,
      'bankak_account_snapshot': bankakAccountSnapshot,
      'status': status,
      'notes': notes,
      'item_count': itemCount,
      'items': items?.map((e) => e.toJson()).toList(),
      'synced_at': syncedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Items {
  final String? id;
  final String? product;
  final String? productName;
  final String? productSku;
  final String? quantity;
  final String? unitPrice;
  final String? discount;
  final String? subtotal;

  const Items({
    this.id,
    this.product,
    this.productName,
    this.productSku,
    this.quantity,
    this.unitPrice,
    this.discount,
    this.subtotal,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      id: json['id']?.toString(),
      product: json['product']?.toString(),
      productName: json['product_name']?.toString(),
      productSku: json['product_sku']?.toString(),
      quantity: json['quantity']?.toString(),
      unitPrice: json['unit_price']?.toString(),
      discount: json['discount']?.toString(),
      subtotal: json['subtotal']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'subtotal': subtotal,
    };
  }
}