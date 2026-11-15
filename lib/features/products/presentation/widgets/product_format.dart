import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/widgets.dart';

enum ProductStockLevel { untracked, ok, low, out }

/// Stock state of a product as shown in rows, tiles and chips.
/// Restaurants and products that do not track inventory are [untracked].
ProductStockLevel productStockLevel(
  ProductData product, {
  required bool isRestaurant,
}) {
  if (isRestaurant || product.trackInventory == false) {
    return ProductStockLevel.untracked;
  }
  final stock = product.stockLevel ?? 0;
  if (stock <= 0) return ProductStockLevel.out;
  final min = product.minStockLevel ?? 0;
  final threshold = min > 0 ? min : 5;
  if (stock <= threshold) return ProductStockLevel.low;
  return ProductStockLevel.ok;
}

String formatQty(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(value * 10 % 1 == 0 ? 1 : 2);
}

String formatPrice(String? value) {
  if (value == null) return '0';
  final parsed = double.tryParse(value);
  if (parsed == null) return value;

  final amount = parsed % 1 != 0
      ? parsed.toStringAsFixed(2)
      : parsed.toStringAsFixed(0);

  return amount.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String productDisplayName(BuildContext context, ProductData product) {
  final name = product.name?.trim();
  if (name == null || name.isEmpty) return context.tr.product;
  return name;
}

/// One-line stock text for a row or tile, or null when stock is not tracked.
String? productStockText(
  BuildContext context,
  ProductData product,
  ProductStockLevel level,
) {
  final tr = context.tr;
  final qty = formatQty(product.stockLevel ?? 0);
  return switch (level) {
    ProductStockLevel.untracked => null,
    ProductStockLevel.out => tr.pcOutOfStock,
    ProductStockLevel.low => tr.pcLeft(qty),
    ProductStockLevel.ok => tr.pcInStock(qty),
  };
}

Color productStockColor(BuildContext context, ProductStockLevel level) {
  final colors = context.appColors;
  return switch (level) {
    ProductStockLevel.out => colors.danger,
    ProductStockLevel.low => colors.warning,
    _ => colors.textHint,
  };
}
