import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_icons/solar_icons.dart';

const _kLoadingSkeletonIconSize = 48.0;
const _kErrorIconSize = 40.0;

/// Shimmer-animated skeleton for loading reports.
class ReportsLoadingSkeleton extends StatelessWidget {
  const ReportsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseColor = colors.border.withAlpha(80);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
        child: Column(
          children: [
            // KPI Cards Row — 5 cards
            Row(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: Container(
                    height: 72,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : AppDims.s2,
                      right: index == 4 ? 0 : AppDims.s2,
                    ),
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                  )
                      .animate(delay: (index * 80).ms, onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 1200.ms,
                        color: Colors.white.withAlpha(60),
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppDims.s4),
            // Main chart row (2/3 + 1/3)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppDims.rXl),
                    ),
                  )
                      .animate(delay: 100.ms, onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 1400.ms,
                        color: Colors.white.withAlpha(60),
                      ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        height: 192,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppDims.rXl),
                        ),
                      )
                          .animate(delay: 200.ms, onPlay: (c) => c.repeat())
                          .shimmer(
                            duration: 1400.ms,
                            color: Colors.white.withAlpha(60),
                          ),
                      const SizedBox(height: AppDims.s3),
                      Container(
                        height: 192,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppDims.rXl),
                        ),
                      )
                          .animate(delay: 300.ms, onPlay: (c) => c.repeat())
                          .shimmer(
                            duration: 1400.ms,
                            color: Colors.white.withAlpha(60),
                          ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s3),
            // Bottom row — 3 equal cards
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 240,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : AppDims.s3,
                    ),
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(AppDims.rXl),
                    ),
                  )
                      .animate(
                        delay: (400 + index * 100).ms,
                        onPlay: (c) => c.repeat(),
                      )
                      .shimmer(
                        duration: 1400.ms,
                        color: Colors.white.withAlpha(60),
                      ),
                ),
              ),
            ),
          ],
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
              SolarIconsOutline.chartSquare,
              size: _kLoadingSkeletonIconSize,
              color: context.appColors.textHint,
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
            const SizedBox(height: AppDims.s3),
            Text(
              context.tr.reportsNoSalesInRange,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textHint,
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
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
              SolarIconsOutline.closeCircle,
              size: _kErrorIconSize,
              color: context.appColors.danger,
            ).animate().fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.7, 0.7),
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              (message?.isNotEmpty == true) ? message! : context.tr.reportsLoadError,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 80.ms).fadeIn(duration: 280.ms).slideY(begin: 0.1),
            const SizedBox(height: AppDims.s3),
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr.retry),
            ).animate(delay: 160.ms).fadeIn(duration: 280.ms),
          ],
        ),
      ),
    );
  }
}
