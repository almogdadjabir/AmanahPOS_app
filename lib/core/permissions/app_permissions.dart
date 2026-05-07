enum AppBusinessType { restaurant, shop, unknown }

enum AppUserRole { owner, cashier, unknown }

class AppPermissions {
  final AppBusinessType businessType;
  final AppUserRole role;

  const AppPermissions({required this.businessType, required this.role});

  static const AppPermissions none = AppPermissions(
    businessType: AppBusinessType.unknown,
    role: AppUserRole.unknown,
  );

  // No active session → hide everything. Prevents menu flash between sessions.
  bool get _hasSession => role != AppUserRole.unknown;

  bool get canAccessPOS => true; // always — cashier needs this
  bool get canAccessProducts => _hasSession;
  bool get canAccessCategories => _hasSession;

  bool get canAccessInventory {
    if (!_hasSession) return false;
    if (businessType == AppBusinessType.restaurant) return false;
    return true; // shop: all roles
  }

  bool get canAccessCustomers {
    if (!_hasSession) return false;
    return !_isRestaurantCashier;
  }

  bool get canAccessReports  => _hasSession && role == AppUserRole.owner;
  bool get canAccessUsers => _hasSession && role == AppUserRole.owner;
  bool get canAccessBusiness => _hasSession && role == AppUserRole.owner;

  bool get isOwner => role == AppUserRole.owner;
  bool get isCashier => role == AppUserRole.cashier;
  bool get isRestaurant => businessType == AppBusinessType.restaurant;
  bool get isShop => businessType == AppBusinessType.shop;

  bool get _isRestaurantCashier =>
      businessType == AppBusinessType.restaurant &&
          role == AppUserRole.cashier;

  static AppPermissions from({
    required String? businessType,
    required String? userRole,
  }) => AppPermissions(
    businessType: _parseBusinessType(businessType),
    role: _parseRole(userRole),
  );

  static AppBusinessType _parseBusinessType(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'restaurant': return AppBusinessType.restaurant;
      case 'shop': return AppBusinessType.shop;
      default: return AppBusinessType.unknown;
    }
  }

  static AppUserRole _parseRole(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'owner': return AppUserRole.owner;
      case 'cashier': return AppUserRole.cashier;
      default: return AppUserRole.unknown;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppPermissions &&
              businessType == other.businessType &&
              role == other.role;

  @override
  int get hashCode => Object.hash(businessType, role);
}