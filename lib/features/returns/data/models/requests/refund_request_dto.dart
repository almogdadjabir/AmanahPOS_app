class RefundRequestDto {
  final List<RefundItemDto> items;
  final String? notes;

  const RefundRequestDto({required this.items, this.notes});

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class RefundItemDto {
  final String productId;
  final int quantity;

  const RefundItemDto({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
      };
}
