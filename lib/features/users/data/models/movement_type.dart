enum MovementType {
  in_,
  out,
  opening,
  return_,

  // These are handled by dedicated endpoints but included for completeness
  adjustment,
  transferIn,
  transferOut,
  sale;

  String get value => switch (this) {
    MovementType.in_ => 'in',
    MovementType.out => 'out',
    MovementType.opening => 'opening',
    MovementType.return_ => 'return',
    MovementType.adjustment  => 'adjustment',
    MovementType.transferIn  => 'transfer_in',
    MovementType.transferOut => 'transfer_out',
    MovementType.sale => 'sale',
  };

  String get label => switch (this) {
    MovementType.in_ => 'Stock In',
    MovementType.out => 'Stock Out',
    MovementType.opening => 'Opening Stock',
    MovementType.return_ => 'Customer Return',
    MovementType.adjustment  => 'Adjustment',
    MovementType.transferIn  => 'Transfer In',
    MovementType.transferOut => 'Transfer Out',
    MovementType.sale => 'Sale',
  };
}