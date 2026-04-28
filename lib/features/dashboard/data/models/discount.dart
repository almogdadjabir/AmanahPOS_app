enum DiscountType { percent, fixed }

class Discount {
  final DiscountType type;
  final num value;

  const Discount({required this.type, required this.value});
  const Discount.none() : type = DiscountType.percent, value = 0;

  /// Computes the discount amount for [subtotal].
  num amountFor(num subtotal) {
    if (value <= 0) return 0;
    if (type == DiscountType.percent) return subtotal * (value / 100);
    return value > subtotal ? subtotal : value;
  }
}
