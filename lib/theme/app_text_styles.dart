import 'package:amana_pos/utilities/responsive_size.dart';
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Geist';
  static const String fontFamilyArabic = 'IBMPlexSansArabic';
  static const List<String> fontFallback = [fontFamilyArabic];

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // SMALL (10-14)
  static TextStyle sm100(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 11),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  static TextStyle sm200(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 12),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 14 / 12,
    );
  }

  static TextStyle sm300(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 13),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 18 / 14,
    );
  }

  // BASIC (16-40)
  static TextStyle smallBold(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 15),
      fontWeight: weight ?? bold,
      color: color,
      letterSpacing: 0,
      height: 20 / 16,
    );
  }

  static TextStyle bs100(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 15),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 20 / 16,
    );
  }

  static TextStyle bs200(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 16),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 22 / 18,
    );
  }

  static TextStyle bs300(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 17),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 26 / 20,
    );
  }

  static TextStyle bs400(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 18),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 28 / 24,
    );
  }

  static TextStyle bs500(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 20),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 32 / 28,
    );
  }

  static TextStyle bs600(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 22),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  static TextStyle bs700(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 26),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  static TextStyle bs800(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 30),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 44 / 40,
    );
  }

  static TextStyle bs900(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 40),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 66 / 60,
    );
  }

  // LARGE (42-72)
  static TextStyle lg100(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 34),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 44 / 42,
    );
  }

  static TextStyle lg200(
    BuildContext context, {
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 40),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Type scale (Apple-calm). Arabic joins only with zero letter-spacing,
  /// so tracking stays 0 everywhere.
  static TextTheme buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: _style(40, bold, textColor, height: 1.1),
      displayMedium: _style(34, bold, textColor, height: 1.12),
      displaySmall: _style(28, bold, textColor, height: 1.16),

      headlineLarge: _style(28, bold, textColor, height: 1.18),
      headlineMedium: _style(24, semibold, textColor, height: 1.2),
      headlineSmall: _style(22, semibold, textColor, height: 1.22),

      titleLarge: _style(20, semibold, textColor, height: 1.25),
      titleMedium: _style(17, semibold, textColor, height: 1.3),
      titleSmall: _style(15, semibold, textColor, height: 1.33),

      bodyLarge: _style(16, regular, textColor, height: 1.45),
      bodyMedium: _style(14, regular, textColor, height: 1.45),
      bodySmall: _style(12, regular, textColor, height: 1.4),

      labelLarge: _style(14, medium, textColor, height: 1.25),
      labelMedium: _style(12, medium, textColor, height: 1.25),
      labelSmall: _style(11, medium, textColor, height: 1.2),
    );
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: 0,
    );
  }
}

extension AppTextStyleNumeric on TextStyle {
  /// Tabular figures so amounts and counts align in columns.
  TextStyle get tabular => copyWith(fontFeatures: AppTextStyles.tabularFigures);
}
