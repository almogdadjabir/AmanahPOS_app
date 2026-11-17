class RefundRequestDto {
  final List<RefundItemDto> items;
  final String? notes;

  /// How the money goes back: `cash`, `bankak`, ... (BE refund method).
  final String method;

  const RefundRequestDto({
    required this.items,
    this.notes,
    this.method = 'cash',
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class RefundItemDto {
  /// Server id of the sale line (works for product and custom-amount lines).
  final String itemId;
  final double quantity;

  const RefundItemDto({required this.itemId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
      };
}
