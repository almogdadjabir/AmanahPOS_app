import 'package:flutter/material.dart';

abstract final class SalesReportColors {
  // Trend line: gross (primary blue) / net (secondary teal)
  static const trendGross = Color(0xFF3B82F6); // blue-500
  static const trendNet = Color(0xFF14B8A6); // teal-500

  // Payment method donut segments (up to 6 distinct methods)
  static const List<Color> donutPalette = [
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFF3B82F6), // blue
    Color(0xFF14B8A6), // teal
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
  ];

  // Bar charts
  static const barPrimary = Color(0xFF6366F1); // indigo
  static const barMuted = Color(0xFFE0E7FF); // indigo-100 (zero-value bars)

  // Ranked list progress bar
  static const rankBar = Color(0xFF6366F1);
}
