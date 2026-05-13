import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/nav_tab.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/bottom_nav.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/bottom_nav_item.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/more_sheet.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavShell extends StatelessWidget {
  final List<NavTab> tabs;
  final NavigationState state;

  const NavShell({super.key, required this.tabs, required this.state});

  int _activeIndex() {
    final directFeatures = tabs
        .where((t) => !t.isMore)
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

  void _onTap(BuildContext context, int index) {
    final tab = tabs[index];
    if (tab.isMore) {
      _openMoreSheet(context);
    } else {
      context
          .read<NavigationBloc>()
          .add(NavigationFeatureSelected(tab.feature!));
    }
  }

  void _openMoreSheet(BuildContext context) {
    final navBloc = context.read<NavigationBloc>();
    final authState = context.read<AuthBloc>().state;

    final directFeatures = tabs
        .where((t) => !t.isMore)
        .map((t) => t.feature!)
        .toSet();

    final moreItems = kFeatureConfigs.entries
        .where((e) =>
    state.permissions.allows(e.key) && !directFeatures.contains(e.key))
        .map((e) => e.value)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: navBloc,
        child: MoreSheet(
          items: moreItems,
          currentFeature: state.currentFeature,
          userName: authState.profile?.fullName ?? authState.profile?.phone,
          isOwner: state.permissions.isOwner,
          businessName: authState.defaultBusiness?.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeIdx = _activeIndex();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < tabs.length; i++)
                Expanded(
                  child: BottomNavItem(
                    icon: i == activeIdx ? tabs[i].activeIcon : tabs[i].icon,
                    label: tabs[i].label,
                    isActive: i == activeIdx,
                    onTap: () => _onTap(context, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}