import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt c(int v) => BigInt.from(v);

void main() {
  group('percent', () {
    test('10% of 20.00 is 2.00', () {
      expect(const CartDiscount.percent('10').cutOf(c(2000)), c(200));
    });
    test('half a cent rounds up', () {
      // 12.5% of 0.04 = 0.005 -> 0.01
      expect(const CartDiscount.percent('12.5').cutOf(c(4)), c(1));
    });
    test('100% is the whole base, never more', () {
      expect(const CartDiscount.percent('100').cutOf(c(1234)), c(1234));
      expect(const CartDiscount.percent('250').cutOf(c(1234)), c(1234));
    });
    test('follows the base', () {
      const d = CartDiscount.percent('10');
      expect(d.cutOf(c(100)), c(10));
      expect(d.cutOf(c(300)), c(30));
    });
  });

  group('amount', () {
    test('is cut to the base', () {
      expect(const CartDiscount.amount('2.50').cutOf(c(1000)), c(250));
      expect(const CartDiscount.amount('50').cutOf(c(1000)), c(1000));
    });
    test('zero, junk and an empty base give nothing', () {
      expect(const CartDiscount.amount('0').cutOf(c(1000)), BigInt.zero);
      expect(const CartDiscount.amount('x').cutOf(c(1000)), BigInt.zero);
      expect(const CartDiscount.percent('10').cutOf(BigInt.zero), BigInt.zero);
    });
  });

  group('check', () {
    test('accepts a fair value', () {
      expect(CartDiscount.check(DiscountKind.percent, '10', c(1000)), isNull);
      expect(CartDiscount.check(DiscountKind.amount, '10', c(1000)), isNull);
      expect(CartDiscount.check(DiscountKind.percent, '100', c(1000)), isNull);
      expect(CartDiscount.check(DiscountKind.amount, '10.00', c(1000)), isNull);
    });
    test('refuses junk, zero and too much', () {
      expect(CartDiscount.check(DiscountKind.percent, 'abc', c(1000)),
          DiscountProblem.notANumber);
      expect(CartDiscount.check(DiscountKind.percent, '0', c(1000)),
          DiscountProblem.zero);
      expect(CartDiscount.check(DiscountKind.percent, '100.01', c(1000)),
          DiscountProblem.overBase);
      expect(CartDiscount.check(DiscountKind.amount, '10.01', c(1000)),
          DiscountProblem.overBase);
      expect(CartDiscount.check(DiscountKind.amount, '-1', c(1000)),
          DiscountProblem.notANumber);
    });
  });

  test('equal by kind and value', () {
    expect(const CartDiscount.percent('10'), const CartDiscount.percent('10'));
    expect(const CartDiscount.percent('10') == const CartDiscount.amount('10'),
        isFalse);
  });
}
