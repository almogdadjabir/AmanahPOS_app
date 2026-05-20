class CreateInboundRequestDto {
  final String shopId;
  final String reference;
  final String? notes;
  final String vendorId;
  final List<CreateInboundItemRequestDto> items;

  const CreateInboundRequestDto({
    required this.shopId,
    required this.reference,
    this.notes,
    required this.vendorId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'reference': reference.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'vendor_id': vendorId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateInboundItemRequestDto {
  final String productId;
  final String quantity;
  final String? unitCost;
  final String? expiryDate;
  final String? batchNumber;

  const CreateInboundItemRequestDto({
    required this.productId,
    required this.quantity,
    this.unitCost,
    this.expiryDate,
    this.batchNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity.trim(),
      if (unitCost != null && unitCost!.trim().isNotEmpty)
        'unit_cost': unitCost!.trim(),
      if (expiryDate != null && expiryDate!.trim().isNotEmpty)
        'expiry_date': expiryDate!.trim(),
      if (batchNumber != null && batchNumber!.trim().isNotEmpty)
        'batch_number': batchNumber!.trim(),
    };
  }
}
