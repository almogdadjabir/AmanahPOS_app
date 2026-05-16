import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        final isPremium = state.permissions.canUseInventoryInboundReceiving;
        final tabs = _buildTabs(state.permissions, isPremium: isPremium);
        if (tabs.isEmpty) return const SizedBox.shrink();
        return NavShell(tabs: tabs, state: state);
      },
    );
  }

  static List<NavTab> _buildTabs(AppPermissions perms, {bool isPremium = false}) {
    final tabs = <NavTab>[];

    if (perms.isOwner) {
      if (perms.canAccessBusiness) {
        tabs.add(const NavTab(
          feature: AppFeature.business,
          icon: SolarIconsBold.shop,
          activeIcon: SolarIconsBold.shop,
          label: 'Home',
        ));
      }

      if (perms.canAccessProducts) {
        tabs.add(const NavTab(
          feature: AppFeature.products,
          icon: SolarIconsOutline.bag5,
          activeIcon: SolarIconsOutline.bag5,
          label: 'Products',
        ));
      }

      tabs.add(const NavTab(
        feature: AppFeature.pos,
        icon: SolarIconsOutline.cartLarge_4,
        activeIcon: SolarIconsOutline.cartLarge,
        label: 'Sell',
      ));

      if (perms.canAccessInventory) {
        tabs.add(NavTab(
          feature: AppFeature.inventory,
          icon: SolarIconsOutline.boxMinimalistic,
          activeIcon: SolarIconsBold.boxMinimalistic,
          label: 'Stock',
          showPremiumIndicator: isPremium,
        ));
      } else {
        tabs.add(const NavTab(
          feature: AppFeature.users,
          icon: SolarIconsOutline.userPlus,
          activeIcon: SolarIconsOutline.userPlus,
          label: 'Cashiers',
        ));
      }

      tabs.add(const NavTab(
        feature: null,
        icon: SolarIconsOutline.menuDots,
        activeIcon: SolarIconsBold.menuDots,
        label: 'More',
        isMore: true,
      ));
    } else {
      if (perms.canAccessProducts) {
        tabs.add(const NavTab(
          feature: AppFeature.products,
          icon: SolarIconsOutline.bag5,
          activeIcon: SolarIconsBold.bag5,
          label: 'Products',
        ));
      }

      if (perms.canAccessInventory) {
        tabs.add(NavTab(
          feature: AppFeature.inventory,
          icon: SolarIconsOutline.boxMinimalistic,
          activeIcon: SolarIconsBold.boxMinimalistic,
          label: 'Stock',
          showPremiumIndicator: isPremium,
        ));
      }

      tabs.add(const NavTab(
        feature: AppFeature.pos,
        icon: SolarIconsOutline.cartLarge_4,
        activeIcon: SolarIconsOutline.cartLarge,
        label: 'Sell',
      ));

      final directFeatures = tabs
          .where((t) => !t.isMore && t.feature != null)
          .map((t) => t.feature!)
          .toSet();

      final hasMore = AppFeature.values.any(
        (f) => perms.allows(f) && !directFeatures.contains(f),
      );

      if (hasMore) {
        tabs.add(const NavTab(
          feature: null,
          icon: SolarIconsOutline.menuDots,
          activeIcon: SolarIconsBold.menuDots,
          label: 'More',
          isMore: true,
        ));
      }
    }

    return tabs;
  }
}
