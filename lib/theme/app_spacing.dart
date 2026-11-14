import 'package:flutter/material.dart';

/// Spacing, radii, component sizes and motion tokens.
class AppDims {
  AppDims._();

  // Spacing
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;

  // Radii: 6 / 8 / 12 / 16 / 24 / pill
  static const double rXs = 6;
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 24;
  static const double rPill = 999;

  static BorderRadius get borderXs => BorderRadius.circular(rXs);
  static BorderRadius get borderSm => BorderRadius.circular(rSm);
  static BorderRadius get borderMd => BorderRadius.circular(rMd);
  static BorderRadius get borderLg => BorderRadius.circular(rLg);
  static BorderRadius get borderXl => BorderRadius.circular(rXl);
  static BorderRadius get borderPill => BorderRadius.circular(rPill);

  // Component sizes
  static const double appBarHeight = 56;
  static const double cartPeekHeight = 76;
  static const double buttonHeight = 48;
  static const double buttonHeightLarge = 56;
  static const double buttonHeightSmall = 36;

  // Motion: fast 120, base 180, slow 280
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 280);
  static const Duration sheet = Duration(milliseconds: 260);

  static const double pressScale = 0.97;
  static const Curve ease = Cubic(0.2, 0, 0, 1);
  static const Curve soft = Cubic(0.16, 1, 0.3, 1);
  static const Curve sheetCurve = Cubic(0.32, 0.72, 0, 1);
}
