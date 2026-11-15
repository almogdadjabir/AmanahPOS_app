import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

List<Section> buildMenuSections(
  BuildContext context,
  NavigationState navState,
) {
  final perms = navState.permissions;
  final current = navState.currentFeature;

  SectionItem? guarded(SectionItem item, bool permitted) =>
      permitted ? item : null;

  final sections = <Section>[
    // ── Sales ────────────────────────────────────────────────────────────────
    Section(
      'Sales',
      [
        guarded(
          SectionItem(
            'pos',
            'POS / Sales',
            'Create sales and checkout',
            PhosphorIconsRegular.cashRegister,
            const Color(0xFF0D9488),
            active: current == AppFeature.pos,
            onTap: () => _go(context, AppFeature.pos),
          ),
          perms.canAccessPOS,
        ),
        guarded(
          SectionItem(
            'sales_history',
            'Sales history',
            'Browse and search all transactions',
            PhosphorIconsRegular.receipt,
            const Color(0xFF0D9488),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(RouteStrings.salesHistoryScreen),
          ),
          perms.canAccessPOS,
        ),
        guarded(
          SectionItem(
            'returns',
            'Returns',
            'Process customer item returns',
            PhosphorIconsRegular.arrowUUpLeft,
            const Color(0xFFDC2626),
            onTap: () =>
                Navigator.of(context).pushNamed(RouteStrings.returnsScreen),
          ),
          perms.canAccessPOS,
        ),
        guarded(
          SectionItem(
            'inventory',
            'Stock',
            'Manage quantity and movements',
            PhosphorIconsFill.package,
            const Color(0xFFEC4899),
            active: current == AppFeature.inventory,
            onTap: () => _go(context, AppFeature.inventory),
          ),
          perms.canAccessInventory,
        ),
      ].whereType<SectionItem>().toList(),
    ),

    // ── Business ─────────────────────────────────────────────────────────────
    Section(
      'Business',
      [
        guarded(
          SectionItem(
            'customers',
            'Customers',
            'Profiles and loyalty',
            PhosphorIconsRegular.users,
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
            PhosphorIconsRegular.chartLine,
            const Color(0xFF22C55E),
            onTap: () =>
                Navigator.of(context).pushNamed(RouteStrings.reportsScreen),
          ),
          perms.canAccessReports,
        ),
      ].whereType<SectionItem>().toList(),
    ),

    // ── Setup ─────────────────────────────────────────────────────────────────
    Section(
      'Setup',
      [
        guarded(
          SectionItem(
            'prod',
            'Products',
            'Items, prices and variants',
            PhosphorIconsRegular.tag,
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
            PhosphorIconsRegular.stack,
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
            PhosphorIconsRegular.storefront,
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
            PhosphorIconsRegular.identificationBadge,
            const Color(0xFFDB2777),
            active: current == AppFeature.users,
            onTap: () => _go(context, AppFeature.users),
          ),
          perms.canAccessUsers,
        ),
      ].whereType<SectionItem>().toList(),
    ),
  ];

  return sections.where((s) => s.items.isNotEmpty).toList();
}

void _go(BuildContext context, AppFeature feature) {
  context.read<NavigationBloc>().add(NavigationFeatureSelected(feature));
}
