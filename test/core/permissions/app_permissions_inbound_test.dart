import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

AppPermissions _p(String type, String role, {Map<String, bool>? f}) =>
    AppPermissions.from(
      businessType: type,
      userRole: role,
      enabledFeatures: f ?? const {},
    );

void main() {
  group('full inventory (inbound/vendors) is switched off for everyone', () {
    test('switch is off', () {
      expect(AppPermissions.fullInventoryEnabled, isFalse);
    });

    test('no role or business type reaches inbound, vendors or receipts', () {
      for (final type in ['shop', 'pharmacy', 'restaurant']) {
        for (final role in ['owner', 'manager', 'cashier']) {
          for (final f in [
            <String, bool>{},
            {AppPermissions.inventoryInboundReceivingFeature: true},
          ]) {
            expect(
              _p(type, role, f: f).canUseInventoryInboundReceiving,
              isFalse,
              reason: '$type/$role',
            );
          }
        }
      }
    });

    test('role rule is kept for when it is re-enabled', () {
      expect(_p('shop', 'manager').inboundAllowedByRole, isTrue);
      expect(_p('pharmacy', 'owner').inboundAllowedByRole, isTrue);
      expect(_p('shop', 'cashier').inboundAllowedByRole, isFalse);
      expect(_p('restaurant', 'owner').inboundAllowedByRole, isFalse);
    });

    test('basic stock stays: shop and pharmacy yes, restaurant no', () {
      expect(_p('shop', 'owner').canAccessInventory, isTrue);
      expect(_p('pharmacy', 'owner').canAccessInventory, isTrue);
      expect(_p('restaurant', 'owner').canAccessInventory, isFalse);
    });

    test('generic enabledFeatures map still carried', () {
      expect(_p('shop', 'owner', f: {'x': true}).enabledFeatures['x'], isTrue);
    });
  });

  test('pharmacy is a stock business like a shop, not unknown', () {
    final p = _p('pharmacy', 'owner');
    expect(p.businessType, AppBusinessType.shop);
    expect(p.canAccessInventory, isTrue);
  });

  test('units are all valid backend codes', () {
    const valid = {
      'pcs',
      'kg',
      'g',
      'l',
      'ml',
      'm',
      'box',
      'pack',
      'dozen',
      'other',
    };
    expect(kUnitsShop.every(valid.contains), isTrue);
    expect(kUnitsRestaurant.every(valid.contains), isTrue);
  });
}
