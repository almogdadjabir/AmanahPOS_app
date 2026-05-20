import 'dart:ui';

import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/bottom_nav_item.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/pos_fab_nav_item.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavShell extends StatelessWidget {
  final List<NavTab> tabs;
  final NavigationState state;

  const NavShell({
    super.key,
    required this.tabs,
    required this.state,
  });

  static const double _barHeight = 86;
  static const double _fabSize = 74;
  static const double _fabLift = 26;
  static const double _fabGapWidth = 86;

  bool _isPosTab(NavTab tab) => tab.feature == AppFeature.pos;

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
      _openMoreSheet(context);
      return;
    }

    final feature = tab.feature;
    if (feature == null) return;
    if (feature == state.currentFeature) return;

    context.read<NavigationBloc>().add(
      NavigationFeatureSelected(feature),
    );
  }

  void _openMoreSheet(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteStrings.settingsScreen,
    );
  }

  List<NavTab> _normalTabs() {
    return tabs.where((tab) => !_isPosTab(tab)).toList();
  }

  NavTab? _posTab() {
    for (final tab in tabs) {
      if (_isPosTab(tab)) return tab;
    }
    return null;
  }

  int _activeNormalIndex(List<NavTab> normalTabs) {
    for (int i = 0; i < normalTabs.length; i++) {
      final tab = normalTabs[i];

      if (tab.isMore) {
        final directFeatures = tabs
            .where((t) => !t.isMore && t.feature != null)
            .map((t) => t.feature!)
            .toSet();

        if (!directFeatures.contains(state.currentFeature)) return i;
      } else if (tab.feature == state.currentFeature) {
        return i;
      }
    }

    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeIdx = _activeIndex();

    final posTab = _posTab();
    final normalTabs = _normalTabs();
    final hasPos = posTab != null;

    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final totalHeight = _barHeight + safeBottom + _fabLift;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            top: _fabLift,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.96),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: colors.primary.withValues(alpha: 0.14),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: _barHeight,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              _SlidingActiveIndicator(
                                width: constraints.maxWidth,
                                tabsCount: normalTabs.length,
                                activeIndex: _activeNormalIndex(normalTabs),
                                hasCenterFab: hasPos,
                                centerGapWidth: _fabGapWidth,
                                color: colors.primary,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: _buildNormalItems(
                                  context: context,
                                  tabs: normalTabs,
                                  activeIdx: activeIdx,
                                  hasPos: hasPos,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (hasPos)
            Positioned(
              top: 0,
              child: PosFabNavItem(
                size: _fabSize,
                label: posTab.label,
                icon: state.currentFeature == AppFeature.pos
                    ? posTab.activeIcon
                    : posTab.icon,
                isActive: state.currentFeature == AppFeature.pos,
                onTap: () => _onTap(context, posTab),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildNormalItems({
    required BuildContext context,
    required List<NavTab> tabs,
    required int activeIdx,
    required bool hasPos,
  }) {
    final widgets = <Widget>[];
    final centerGapIndex = hasPos ? (tabs.length / 2).ceil() : -1;

    for (int i = 0; i < tabs.length; i++) {
      if (hasPos && i == centerGapIndex) {
        widgets.add(
          const SizedBox(
            width: _fabGapWidth,
          ),
        );
      }

      final tab = tabs[i];
      final originalIndex = this.tabs.indexOf(tab);

      widgets.add(
        Expanded(
          child: BottomNavItem(
            icon: originalIndex == activeIdx ? tab.activeIcon : tab.icon,
            label: tab.label,
            isActive: originalIndex == activeIdx,
            onTap: () => _onTap(context, tab),
            showPremiumIndicator: tab.showPremiumIndicator,
          ),
        ),
      );
    }

    return widgets;
  }
}

class _SlidingActiveIndicator extends StatelessWidget {
  final double width;
  final int tabsCount;
  final int activeIndex;
  final bool hasCenterFab;
  final double centerGapWidth;
  final Color color;

  const _SlidingActiveIndicator({
    required this.width,
    required this.tabsCount,
    required this.activeIndex,
    required this.hasCenterFab,
    required this.centerGapWidth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (tabsCount == 0 || activeIndex < 0) {
      return const SizedBox.shrink();
    }

    final gapIndex = hasCenterFab ? (tabsCount / 2).ceil() : -1;
    final availableWidth = hasCenterFab ? width - centerGapWidth : width;
    final itemWidth = availableWidth / tabsCount;

    var left = itemWidth * activeIndex;

    if (hasCenterFab && activeIndex >= gapIndex) {
      left += centerGapWidth;
    }

    const dotSize = 6.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutExpo,
      left: left + ((itemWidth - dotSize) / 2),
      top: 8,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}