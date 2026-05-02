import 'package:amana_pos/features/business/presentation/widgets/add_business_sheet.dart';
import 'package:amana_pos/features/business/presentation/widgets/feature_slider.dart';
import 'package:amana_pos/features/business/presentation/widgets/floating_store_hero.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FancyBusinessBottomSheet {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;

    isShowing = true;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Create Business Required',
      useRootNavigator: true,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) {
        return _CreateBusinessRequiredScreen(parentContext: context);
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

  static void reset() {
    isShowing = false;
  }
}

class _CreateBusinessRequiredScreen extends StatelessWidget {
  final BuildContext parentContext;

  const _CreateBusinessRequiredScreen({
    required this.parentContext,
  });

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
            child: Column(
              children: [
                const Spacer(),

                const FloatingStoreHero(),

                const SizedBox(height: AppDims.s6),

                Text(
                  'Welcome to AmanaPOS',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.lg200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: AppDims.s2),

                Text(
                  'Create your first business to unlock your workspace and start running smarter sales operations.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 90.ms, duration: 420.ms)
                    .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: AppDims.s6),

                const FeatureSlider()
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 420.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {
                      Future.delayed(const Duration(milliseconds: 180), () {
                        if (!parentContext.mounted) return;
                        showAddBusinessSheet(parentContext);
                      });
                    },
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Create My Business'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      textStyle: AppTextStyles.bs600(context).copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 420.ms)
                    .slideY(begin: 0.22, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: AppDims.s3),

                Text(
                  'This step is required before using AmanaPOS.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 330.ms, duration: 420.ms),

                const SizedBox(height: AppDims.s2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


