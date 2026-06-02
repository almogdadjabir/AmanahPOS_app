import 'package:amana_pos/core/responsive/breakpoints.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

extension LayoutMetrics on BuildContext {
  EdgeInsets get pagePadding => responsive(
        mobile:  const EdgeInsets.all(AppSpacing.md),
        tablet:  const EdgeInsets.all(AppSpacing.xl),
        desktop: const EdgeInsets.all(AppSpacing.xxl),
      );

  double get sectionGap =>
      responsive(mobile: AppSpacing.lg, desktop: AppSpacing.xxl);

  double get maxContentWidth => Breakpoints.large;

  int gridColumnsFor(double maxWidth, {double tile = 180}) =>
      (maxWidth / tile).floor().clamp(2, 8);
}
