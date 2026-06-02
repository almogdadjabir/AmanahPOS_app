import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/desktop_navigation_rail.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/pos_app_bar.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  static const double _topBarHeight = 74;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const DesktopNavigationRail(),
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
                  child: const PosAppBar(),
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
