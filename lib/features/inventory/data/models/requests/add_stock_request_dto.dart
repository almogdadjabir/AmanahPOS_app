import 'package:amana_pos/features/users/data/models/movement_type.dart';

class AddStockRequestDto {
  final String productId;
  final String shopId;
  final String quantity;
  final MovementType movementType;
  final String? reference;
  /// ISO date-only string "YYYY-MM-DD". Null if not tracked.
  /// Shop businesses only — never sent for restaurant type.
  final String? expiryDate;

  const AddStockRequestDto({
    required this.productId,
    required this.shopId,
    required this.quantity,
    required this.movementType,
    this.reference,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
    'product':       productId,
    'shop':          shopId,
    'quantity':      quantity,
    'movement_type': movementType.value,
    if (reference   != null) 'reference':   reference,
    if (expiryDate  != null) 'expiry_date': expiryDate,
  };
}