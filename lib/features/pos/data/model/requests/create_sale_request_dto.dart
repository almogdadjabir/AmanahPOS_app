class CreateSaleRequestDto {
  final String clientSaleId;
  final String shop;
  final String? customer;
  final String paymentMethod;
  final String discountAmount;
  final String taxAmount;
  final List<CreateSaleItemDto> items;

  const CreateSaleRequestDto({
    required this.clientSaleId,
    required this.shop,
    required this.customer,
    required this.paymentMethod,
    required this.discountAmount,
    required this.taxAmount,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_sale_id': clientSaleId,
      'shop': shop,
      if (customer != null && customer!.isNotEmpty) 'customer': customer,
      'payment_method': paymentMethod,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateSaleItemDto {
  final String productId;
  final String quantity;
  final String? unitPrice;

  const CreateSaleItemDto({
    required this.productId,
    required this.quantity,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
    };
  }
}