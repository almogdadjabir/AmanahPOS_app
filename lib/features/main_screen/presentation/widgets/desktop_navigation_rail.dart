import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/bottom_nav.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopNavigationRail extends StatefulWidget {
  const DesktopNavigationRail({super.key});

  @override
  State<DesktopNavigationRail> createState() => _DesktopNavigationRailState();
}

class _DesktopNavigationRailState extends State<DesktopNavigationRail> {
  bool _extended = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        final allTabs = BottomNav.buildTabs(context, state.permissions);
        final railTabs =
            allTabs.where((t) => t.feature != AppFeature.pos).toList();
        final isPosActive = state.currentFeature == AppFeature.pos;

        final activeIdx = _activeIndex(railTabs, state.currentFeature);
        final colors = context.appColors;

        return NavigationRail(
          extended: _extended,
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
          onDestinationSelected: (i) => _onTap(context, railTabs[i]),
          leading: GestureDetector(
            onTap: () => setState(() => _extended = !_extended),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.lg, bottom: AppSpacing.md),
              child: const BrandLogo(),
            ),
          ),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: _SellFab(
                  isActive: isPosActive,
                  extended: _extended,
                  label: context.tr.navSell,
                ),
              ),
            ),
          ),
          destinations: [
            for (final tab in railTabs)
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

  int? _activeIndex(List<NavTab> railTabs, AppFeature? currentFeature) {
    if (currentFeature == AppFeature.pos) return null;
    for (int i = 0; i < railTabs.length; i++) {
      final tab = railTabs[i];
      if (tab.isMore) {
        final directFeatures = railTabs
            .where((t) => !t.isMore && t.feature != null)
            .map((t) => t.feature!)
            .toSet();
        if (!directFeatures.contains(currentFeature)) return i;
      } else if (tab.feature == currentFeature) {
        return i;
      }
    }
    return null;
  }

  void _onTap(BuildContext context, NavTab tab) {
    if (tab.isMore) {
      Navigator.of(context).pushNamed(RouteStrings.settingsScreen);
      return;
    }
    if (tab.feature != null) {
      context
          .read<NavigationBloc>()
          .add(NavigationFeatureSelected(tab.feature!));
    }
  }
}

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
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
