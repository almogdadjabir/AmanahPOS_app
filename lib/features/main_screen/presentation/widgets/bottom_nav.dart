import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

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
        final tabs = buildTabs(
          context,
          state.permissions,
          isPremium: isPremium,
        );
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

    // One fixed order for every role: Home (owner only), Sell, Products,
    // Stock, More. Roles and business types only remove tabs, they never
    // reorder them, so a tab is always where the hand expects it.
    if (perms.isOwner && perms.canAccessBusiness) {
      tabs.add(
        NavTab(
          feature: AppFeature.business,
          icon: PhosphorIconsRegular.house,
          activeIcon: PhosphorIconsFill.house,
          label: tr.navHome,
        ),
      );
    }

    tabs.add(
      NavTab(
        feature: AppFeature.pos,
        icon: PhosphorIconsRegular.cashRegister,
        activeIcon: PhosphorIconsFill.cashRegister,
        label: tr.navSell,
      ),
    );

    if (perms.canAccessProducts) {
      tabs.add(
        NavTab(
          feature: AppFeature.products,
          icon: PhosphorIconsRegular.tag,
          activeIcon: PhosphorIconsFill.tag,
          label: tr.navProducts,
        ),
      );
    }

    if (perms.canAccessInventory) {
      tabs.add(
        NavTab(
          feature: AppFeature.inventory,
          icon: PhosphorIconsRegular.package,
          activeIcon: PhosphorIconsFill.package,
          label: tr.navInventory,
          showPremiumIndicator: isPremium,
        ),
      );
    }

    final directFeatures = tabs.map((t) => t.feature).toSet();
    final hasMore =
        perms.isOwner ||
        AppFeature.values.any(
          (f) => perms.allows(f) && !directFeatures.contains(f),
        );

    if (hasMore) {
      tabs.add(
        NavTab(
          feature: null,
          icon: PhosphorIconsRegular.dotsThree,
          activeIcon: PhosphorIconsRegular.dotsThree,
          label: tr.navMore,
          isMore: true,
        ),
      );
    }

    return tabs;
  }
}
