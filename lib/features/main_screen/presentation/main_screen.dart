import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/offline_preparation_listener.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/main_bottom_area.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/pos_app_bar.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const double _appBarHeight = 74;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: colors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // iOS
    )
        : SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: colors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: OfflinePreparationListener(
        child: Scaffold(
          extendBody: true,
          backgroundColor: colors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: _appBarHeight,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: colors.background,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            systemOverlayStyle: overlayStyle,
            title: const PosAppBar(),
          ),
          body: BlocBuilder<NavigationBloc, NavigationState>(
            buildWhen: (prev, curr) =>
            prev.currentFeature != curr.currentFeature,
            builder: (context, state) => state.currentScreen,
          ),
          bottomNavigationBar: const MainBottomArea(),
        ),
      ),
    );
  }
}