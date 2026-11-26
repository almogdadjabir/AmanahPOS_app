import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';

/// How the signed-in user may give a discount right now.
enum DiscountAccess {
  /// No discount controls.
  none,

  /// Controls shown; the discount is given straight away.
  direct,

  /// Controls shown; the owner's PIN is asked first.
  approval,
}

DiscountAccess discountAccess(AppPermissions p, BusinessFeatures f) {
  if (p.canGiveDiscount) return DiscountAccess.direct;
  if (!p.isCashier) return DiscountAccess.none;
  return switch (f.cashierDiscount) {
    CashierDiscountMode.off => DiscountAccess.none,
    CashierDiscountMode.approval => DiscountAccess.approval,
    CashierDiscountMode.free => DiscountAccess.direct,
  };
}
