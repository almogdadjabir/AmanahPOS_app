import 'package:amana_pos/features/main_screen/presentation/offline_preparation_listener.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/pos_app_bar.dart';
import 'package:amana_pos/features/feature_menu/feature_menu.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OfflinePreparationListener(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: AppDims.appBarHeight,
          title: PosAppBar(
            onMenuTap: () =>
                context.read<NavigationBloc>().add(const SetMenuOpenEvent()),
            onNotifTap: () {},
          ),
        ),
        body: BlocBuilder<NavigationBloc, NavigationState>(
          // Only rebuild when the active screen changes.
          buildWhen: (prev, curr) =>
          prev.currentFeature != curr.currentFeature,
          builder: (context, state) {
            return Stack(
              children: [
                state.currentScreen,
                const FeatureMenu(),
              ],
            );
          },
        ),
      ),
    );
  }
}

