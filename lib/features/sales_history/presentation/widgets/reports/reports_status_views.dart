import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

const _kLoadingSkeletonIconSize = 48.0;
const _kErrorIconSize = 40.0;

/// A skeleton placeholder for reports that are loading.
///
/// Displays a layout with shimmer boxes mimicking KPI cards and chart areas.
class ReportsLoadingSkeleton extends StatelessWidget {
  const ReportsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final skeletonColor = colors.border.withAlpha(60);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
        child: Column(
          children: [
            // KPI Cards Row
            Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Container(
                    height: 64,
                    margin: EdgeInsets.only(
                      left: index == 0 ? AppDims.s4 : AppDims.s2,
                      right: index == 3 ? AppDims.s4 : AppDims.s2,
                    ),
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppDims.rXl),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDims.s4),
            // Chart and Details Row
            Row(
              children: [
                // Large chart placeholder (2/3 width)
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 280,
                    margin: const EdgeInsets.only(left: AppDims.s4),
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppDims.rXl),
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                // Details column (1/3 width)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        height: 135,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(AppDims.rXl),
                        ),
                      ),
                      const SizedBox(height: AppDims.s3),
                      Container(
                        height: 135,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(AppDims.rXl),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state view for reports with no sales in the selected period.
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
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              context.tr.reportsNoSalesInRange,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state view for failed report loads.
///
/// Displays an error message and a retry button to allow the user to
/// retry loading the report.
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
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              (message?.isNotEmpty == true) ? message! : context.tr.reportsLoadError,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDims.s3),
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr.retry),
            ),
          ],
        ),
      ),
    );
  }
}
