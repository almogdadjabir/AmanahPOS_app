class CreateSaleRequestDto {
  final String clientSaleId;
  final String shop;
  final String? customer;
  final String paymentMethod;
  final String discountAmount;
  final List<CreateSaleItemDto> items;

  const CreateSaleRequestDto({
    required this.clientSaleId,
    required this.shop,
    required this.customer,
    required this.paymentMethod,
    required this.discountAmount,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_sale_id': clientSaleId,
      'shop': shop,
      if (customer != null && customer!.isNotEmpty) 'customer': customer,
      'payment_method': paymentMethod,
      'discount_amount': discountAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateSaleItemDto {
  final String productId;
  final String quantity;
  final String? unitPrice;

  /// Free-form amount line (no product). [note] is its label.
  final bool custom;
  final String? note;

  const CreateSaleItemDto({
    required this.productId,
    required this.quantity,
    this.unitPrice,
    this.custom = false,
    this.note,
  });

  Map<String, dynamic> toJson() {
    if (custom) {
      return {
        'custom': true,
        'quantity': quantity,
        'unit_price': unitPrice,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
    }
    return {
      'product_id': productId,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
    };
  }
}
