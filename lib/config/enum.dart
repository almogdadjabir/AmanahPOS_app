enum ScreenMode {
  light,
  dark,
  device
}

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

const kUnitsShop = ['pcs', 'kg', 'g', 'l', 'ml', 'box', 'pack'];
const kUnitsRestaurant = ['pcs', 'portion', 'plate', 'bowl', 'glass', 'bottle'];