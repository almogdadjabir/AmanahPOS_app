import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_more_drawer.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_navigation_rail.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_top_bar.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  static const double _topBarHeight = 74;

  bool _railExtended = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const DesktopMoreDrawer(),
      body: Row(
        children: [
          DesktopNavigationRail(extended: _railExtended),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.border,
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: _topBarHeight,
                  child: DesktopTopBar(
                    railExtended: _railExtended,
                    onMenuTap: () =>
                        setState(() => _railExtended = !_railExtended),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: colors.border),
                Expanded(
                  child: BlocBuilder<NavigationBloc, NavigationState>(
                    buildWhen: (prev, curr) =>
                        prev.currentFeature != curr.currentFeature,
                    builder: (context, state) => state.currentScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
