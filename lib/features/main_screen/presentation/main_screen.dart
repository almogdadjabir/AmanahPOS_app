import 'package:amana_pos/features/dashboard/presentation/feature_menu/feature_menu.dart';
import 'package:amana_pos/features/dashboard/presentation/widgets/pos_app_bar.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: AppDims.appBarHeight,
        title: PosAppBar(
          onMenuTap: () => context
              .read<NavigationBloc>()
              .add(const SetMenuOpenEvent(open: true)),
          onNotifTap: () {},
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<NavigationBloc, NavigationState>(
          buildWhen: (prev, curr) => prev.selectedIndex != curr.selectedIndex,
          builder: (context, state) {
            return Stack(
              children: [
                state.screens[state.selectedIndex].child,
                const FeatureMenu(),
              ],
            );
          },
        ),
      ),
    );
  }
}
