class AdjustStockRequestDto {
  String? productId;
  String? shopId;
  String? newQuantity;
  String? notes;

  AdjustStockRequestDto({this.productId, this.shopId, this.newQuantity, this.notes});

  AdjustStockRequestDto.fromJson(Map<String, dynamic> json) {
    productId = json['product'];
    shopId = json['shop'];
    newQuantity = json['new_quantity'];
    notes = json['notes'];
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      if (shopId != null) 'shop': shopId,
      if (newQuantity != null) 'new_quantity': newQuantity,
      if (notes != null) 'notes': notes,
    };
  }
}