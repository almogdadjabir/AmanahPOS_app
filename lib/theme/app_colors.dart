import 'package:flutter/material.dart';

/// Raw Nile Ledger palette. Feature code reads colours from
/// `context.appColors`; hex values live only in `lib/theme/`.
abstract final class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5D56);
  static const Color primaryLight = Color(0xFFE8F5F2);

  // Cash (amber is for cash only)
  static const Color secondary = Color(0xFFB7791F);
  static const Color secondaryDark = Color(0xFF7A4E05);
  static const Color secondaryLight = Color(0xFFFBF1DC);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Legacy neutral scale, kept so older call sites compile; warm values.
  static const Color slate50 = Color(0xFFF6F4EF);
  static const Color slate100 = Color(0xFFEEEBE4);
  static const Color slate200 = Color(0xFFE5E1D8);
  static const Color slate300 = Color(0xFFCFC9BC);
  static const Color slate400 = Color(0xFF958E80);
  static const Color slate500 = Color(0xFF716B60);
  static const Color slate600 = Color(0xFF58534A);
  static const Color slate700 = Color(0xFF3A3630);
  static const Color slate800 = Color(0xFF24312F);
  static const Color slate900 = Color(0xFF1C1A17);
  static const Color slate950 = Color(0xFF0B1211);

  // Status
  static const Color success = Color(0xFF0E6B4E);
  static const Color successLight = Color(0xFFE5F3EB);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerLight = Color(0xFFFBE9E7);
  static const Color warning = Color(0xFF9A4508);
  static const Color warningLight = Color(0xFFFCEDE0);
  static const Color info = Color(0xFF2D5B88);
  static const Color infoLight = Color(0xFFE7EEF6);

  // POS-specific
  static const Color sale = primary;
  static const Color refund = danger;
  static const Color cash = Color(0xFFB7791F);
  static const Color card = Color(0xFF5B55D6);
  static const Color stockLow = warning;
  static const Color profit = success;

  // Light
  static const Color lightBackground = Color(0xFFF6F4EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSoft = Color(0xFFEEEBE4);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E1D8);
  static const Color lightBorderStrong = Color(0xFF958E80);
  static const Color lightTextPrimary = Color(0xFF1C1A17);
  static const Color lightTextSecondary = Color(0xFF58534A);
  static const Color lightTextHint = Color(0xFF716B60);
  static const Color lightDisabled = Color(0xFF958E80);
  static const Color lightPrimaryStrong = Color(0xFF0B5D56);
  static const Color lightDigitalTint = Color(0xFFEEEEFC);
  static const Color lightDigitalInk = Color(0xFF3730A3);
  static const Color lightCashTint = Color(0xFFFBF1DC);
  static const Color lightCashInk = Color(0xFF7A4E05);
  static const Color lightPremium = Color(0xFFA8822F);
  static const Color lightPremiumTint = Color(0xFFFBF3E1);
  static const Color lightChartTrack = Color(0x240F766E);
  static const Color lightShadow = Color(0x141C1A17);
  static const List<Color> lightHeroGradient = [
    Color(0xFF0F766E),
    Color(0xFF0B5D56),
  ];

  // Dark (never black)
  static const Color darkBackground = Color(0xFF0B1211);
  static const Color darkSurface = Color(0xFF121B1A);
  static const Color darkSurfaceSoft = Color(0xFF1B2725);
  static const Color darkSurfaceRaised = Color(0xFF182322);
  static const Color darkBorder = Color(0xFF24312F);
  static const Color darkBorderStrong = Color(0xFF5C6E6A);
  static const Color darkTextPrimary = Color(0xFFEEF1EF);
  static const Color darkTextSecondary = Color(0xFFA7B3AF);
  static const Color darkTextHint = Color(0xFF7F8D89);
  static const Color darkDisabled = Color(0xFF5C6E6A);
  static const Color darkPrimary = Color(0xFF4CC2B0);
  static const Color darkPrimaryContainer = Color(0xFF1A312E);
  static const Color darkOnPrimary = Color(0xFF04201D);
  static const Color darkPrimaryStrong = Color(0xFF6FD3C3);
  static const Color darkCash = Color(0xFFE8B04A);
  static const Color darkCashTint = Color(0xFF2B220F);
  static const Color darkCashInk = Color(0xFFF2C46B);
  static const Color darkDigital = Color(0xFF8E89F2);
  static const Color darkDigitalTint = Color(0xFF1E1D3A);
  static const Color darkDigitalInk = Color(0xFFB4B1FA);
  static const Color darkSuccess = Color(0xFF5FCB98);
  static const Color darkSuccessContainer = Color(0xFF12291F);
  static const Color darkDanger = Color(0xFFF2827A);
  static const Color darkDangerContainer = Color(0xFF2E1614);
  static const Color darkWarning = Color(0xFFF0A060);
  static const Color darkWarningContainer = Color(0xFF2E1D10);
  static const Color darkInfo = Color(0xFF8DB4DD);
  static const Color darkInfoContainer = Color(0xFF15212E);
  static const Color darkPremium = Color(0xFFE7C273);
  static const Color darkPremiumTint = Color(0xFF2E2408);
  static const Color darkChartTrack = Color(0x244CC2B0);
  static const Color darkShadow = Color(0x00000000);
  static const List<Color> darkHeroGradient = [
    Color(0xFF1F3D39),
    Color(0xFF1A312E),
  ];
}
