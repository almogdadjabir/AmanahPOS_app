import 'package:amana_pos/features/users/data/models/movement_type.dart';

class AddStockRequestDto {
  final String productId;
  final String shopId;
  final String quantity;
  final MovementType movementType;
  final String? reference;

  const AddStockRequestDto({
    required this.productId,
    required this.shopId,
    required this.quantity,
    required this.movementType,
    this.reference,
  });

  Map<String, dynamic> toJson() => {
    'product':       productId,
    'shop':          shopId,
    'quantity':      quantity,
    'movement_type': movementType.value,
    if (reference != null) 'reference': reference,
  };
}