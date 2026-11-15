import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/offline/presentation/widgets/footer_status.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_hero.dart';
import 'package:amana_pos/core/offline/presentation/widgets/preparation_steps.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreparingOfflineScreen {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;

    isShowing = true;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Preparing offline mode',
      useRootNavigator: true,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) {
        return BlocProvider.value(
          value: getIt<OfflineStatusBloc>(),
          child: const _PreparingOfflineDialogBody(),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    isShowing = false;
  }

  static void close(BuildContext context) {
    if (!isShowing) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }

    isShowing = false;
  }

  static void reset() {
    isShowing = false;
  }
}

class _PreparingOfflineDialogBody extends StatelessWidget {
  const _PreparingOfflineDialogBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDims.s5),
            child: BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
              builder: (context, state) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(),

                            const OfflineHero(),

                            const SizedBox(height: AppDims.s6),

                            Text(
                              context.tr.poTitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.lg200(context).copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: AppDims.s2),

                            Text(
                              _description(context, state),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bs400(context).copyWith(
                                color: colors.textSecondary,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: AppDims.s6),

                            PreparationSteps(state: state),

                            const Spacer(),

                            FooterStatus(state: state),

                            const SizedBox(height: AppDims.s2),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _description(BuildContext context, OfflineStatusState state) {
    if (state.connectionStatus == OfflineConnectionStatus.offline) {
      return context.tr.poDescOffline;
    }

    if (state.isBootstrapLoading) {
      return context.tr.poDescBootstrap;
    }

    if (state.isAssetsLoading) {
      return context.tr.poDescAssets;
    }

    if (state.hasFailure) {
      return state.errorMessage ?? context.tr.poDescFailure;
    }

    return context.tr.poDescDefault;
  }
}
