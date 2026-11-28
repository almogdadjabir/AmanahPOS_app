enum AppBusinessType { restaurant, shop, unknown }

enum AppUserRole { owner, manager, cashier, unknown }

class AppPermissions {
  /// Plan feature key, kept for display only. The backend no longer enforces
  /// it (it reports `enforced: false`), so it must NOT gate any screen: inbound,
  /// vendors, expiry and the premium summary depend on role + business type.
  static const inventoryInboundReceivingFeature = 'inventory_inbound_receiving';

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
  bool get canAccessSalesHistory => _hasSession;

  bool get canAccessInventory {
    if (!_hasSession) return false;
    if (businessType == AppBusinessType.restaurant) return false;
    return true;
  }

  /// SINGLE SWITCH for the full (premium) inventory: inbound receiving,
  /// vendors, receipts and the premium dashboard. Disabled for every business
  /// type until pharmacy support ships; the code, blocs and API calls are
  /// kept. Set to true to bring the full version back. Not plan-gated.
  static const bool fullInventoryEnabled = false;

  /// Role + business-type rule for the full inventory (manager/owner, never
  /// restaurants), independent of the switch above.
  bool get inboundAllowedByRole {
    final allowedRole =
        role == AppUserRole.owner || role == AppUserRole.manager;
    return canAccessInventory && allowedRole;
  }

  bool get canUseInventoryInboundReceiving =>
      fullInventoryEnabled && inboundAllowedByRole;

  bool get canAccessCustomers {
    if (!_hasSession) return false;
    return !_isRestaurantCashier;
  }

  bool get canAccessReports => _hasSession && role == AppUserRole.owner;
  bool get canAccessUsers => _hasSession && role == AppUserRole.owner;
  bool get canAccessBusiness => _hasSession && role == AppUserRole.owner;

  /// Add / edit / delete of products, categories and vendors (BE: owner or
  /// manager, `forbidden` otherwise). Cashiers get no entry points.
  bool get canEditCatalog =>
      role == AppUserRole.owner || role == AppUserRole.manager;

  /// Line and sale discounts: owner and manager only (the phone has no
  /// owner-approval pop-up like the desktop).
  bool get canGiveDiscount =>
      role == AppUserRole.owner || role == AppUserRole.manager;

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
      case 'pharmacy': // backend type; stock + expiry behave like a shop
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
    Object.hashAll(
      enabledFeatures.entries.map((e) => Object.hash(e.key, e.value)),
    ),
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
