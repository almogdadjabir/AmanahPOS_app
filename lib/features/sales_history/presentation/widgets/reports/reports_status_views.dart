import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/shimmer.dart';

const _kLoadingSkeletonIconSize = 48.0;
const _kErrorIconSize = 40.0;

/// Loading skeleton for reports: one soft pulse over the whole layout.
class ReportsLoadingSkeleton extends StatelessWidget {
  const ReportsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.appColors.surfaceSoft;

    Widget block(double height, double radius, {EdgeInsetsGeometry? margin}) {
      return Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppSkeleton(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
          child: Column(
            children: [
              // KPI cards row: 5 cards
              Row(
                children: List.generate(
                  5,
                  (index) => Expanded(
                    child: block(
                      72,
                      AppDims.rMd,
                      margin: EdgeInsetsDirectional.only(
                        start: index == 0 ? 0 : AppDims.s2,
                        end: index == 4 ? 0 : AppDims.s2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s4),
              // Main chart row (2/3 + 1/3)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: block(400, AppDims.rXl)),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      children: [
                        block(192, AppDims.rXl),
                        const SizedBox(height: AppDims.s3),
                        block(192, AppDims.rXl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDims.s3),
              // Bottom row: 3 equal cards
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: block(
                      240,
                      AppDims.rXl,
                      margin: EdgeInsetsDirectional.only(
                        start: index == 0 ? 0 : AppDims.s3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for no sales in the selected period.
class ReportsEmptyView extends StatelessWidget {
  const ReportsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  PhosphorIconsRegular.chartBar,
                  size: _kLoadingSkeletonIconSize,
                  color: context.appColors.textHint,
                )
                .mAnimate()
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AppDims.s3),
            Text(
                  context.tr.reportsNoSalesInRange,
                  style: AppTextStyles.bs200(
                    context,
                  ).copyWith(color: context.appColors.textHint),
                )
                .mAnimate(delay: 100.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

/// Error state with retry button.
class ReportsErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const ReportsErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  PhosphorIconsRegular.xCircle,
                  size: _kErrorIconSize,
                  color: context.appColors.danger,
                )
                .mAnimate()
                .fadeIn(duration: 300.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AppDims.s3),
            Text(
                  (message?.isNotEmpty == true)
                      ? message!
                      : context.tr.reportsLoadError,
                  style: AppTextStyles.bs200(
                    context,
                  ).copyWith(color: context.appColors.textSecondary),
                  textAlign: TextAlign.center,
                )
                .mAnimate(delay: 80.ms)
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.1),
            const SizedBox(height: AppDims.s3),
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr.retry),
            ).mAnimate(delay: 160.ms).fadeIn(duration: 280.ms),
          ],
        ),
      ),
    );
  }
}
