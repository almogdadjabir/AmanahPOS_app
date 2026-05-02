class UpdateProductRequestDto {
  final String? name;
  final String? price;
  final String? costPrice;
  final String? category;
  final String? unit;
  final bool? trackInventory;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? minStockLevel;
  final int? expiryAlertDays;

  const UpdateProductRequestDto({
    this.name,
    this.price,
    this.costPrice,
    this.category,
    this.unit,
    this.trackInventory,
    this.description,
    this.sku,
    this.barcode,
    this.minStockLevel,
    this.expiryAlertDays,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (costPrice != null) 'cost_price': costPrice,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (trackInventory != null) 'track_inventory': trackInventory,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
      if (expiryAlertDays != null) 'expiry_alert_days': expiryAlertDays,
    };
  }
}