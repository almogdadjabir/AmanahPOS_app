enum ScreenMode { light, dark, device }

enum UserRole {
  owner('owner'),
  manager('manager'),
  cashier('cashier'),
  unknown('');

  final String wireName;

  const UserRole(this.wireName);

  static UserRole fromString(String? value) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.unknown;
    }
  }
}

/// Product units. Every value MUST be a backend `UnitChoices` code
/// (pcs, kg, g, l, ml, m, box, pack, dozen, other); anything else fails to
/// sync. The old restaurant units (portion/plate/bowl/glass/bottle) were not
/// valid backend values, so restaurants use `pcs`/`other` for those.
const kUnitsShop = [
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
];
const kUnitsRestaurant = [
  'pcs',
  'kg',
  'g',
  'l',
  'ml',
  'pack',
  'dozen',
  'other',
];

enum AnimationPreference { auto, alwaysOn, alwaysOff }
