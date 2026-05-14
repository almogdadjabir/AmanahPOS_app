import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CategoryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = widget.selected
        ? colors.primary.withValues(alpha: isDark ? 0.16 : 0.10)
        : colors.surfaceSoft.withValues(alpha: isDark ? 0.82 : 0.96);

    final borderColor = widget.selected
        ? colors.primary.withValues(alpha: 0.82)
        : colors.border.withValues(alpha: isDark ? 0.78 : 0.95);

    final textColor = widget.selected ? colors.primary : colors.textPrimary;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed ? 0.96 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            constraints: const BoxConstraints(
              maxWidth: 170,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: borderColor,
                width: widget.selected ? 1.35 : 1.05,
              ),
              boxShadow: widget.selected
                  ? [
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: isDark ? 0.13 : 0.07,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: AppTextStyles.bs300(context).copyWith(
                  color: textColor,
                  fontWeight: widget.selected ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: -0.15,
                  height: 1,
                ),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
        ),
      ),
    );
  }
}