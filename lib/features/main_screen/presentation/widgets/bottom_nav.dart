import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/feature_config.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        final tabs = _buildTabs(state.permissions);
        if (tabs.isEmpty) return const SizedBox.shrink();
        return NavShell(tabs: tabs, state: state);
      },
    );
  }

  static List<NavTab> _buildTabs(AppPermissions perms) {
    final tabs = <NavTab>[];

    if (perms.isOwner) {
      if (perms.canAccessBusiness) {
        tabs.add(const NavTab(
          feature: AppFeature.business,
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
          label: 'Workspace',
        ));
      }

      tabs.add(const NavTab(
        feature: AppFeature.pos,
        icon: Icons.point_of_sale_rounded,
        activeIcon: Icons.point_of_sale_rounded,
        label: 'POS',
      ));

      if (perms.canAccessProducts) {
        tabs.add(const NavTab(
          feature: AppFeature.products,
          icon: Icons.local_offer_outlined,
          activeIcon: Icons.local_offer_rounded,
          label: 'Products',
        ));
      }

      tabs.add(const NavTab(
        feature: null,
        icon: Icons.more_horiz_rounded,
        activeIcon: Icons.more_horiz_rounded,
        label: 'More',
        isMore: true,
      ));
    } else {

      tabs.add(const NavTab(
        feature: AppFeature.pos,
        icon: Icons.point_of_sale_rounded,
        activeIcon: Icons.point_of_sale_rounded,
        label: 'POS',
      ));

      if (perms.canAccessProducts) {
        tabs.add(const NavTab(
          feature: AppFeature.products,
          icon: Icons.local_offer_outlined,
          activeIcon: Icons.local_offer_rounded,
          label: 'Products',
        ));
      }

      if (perms.canAccessInventory) {
        tabs.add(const NavTab(
          feature: AppFeature.inventory,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          label: 'Stock',
        ));
      }
      
      final directFeatures = tabs
          .where((t) => !t.isMore && t.feature != null)
          .map((t) => t.feature!)
          .toSet();
      final hasMore = AppFeature.values
          .any((f) => perms.allows(f) && !directFeatures.contains(f));
      if (hasMore) {
        tabs.add(const NavTab(
          feature: null,
          icon: Icons.more_horiz_rounded,
          activeIcon: Icons.more_horiz_rounded,
          label: 'More',
          isMore: true,
        ));
      }
    }

    return tabs;
  }
}

const kFeatureConfigs = <AppFeature, FeatureConfig>{
  AppFeature.categories: FeatureConfig(
    feature: AppFeature.categories,
    label: 'Categories',
    subtitle: 'Organize your products',
    icon: Icons.layers_rounded,
    color: Color(0xFF8B5CF6),
  ),
  AppFeature.inventory: FeatureConfig(
    feature: AppFeature.inventory,
    label: 'Stock',
    subtitle: 'Manage inventory levels',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFFEC4899),
  ),
  AppFeature.users: FeatureConfig(
    feature: AppFeature.users,
    label: 'Cashiers',
    subtitle: 'Staff access & accounts',
    icon: Icons.badge_rounded,
    color: Color(0xFF0D9488),
  ),
  AppFeature.customers: FeatureConfig(
    feature: AppFeature.customers,
    label: 'Customers',
    subtitle: 'Profiles and loyalty',
    icon: Icons.people_alt_rounded,
    color: Color(0xFF0EA5E9),
  ),
};
