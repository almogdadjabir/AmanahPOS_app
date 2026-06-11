import 'package:flutter/material.dart';

abstract final class SalesReportColors {
  // Trend lines — brand-aligned
  static const trendGross = Color(0xFF0F766E); // emerald-600 (brand primary)
  static const trendNet   = Color(0xFF0891B2); // cyan-600

  // Trend under-curve gradient fills
  static const trendGrossGradientTop    = Color(0x500F766E);
  static const trendGrossGradientBottom = Color(0x000F766E);
  static const trendNetGradientTop      = Color(0x300891B2);
  static const trendNetGradientBottom   = Color(0x000891B2);

  // Payment method donut/pie palette
  static const List<Color> donutPalette = [
    Color(0xFF0F766E), // emerald (brand)
    Color(0xFFF59E0B), // amber (brand secondary)
    Color(0xFF6366F1), // indigo
    Color(0xFF0891B2), // cyan
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
  ];

  // Bar charts: gradient top-to-bottom for active bars
  static const barGradientTop    = Color(0xFF0F766E); // emerald-600
  static const barGradientBottom = Color(0xFF5EEAD4); // teal-300
  static const barMuted          = Color(0xFFE2E8F0); // slate-200 (zero-value bars)
  static const barBest           = Color(0xFFF59E0B); // amber (peak / best day)
  static const barBestBottom     = Color(0xFFFCD34D); // amber-300

  // Ranked list progress bars — medals
  static const rankGold   = Color(0xFFF59E0B); // gold
  static const rankSilver = Color(0xFF94A3B8); // slate-400 (silver)
  static const rankBronze = Color(0xFFB45309); // amber-700 (bronze)
  static const rankRest   = Color(0xFF0F766E); // emerald for 4th+

  // Tooltip background
  static const tooltipBg = Color(0xFF0F172A); // slate-950
}
