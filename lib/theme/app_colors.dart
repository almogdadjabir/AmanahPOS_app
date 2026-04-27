import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // Brand - POS identity
  static const Color primary = Color(0xFF0F766E); // Emerald
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFFCCFBF1);

  static const Color secondary = Color(0xFFF59E0B); // Amber
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFFEF3C7);

  // Neutral / Slate
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // POS-specific
  static const Color sale = Color(0xFF0F766E);
  static const Color refund = Color(0xFFDC2626);
  static const Color cash = Color(0xFFF59E0B);
  static const Color card = Color(0xFF2563EB);
  static const Color stockLow = Color(0xFFEA580C);
  static const Color profit = Color(0xFF16A34A);

  // Light theme semantic colors
  static const Color lightBackground = slate50;
  static const Color lightSurface = white;
  static const Color lightSurfaceSoft = slate100;
  static const Color lightBorder = slate200;
  static const Color lightTextPrimary = slate900;
  static const Color lightTextSecondary = slate600;
  static const Color lightTextHint = slate400;
  static const Color lightDisabled = slate300;

  // Dark theme semantic colors
  static const Color darkBackground = slate950;
  static const Color darkSurface = Color(0xFF0B1220);
  static const Color darkSurfaceSoft = slate900;
  static const Color darkBorder = slate800;
  static const Color darkTextPrimary = slate50;
  static const Color darkTextSecondary = slate300;
  static const Color darkTextHint = slate500;
  static const Color darkDisabled = slate700;

  // Shadows
  static const Color lightShadow = Color(0x140F172A);
  static const Color darkShadow = Color(0x66000000);
}