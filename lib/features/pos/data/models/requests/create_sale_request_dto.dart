class CreateSaleRequestDto {
  final String shop;
  final String paymentMethod;
  final List<CreateSaleItemDto> items;
  final String? customer;
  final String? discountAmount;
  final String? taxAmount;

  const CreateSaleRequestDto({
    required this.shop,
    required this.paymentMethod,
    required this.items,
    this.customer,
    this.discountAmount,
    this.taxAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'shop': shop,
      'payment_method': paymentMethod,
      'items': items.map((e) => e.toJson()).toList(),
      if (customer != null && customer!.trim().isNotEmpty) 'customer': customer,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
    };
  }
}

class CreateSaleItemDto {
  final String productId;
  final String quantity;

  const CreateSaleItemDto({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }
}