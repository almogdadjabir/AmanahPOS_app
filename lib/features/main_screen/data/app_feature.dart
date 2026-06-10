import 'package:amana_pos/core/permissions/app_permissions.dart';

enum AppFeature {
  pos,
  business,
  users,
  categories,
  products,
  inventory,
  customers,
  salesHistory,
}

extension FeaturePermission on AppPermissions {
  bool allows(AppFeature feature) {
    switch (feature) {
      case AppFeature.pos:
        return canAccessPOS;
      case AppFeature.products:
        return canAccessProducts;
      case AppFeature.categories:
        return canAccessCategories;
      case AppFeature.inventory:
        return canAccessInventory;
      case AppFeature.customers:
        return canAccessCustomers;
      case AppFeature.users:
        return canAccessUsers;
      case AppFeature.business:
        return canAccessBusiness;
      case AppFeature.salesHistory:
        return canAccessSalesHistory;
    }
  }
}