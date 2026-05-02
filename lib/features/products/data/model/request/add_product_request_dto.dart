class AddProductRequestDto {
  final String name;
  final String price;
  final String? costPrice;
  final String category;
  final String unit;
  final bool trackInventory;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? minStockLevel;

  const AddProductRequestDto({
    required this.name,
    required this.price,
    required this.category,
    required this.unit,
    this.costPrice,
    this.trackInventory = true,
    this.description,
    this.sku,
    this.barcode,
    this.minStockLevel,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'category': category,
    'unit': unit,
    'track_inventory': trackInventory,
    if (costPrice != null && costPrice!.isNotEmpty) 'cost_price':  costPrice,
    if (description  != null && description!.isNotEmpty) 'description': description,
    if (sku != null && sku!.isNotEmpty) 'sku': sku,
    if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
    if (minStockLevel != null) 'min_stock_level': minStockLevel,
  };
}