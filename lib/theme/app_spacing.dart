import 'package:flutter/material.dart';

abstract final class AppSpacing {
  AppSpacing._();

  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 56;
}

abstract final class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;

  static BorderRadius get borderXs => BorderRadius.circular(xs);
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderXxl => BorderRadius.circular(xxl);
}

abstract final class AppPadding {
  AppPadding._();

  static EdgeInsets all(double value) => EdgeInsets.all(value);

  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  static const EdgeInsets none = EdgeInsets.zero;
  static const EdgeInsets xs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets sm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets md = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets lg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets xl = EdgeInsets.all(AppSpacing.xl);

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.md,
  );
}

abstract final class AppGap {
  AppGap._();

  static const SizedBox verticalXs = SizedBox(height: AppSpacing.xs);
  static const SizedBox verticalSm = SizedBox(height: AppSpacing.sm);
  static const SizedBox verticalMd = SizedBox(height: AppSpacing.md);
  static const SizedBox verticalLg = SizedBox(height: AppSpacing.lg);
  static const SizedBox verticalXl = SizedBox(height: AppSpacing.xl);
  static const SizedBox verticalXxl = SizedBox(height: AppSpacing.xxl);

  static const SizedBox horizontalXs = SizedBox(width: AppSpacing.xs);
  static const SizedBox horizontalSm = SizedBox(width: AppSpacing.sm);
  static const SizedBox horizontalMd = SizedBox(width: AppSpacing.md);
  static const SizedBox horizontalLg = SizedBox(width: AppSpacing.lg);
  static const SizedBox horizontalXl = SizedBox(width: AppSpacing.xl);
}