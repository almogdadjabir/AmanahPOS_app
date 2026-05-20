import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
        final tabs = buildTabs(context, state.permissions, isPremium: isPremium);
        if (tabs.isEmpty) return const SizedBox.shrink();
        return NavShell(tabs: tabs, state: state);
      },
    );
  }

  static List<NavTab> buildTabs(
    BuildContext context,
    AppPermissions perms, {
    bool isPremium = false,
  }) {
    final tr = context.tr;
    final tabs = <NavTab>[];

    if (perms.isOwner) {
      if (perms.canAccessBusiness) {
        tabs.add(NavTab(
          feature: AppFeature.business,
          icon: SolarIconsBold.shop,
          activeIcon: SolarIconsBold.shop,
          label: tr.navHome,
        ));
      }

      if (perms.canAccessProducts) {
        tabs.add(NavTab(
          feature: AppFeature.products,
          icon: SolarIconsOutline.bag5,
          activeIcon: SolarIconsOutline.bag5,
          label: tr.navProducts,
        ));
      }

      tabs.add(NavTab(
        feature: AppFeature.pos,
        icon: SolarIconsOutline.cartLarge_4,
        activeIcon: SolarIconsOutline.cartLarge,
        label: tr.navSell,
      ));

      if (perms.canAccessInventory) {
        tabs.add(NavTab(
          feature: AppFeature.inventory,
          icon: SolarIconsOutline.boxMinimalistic,
          activeIcon: SolarIconsBold.boxMinimalistic,
          label: tr.navInventory,
          showPremiumIndicator: isPremium,
        ));
      } else {
        tabs.add(NavTab(
          feature: AppFeature.users,
          icon: SolarIconsOutline.userPlus,
          activeIcon: SolarIconsOutline.userPlus,
          label: tr.navCashiers,
        ));
      }

      tabs.add(NavTab(
        feature: null,
        icon: SolarIconsOutline.menuDots,
        activeIcon: SolarIconsBold.menuDots,
        label: tr.navMore,
        isMore: true,
      ));
    } else {
      if (perms.canAccessProducts) {
        tabs.add(NavTab(
          feature: AppFeature.products,
          icon: SolarIconsOutline.bag5,
          activeIcon: SolarIconsBold.bag5,
          label: tr.navProducts,
        ));
      }

      if (perms.canAccessInventory) {
        tabs.add(NavTab(
          feature: AppFeature.inventory,
          icon: SolarIconsOutline.boxMinimalistic,
          activeIcon: SolarIconsBold.boxMinimalistic,
          label: tr.navInventory,
          showPremiumIndicator: isPremium,
        ));
      }

      tabs.add(NavTab(
        feature: AppFeature.pos,
        icon: SolarIconsOutline.cartLarge_4,
        activeIcon: SolarIconsOutline.cartLarge,
        label: tr.navSell,
      ));

      final directFeatures = tabs
          .where((t) => !t.isMore && t.feature != null)
          .map((t) => t.feature!)
          .toSet();

      final hasMore = AppFeature.values.any(
        (f) => perms.allows(f) && !directFeatures.contains(f),
      );

      if (hasMore) {
        tabs.add(NavTab(
          feature: null,
          icon: SolarIconsOutline.menuDots,
          activeIcon: SolarIconsBold.menuDots,
          label: tr.navMore,
          isMore: true,
        ));
      }
    }

    return tabs;
  }
}
