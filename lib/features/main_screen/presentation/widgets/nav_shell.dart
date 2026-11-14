import 'dart:ui';

import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavShell extends StatelessWidget {
  final List<NavTab> tabs;
  final NavigationState state;

  const NavShell({super.key, required this.tabs, required this.state});

  /// Content height of the tab bar, above the bottom safe area.
  static const double contentHeight = 49;

  int _activeIndex() {
    final directFeatures = tabs
        .where((t) => !t.isMore && t.feature != null)
        .map((t) => t.feature!)
        .toSet();

    for (int i = 0; i < tabs.length; i++) {
      final tab = tabs[i];

      if (tab.isMore) {
        if (!directFeatures.contains(state.currentFeature)) return i;
      } else if (state.currentFeature == tab.feature) {
        return i;
      }
    }

    return 0;
  }

  void _onTap(BuildContext context, NavTab tab) {
    if (tab.isMore) {
      HapticFeedback.selectionClick();
      Navigator.of(context).pushNamed(RouteStrings.settingsScreen);
      return;
    }

    final feature = tab.feature;
    if (feature == null) return;
    if (feature == state.currentFeature) return;

    HapticFeedback.selectionClick();
    context.read<NavigationBloc>().add(NavigationFeatureSelected(feature));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeIdx = _activeIndex();
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.78),
            border: BorderDirectional(
              top: BorderSide(
                color: colors.borderStrong.withValues(alpha: 0.45),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: safeBottom),
            child: SizedBox(
              height: contentHeight,
              child: Row(
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _TabItem(
                        tab: tabs[i],
                        isActive: i == activeIdx,
                        onTap: () => _onTap(context, tabs[i]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final duration = Motion.duration(AppDims.fast);
    final showFill = isActive && !tab.isMore;

    final labelColor = isActive ? colors.primary : colors.textHint;

    final glyph = SizedBox(
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            showFill ? tab.activeIcon : tab.icon,
            size: 26,
            color: labelColor,
          ),
          if (tab.showPremiumIndicator)
            PositionedDirectional(
              top: 0,
              end: -5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.premium,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
            ),
        ],
      ),
    );

    return Pressable(
      onTap: onTap,
      semanticLabel: tab.label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glyph,
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: duration,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 10,
              height: 1.1,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
            child: Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
