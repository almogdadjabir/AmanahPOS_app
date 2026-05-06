import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/offline/presentation/widgets/footer_status.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_hero.dart';
import 'package:amana_pos/core/offline/presentation/widgets/preparation_steps.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreparingOfflineScreen {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;

    isShowing = true;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Preparing Offline Mode',
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
                return Column(
                  children: [
                    const Spacer(),

                    const OfflineHero()
                        .animate()
                        .fadeIn(duration: 420.ms)
                        .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s6),

                    Text(
                      'Preparing Offline Mode',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.lg200(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 420.ms)
                        .slideY(
                      begin: 0.16,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s2),

                    Text(
                      _description(state),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 90.ms, duration: 420.ms)
                        .slideY(
                      begin: 0.16,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s6),

                    PreparationSteps(state: state)
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 420.ms)
                        .slideY(
                      begin: 0.12,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const Spacer(),

                    FooterStatus(state: state)
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 420.ms)
                        .slideY(
                      begin: 0.22,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s2),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _description(OfflineStatusState state) {
    if (state.connectionStatus == OfflineConnectionStatus.offline) {
      return 'Internet is required only for the first setup. Please connect once so AmanaPOS can prepare your business for offline use.';
    }

    if (state.isBootstrapLoading) {
      return 'Please keep the app open while we download your business data, products, categories, stock, and customers.';
    }

    if (state.isAssetsLoading) {
      return 'Your business data is ready. We are updating product and category assets in the background.';
    }

    if (state.hasFailure) {
      return state.errorMessage ?? 'Something went wrong while preparing offline mode.';
    }

    return 'Almost done. AmanaPOS is getting your workspace ready for poor internet and offline sales.';
  }
}