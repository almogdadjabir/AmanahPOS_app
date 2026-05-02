class TransferStockRequestDto {
  String? productId;
  String? fromShop;
  String? toShop;
  String? quantity;

  TransferStockRequestDto({this.productId, this.fromShop, this.toShop, this.quantity});

  TransferStockRequestDto.fromJson(Map<String, dynamic> json) {
    productId = json['product'];
    fromShop = json['from_shop'];
    toShop = json['to_shop'];
    quantity = json['quantity'];
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      if (fromShop != null) 'from_shop': fromShop,
      if (toShop != null) 'to_shop': toShop,
      if (quantity != null) 'quantity': quantity,
    };
  }
}