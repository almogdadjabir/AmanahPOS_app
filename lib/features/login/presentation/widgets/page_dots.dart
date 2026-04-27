import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class PageDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double dotSize;
  final double activeDotWidth;

  const PageDots({
    super.key,
    required this.currentPage,
    this.totalPages = 2,
    this.dotSize = 6,
    this.activeDotWidth = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPages, (i) {
        final active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: dotSize,
          width: active ? activeDotWidth : dotSize,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}