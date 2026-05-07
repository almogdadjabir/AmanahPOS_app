// lib/features/feature_menu/widgets/menu_sections.dart
//
// Builds the menu section list filtered to what the current user can access.
// Reads permissions from NavigationState (already synced from AuthBloc).

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<Section> buildMenuSections(
    BuildContext context,
    NavigationState navState,
    ) {
  final perms = navState.permissions;
  final current = navState.currentFeature;

  // Helper: only add an item if the user has permission.
  SectionItem? guarded(
      SectionItem item,
      bool permitted,
      ) =>
      permitted ? item : null;

  final sections = <Section>[
    // ── Sales ────────────────────────────────────────────────────────────────
    Section('Sales', [
      guarded(
        SectionItem(
          'pos',
          'POS / Sales',
          'Create sales and checkout',
          Icons.point_of_sale_rounded,
          const Color(0xFF0D9488),
          active: current == AppFeature.pos,
          onTap: () => _go(context, AppFeature.pos),
        ),
        perms.canAccessPOS,
      ),
      guarded(
        SectionItem(
          'inventory',
          'Stock',
          'Manage quantity and movements',
          Icons.inventory_2_rounded,
          const Color(0xFFEC4899),
          active: current == AppFeature.inventory,
          onTap: () => _go(context, AppFeature.inventory),
        ),
        perms.canAccessInventory,
      ),
    ].whereType<SectionItem>().toList()),

    // ── Business ─────────────────────────────────────────────────────────────
    Section('Business', [
      guarded(
        SectionItem(
          'customers',
          'Customers',
          'Profiles and loyalty',
          Icons.people_alt_rounded,
          const Color(0xFFEC4899),
          active: current == AppFeature.customers,
          onTap: () => _go(context, AppFeature.customers),
        ),
        perms.canAccessCustomers,
      ),
      guarded(
        SectionItem(
          'reports',
          'Reports',
          'Sales and performance',
          Icons.show_chart_rounded,
          const Color(0xFF22C55E),
          // Reports screen not wired yet — keep inactive.
        ),
        perms.canAccessReports,
      ),
    ].whereType<SectionItem>().toList()),

    // ── Setup ─────────────────────────────────────────────────────────────────
    Section('Setup', [
      guarded(
        SectionItem(
          'prod',
          'Products',
          'Items, prices and variants',
          Icons.local_offer_rounded,
          const Color(0xFF0EA5E9),
          active: current == AppFeature.products,
          onTap: () => _go(context, AppFeature.products),
        ),
        perms.canAccessProducts,
      ),
      guarded(
        SectionItem(
          'cat',
          'Categories',
          'Organize your products',
          Icons.layers_rounded,
          const Color(0xFF8B5CF6),
          active: current == AppFeature.categories,
          onTap: () => _go(context, AppFeature.categories),
        ),
        perms.canAccessCategories,
      ),
      guarded(
        SectionItem(
          'business',
          'Business & Shops',
          'Profile and shop locations',
          Icons.store_mall_directory_rounded,
          const Color(0xFF475569),
          active: current == AppFeature.business,
          onTap: () => _go(context, AppFeature.business),
        ),
        perms.canAccessBusiness,
      ),
      guarded(
        SectionItem(
          'cashiers',
          'Cashiers',
          'Staff access and cashier accounts',
          Icons.badge_rounded,
          const Color(0xFFDB2777),
          active: current == AppFeature.users,
          onTap: () => _go(context, AppFeature.users),
        ),
        perms.canAccessUsers,
      ),
    ].whereType<SectionItem>().toList()),
  ];

  // Drop sections that ended up empty after permission filtering.
  return sections.where((s) => s.items.isNotEmpty).toList();
}

void _go(BuildContext context, AppFeature feature) {
  context.read<NavigationBloc>().add(NavigationFeatureSelected(feature));
}