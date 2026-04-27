import 'package:amana_pos/utilities/responsive_size.dart';
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'NunitoSans';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // SMALL (10-14)
  static TextStyle sm100(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 10),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  static TextStyle sm200(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 12),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 14 / 12,
    );
  }

  static TextStyle sm300(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 14),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 18 / 14,
    );
  }

  // BASIC (16-40)
  static TextStyle smallBold(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 16),
      fontWeight: weight ?? bold,
      color: color,
      letterSpacing: 0,
      height: 20 / 16,
    );
  }

  static TextStyle bs100(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 16),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 20 / 16,
    );
  }

  static TextStyle bs200(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 18),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 22 / 18,
    );
  }

  static TextStyle bs300(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 20),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 26 / 20,
    );
  }

  static TextStyle bs400(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 24),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 28/24,
    );
  }

  static TextStyle bs500(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 28),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 32 / 28,
    );
  }

  static TextStyle bs600(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 32),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  static TextStyle bs800(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 40),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 44 / 40,
    );
  }

  // LARGE (42-72)
  static TextStyle lg100(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 42),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
      height: 44 / 42,
    );
  }

  static TextStyle lg200(BuildContext context, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: ResponsiveSize.getResponsiveFontSize(context, 48),
      fontWeight: weight ?? regular,
      color: color,
      letterSpacing: 0,
    );
  }

  static TextTheme buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: _style(48, extraBold, textColor, height: 1.08),
      displayMedium: _style(40, extraBold, textColor, height: 1.1),
      displaySmall: _style(34, bold, textColor, height: 1.12),

      headlineLarge: _style(30, bold, textColor, height: 1.16),
      headlineMedium: _style(26, bold, textColor, height: 1.18),
      headlineSmall: _style(22, semibold, textColor, height: 1.22),

      titleLarge: _style(20, semibold, textColor, height: 1.25),
      titleMedium: _style(18, semibold, textColor, height: 1.3),
      titleSmall: _style(16, semibold, textColor, height: 1.35),

      bodyLarge: _style(16, regular, textColor, height: 1.45),
      bodyMedium: _style(14, regular, textColor, height: 1.45),
      bodySmall: _style(12, regular, textColor, height: 1.4),

      labelLarge: _style(14, semibold, textColor, height: 1.2),
      labelMedium: _style(12, semibold, textColor, height: 1.2),
      labelSmall: _style(11, medium, textColor, height: 1.15),
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
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.1,
    );
  }
}