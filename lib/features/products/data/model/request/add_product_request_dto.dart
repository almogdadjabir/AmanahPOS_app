import 'package:amana_pos/common/services/image/app_image_picker.dart';

class AddProductRequestDto {
  final String name;
  final String price;
  final String category;
  final String unit;
  final String? costPrice;
  final String? description;
  final String? sku;
  final String? barcode;
  final bool trackInventory;
  final String? minStockLevel;
  final PickedAppImage? imageUpload;

  const AddProductRequestDto({
    required this.name,
    required this.price,
    required this.category,
    required this.unit,
    this.costPrice,
    this.description,
    this.sku,
    this.barcode,
    required this.trackInventory,
    this.minStockLevel,
    this.imageUpload,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'unit': unit,
      'track_inventory': trackInventory,
      if (costPrice != null) 'cost_price': costPrice,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
    };
  }
}