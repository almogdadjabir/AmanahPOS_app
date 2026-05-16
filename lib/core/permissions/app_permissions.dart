enum AppBusinessType { restaurant, shop, unknown }

enum AppUserRole { owner, manager, cashier, unknown }

class AppPermissions {
  static const inventoryInboundReceivingFeature =
      'inventory_inbound_receiving';

  final AppBusinessType businessType;
  final AppUserRole role;
  final Map<String, bool> enabledFeatures;

  const AppPermissions({
    required this.businessType,
    required this.role,
    this.enabledFeatures = const {},
  });

  static const AppPermissions none = AppPermissions(
    businessType: AppBusinessType.unknown,
    role: AppUserRole.unknown,
  );

  bool get _hasSession =>
      role != AppUserRole.unknown || businessType != AppBusinessType.unknown;

  bool get canAccessPOS => true;
  bool get canAccessProducts => _hasSession;
  bool get canAccessCategories => _hasSession;

  bool get canAccessInventory {
    if (!_hasSession) return false;
    if (businessType == AppBusinessType.restaurant) return false;
    return true;
  }

  bool get canUseInventoryInboundReceiving {
    final featureEnabled =
        enabledFeatures[inventoryInboundReceivingFeature] == true;

    final allowedRole = role == AppUserRole.owner || role == AppUserRole.manager;

    return canAccessInventory && featureEnabled && allowedRole;
  }

  bool get canSeeInboundPremiumCard {
    final allowedRole = role == AppUserRole.owner || role == AppUserRole.manager;
    return canAccessInventory && allowedRole && !canUseInventoryInboundReceiving;
  }

  bool get canAccessCustomers {
    if (!_hasSession) return false;
    return !_isRestaurantCashier;
  }

  bool get canAccessReports => _hasSession && role == AppUserRole.owner;
  bool get canAccessUsers => _hasSession && role == AppUserRole.owner;
  bool get canAccessBusiness => _hasSession && role == AppUserRole.owner;

  bool get isOwner => role == AppUserRole.owner;
  bool get isManager => role == AppUserRole.manager;
  bool get isCashier => role == AppUserRole.cashier;
  bool get isRestaurant => businessType == AppBusinessType.restaurant;
  bool get isShop => businessType == AppBusinessType.shop;

  bool get _isRestaurantCashier =>
      businessType == AppBusinessType.restaurant && role == AppUserRole.cashier;

  static AppPermissions from({
    required String? businessType,
    required String? userRole,
    Map<String, bool> enabledFeatures = const {},
  }) {
    return AppPermissions(
      businessType: _parseBusinessType(businessType),
      role: _parseRole(userRole),
      enabledFeatures: enabledFeatures,
    );
  }

  static AppBusinessType _parseBusinessType(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'restaurant':
        return AppBusinessType.restaurant;
      case 'shop':
      case 'retail':
      case 'store':
      case 'general':
        return AppBusinessType.shop;
      default:
        return AppBusinessType.unknown;
    }
  }

  static AppUserRole _parseRole(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'owner':
      case 'business_owner':
      case 'admin':
        return AppUserRole.owner;
      case 'manager':
        return AppUserRole.manager;
      case 'cashier':
      case 'staff':
        return AppUserRole.cashier;
      default:
        return AppUserRole.unknown;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppPermissions &&
              businessType == other.businessType &&
              role == other.role &&
              _mapEquals(enabledFeatures, other.enabledFeatures);

  @override
  int get hashCode => Object.hash(
    businessType,
    role,
    Object.hashAll(enabledFeatures.entries.map((e) => Object.hash(e.key, e.value))),
  );

  static bool _mapEquals(Map<String, bool> a, Map<String, bool> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
