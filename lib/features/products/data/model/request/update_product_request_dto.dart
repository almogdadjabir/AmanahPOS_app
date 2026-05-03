import 'package:amana_pos/common/services/image/app_image_picker.dart';

class UpdateProductRequestDto {
  final String? name;
  final String? price;
  final String? category;
  final String? unit;
  final String? costPrice;
  final String? description;
  final String? sku;
  final String? barcode;
  final bool? trackInventory;
  final String? minStockLevel;
  final PickedAppImage? imageUpload;

  const UpdateProductRequestDto({
    this.name,
    this.price,
    this.category,
    this.unit,
    this.costPrice,
    this.description,
    this.sku,
    this.barcode,
    this.trackInventory,
    this.minStockLevel,
    this.imageUpload,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (costPrice != null) 'cost_price': costPrice,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (trackInventory != null) 'track_inventory': trackInventory,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
    };
  }
}