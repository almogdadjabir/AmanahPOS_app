import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canAccessSalesHistory is false when no session', () {
    expect(AppPermissions.none.canAccessSalesHistory, isFalse);
  });

  test('canAccessSalesHistory is true for owner', () {
    final perms = AppPermissions.from(businessType: 'shop', userRole: 'owner');
    expect(perms.canAccessSalesHistory, isTrue);
  });

  test('canAccessSalesHistory is true for cashier', () {
    final perms = AppPermissions.from(businessType: 'shop', userRole: 'cashier');
    expect(perms.canAccessSalesHistory, isTrue);
  });

  test('FeaturePermission.allows delegates to canAccessSalesHistory', () {
    final perms = AppPermissions.from(businessType: 'shop', userRole: 'owner');
    expect(perms.allows(AppFeature.salesHistory), isTrue);
  });
}
