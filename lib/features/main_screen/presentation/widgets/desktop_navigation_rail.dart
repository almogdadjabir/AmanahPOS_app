import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopNavigationRail extends StatelessWidget {
  const DesktopNavigationRail({super.key, required this.extended});

  /// Whether the rail is in its expanded (labelled) state.
  /// Driven by the hamburger toggle in [DesktopTopBar] via [DesktopShell].
  final bool extended;

  /// Builds every feature tab the user is allowed to see on desktop.
  /// Order reflects priority — most-used first.
  static List<NavTab> _buildAllTabs(
    BuildContext context,
    AppPermissions perms,
  ) {
    final tr = context.tr;
    final tabs = <NavTab>[];

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
      ));
    }
    if (perms.canAccessSalesHistory) {
      tabs.add(NavTab(
        feature: AppFeature.salesHistory,
        icon: SolarIconsOutline.notebook,
        activeIcon: SolarIconsBold.notebook,
        label: tr.settingsSalesHistory,
      ));
    }
    if (perms.canAccessCategories) {
      tabs.add(NavTab(
        feature: AppFeature.categories,
        icon: SolarIconsOutline.layers,
        activeIcon: SolarIconsBold.layers,
        label: tr.settingsCategories,
      ));
    }
    if (perms.canAccessCustomers) {
      tabs.add(NavTab(
        feature: AppFeature.customers,
        icon: SolarIconsOutline.usersGroupRounded,
        activeIcon: SolarIconsBold.usersGroupRounded,
        label: tr.settingsCustomers,
      ));
    }
    if (perms.canAccessUsers) {
      tabs.add(NavTab(
        feature: AppFeature.users,
        icon: SolarIconsOutline.userPlus,
        activeIcon: SolarIconsBold.userPlus,
        label: tr.navCashiers,
      ));
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        final allTabs = _buildAllTabs(context, state.permissions);

        final isPosActive = state.currentFeature == AppFeature.pos;
        final activeIdx = _activeRailIndex(allTabs, state.currentFeature);
        final colors = context.appColors;

        return NavigationRail(
          extended: extended,
          minWidth: 76,
          minExtendedWidth: 248,
          backgroundColor: colors.surface,
          groupAlignment: -1,
          selectedIndex: activeIdx,
          indicatorColor: colors.primary.withValues(alpha: 0.12),
          selectedIconTheme: IconThemeData(color: colors.primary),
          selectedLabelTextStyle: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedIconTheme: IconThemeData(color: colors.textSecondary),
          unselectedLabelTextStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
          onDestinationSelected: (i) {
            final feature = allTabs[i].feature;
            if (feature != null) {
              context
                  .read<NavigationBloc>()
                  .add(NavigationFeatureSelected(feature));
            }
          },
          leading: const Padding(
            padding: EdgeInsetsDirectional.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: AmanaPosLogoMark(size: 44),
          ),
          trailing: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SettingsButton(extended: extended),
                const SizedBox(height: AppSpacing.md),
                _SellFab(
                  isActive: isPosActive,
                  extended: extended,
                  label: context.tr.navSell,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          destinations: [
            for (final tab in allTabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: Text(tab.label),
              ),
          ],
        );
      },
    );
  }

  static int? _activeRailIndex(List<NavTab> tabs, AppFeature? currentFeature) {
    if (currentFeature == AppFeature.pos) return null;
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].feature == currentFeature) return i;
    }
    return null;
  }
}

// ── Settings button ───────────────────────────────────────────────────────────

class _SettingsButton extends StatelessWidget {
  final bool extended;

  const _SettingsButton({required this.extended});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(RouteStrings.settingsScreen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: extended ? 200 : 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.settings,
              size: 22,
              color: colors.textSecondary,
            ),
            if (extended) ...[
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  context.tr.navSettings,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sell FAB ──────────────────────────────────────────────────────────────────

class _SellFab extends StatelessWidget {
  const _SellFab({
    required this.isActive,
    required this.extended,
    required this.label,
  });

  final bool isActive;
  final bool extended;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => context
          .read<NavigationBloc>()
          .add(const NavigationFeatureSelected(AppFeature.pos)),
      child: AnimatedContainer(
        duration: AppDims.fast,
        width: extended ? 200 : 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isActive ? colors.primary : colors.surfaceSoft,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.cartLarge_4,
              color: isActive ? Colors.white : colors.textSecondary,
              size: 24,
            ),
            if (extended) ...[
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.white : colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
