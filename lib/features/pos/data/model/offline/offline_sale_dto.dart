import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class OfflineSaleItemDto {
  final String productId;
  final String productName;
  final double quantity;
  final String unitPrice;
  final String lineTotal;
  final ProductData productSnapshot;

  const OfflineSaleItemDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.productSnapshot,
  });
}

class OfflineSaleDto {
  final String clientSaleId;
  final String shopId;
  final String? customerId;
  final String paymentMethod;
  final String discountAmount;
  final String taxAmount;
  final String subtotal;
  final String total;
  final List<OfflineSaleItemDto> items;
  final DateTime createdAt;

  const OfflineSaleDto({
    required this.clientSaleId,
    required this.shopId,
    required this.customerId,
    required this.paymentMethod,
    required this.discountAmount,
    required this.taxAmount,
    required this.subtotal,
    required this.total,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toSyncJson() {
    return {
      'client_sale_id': clientSaleId,
      'shop': shopId,
      'customer': customerId,
      'payment_method': paymentMethod,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'created_at': createdAt.toUtc().toIso8601String(),
      'items': items.map((item) {
        return {
          'product_id': item.productId,
          'quantity': item.quantity.toString(),
          'unit_price': item.unitPrice,
        };
      }).toList(),
    };
  }
}