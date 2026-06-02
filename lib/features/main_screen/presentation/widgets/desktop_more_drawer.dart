import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

// Must match the constant in desktop_navigation_rail.dart.
const _kMaxRailDestinations = 6;

/// Desktop slide-in drawer for overflow features + Settings.
/// Self-contained: reads permissions from NavigationBloc, computes its
/// own overflow list, no parameters required.
class DesktopMoreDrawer extends StatelessWidget {
  const DesktopMoreDrawer({super.key});

  // Builds every permitted feature tab in priority order.
  // Kept in sync with _buildAllTabs() in desktop_navigation_rail.dart.
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
          prev.permissions != curr.permissions ||
          prev.currentFeature != curr.currentFeature,
      builder: (context, state) {
        final allTabs = _buildAllTabs(context, state.permissions);
        final overflowTabs = allTabs.skip(_kMaxRailDestinations).toList();
        final colors = context.appColors;

        return Drawer(
          width: 280,
          backgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(AppRadius.xl),
              bottomRight: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDims.s4, AppDims.s4, AppDims.s3, AppDims.s3),
                  child: Row(
                    children: [
                      const BrandLogo(),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDims.s2),
                            child: Icon(
                              SolarIconsOutline.closeCircle,
                              size: 20,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colors.border),

                // Overflow features (if any)
                if (overflowTabs.isNotEmpty) ...[
                  const SizedBox(height: AppDims.s2),
                  _DrawerSection(
                    label: 'MORE',
                    children: [
                      for (final tab in overflowTabs)
                        _DrawerFeatureTile(tab: tab),
                    ],
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.border,
                    indent: AppDims.s4,
                    endIndent: AppDims.s4,
                  ),
                ],

                const SizedBox(height: AppDims.s2),

                // Settings
                _DrawerSection(
                  label: 'PREFERENCES',
                  children: [
                    _DrawerTile(
                      icon: SolarIconsOutline.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(RouteStrings.settingsScreen);
                      },
                    ),
                  ],
                ),

                const Spacer(),

                // Footer
                Divider(height: 1, thickness: 1, color: colors.border),
                Padding(
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Text(
                    'AmanaPOS',
                    style: AppTextStyles.bs100(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _DrawerSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _DrawerSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s2, AppDims.s4, AppDims.s2),
          child: Text(
            label,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: AppDims.s2),
      ],
    );
  }
}

// ── Feature tile ──────────────────────────────────────────────────────────────

class _DrawerFeatureTile extends StatelessWidget {
  final NavTab tab;
  const _DrawerFeatureTile({required this.tab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) => prev.currentFeature != curr.currentFeature,
      builder: (context, state) {
        final isActive =
            tab.feature != null && state.currentFeature == tab.feature;
        return _DrawerTile(
          icon: isActive ? tab.activeIcon : tab.icon,
          label: tab.label,
          isActive: isActive,
          onTap: () {
            Navigator.of(context).pop();
            if (tab.feature != null) {
              context
                  .read<NavigationBloc>()
                  .add(NavigationFeatureSelected(tab.feature!));
            }
          },
        );
      },
    );
  }
}

// ── Generic tile ──────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(
              horizontal: AppDims.s2, vertical: 2),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s3, vertical: AppDims.s3),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: isActive ? colors.primary : colors.textPrimary,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
