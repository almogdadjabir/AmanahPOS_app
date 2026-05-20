import 'package:amana_pos/config/providers/feature_bloc_providers.dart';
import 'package:amana_pos/features/business/presentation/business_screen.dart';
import 'package:amana_pos/features/category/presentation/category_screen.dart';
import 'package:amana_pos/features/customers/presentation/customers_screen.dart';
import 'package:amana_pos/features/inventory/presentation/inventory_screen.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/features/products/presentation/product_screen.dart';
import 'package:amana_pos/features/users/presentation/users_screen.dart';
import 'package:flutter/material.dart';

class NavigationConfig {
  static Widget screenFor(AppFeature feature) {
    switch (feature) {
      case AppFeature.pos:
        return const PosScreen();

      case AppFeature.business:
        return const BusinessScreen();

      case AppFeature.users:
        return UsersScreen();

      case AppFeature.categories:
        return FeatureBlocProviders.categories(
          child: const CategoriesScreen(),
        );

      case AppFeature.products:
        return const ProductsScreen();

      case AppFeature.inventory:
        return FeatureBlocProviders.inventory(
          child: const InventoryScreen(),
        );

      case AppFeature.customers:
        return FeatureBlocProviders.customers(
          child: const CustomersScreen(),
        );
    }
  }
}