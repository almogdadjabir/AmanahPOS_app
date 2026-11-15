import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

enum AppChipTone { neutral, warning, danger }

/// Filter chip: pill, 34pt. Selected state is brand tint with a brand
/// outline. Optional count badge and a trailing caret for menu chips.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;

  /// Overrides the rendered count text (for example `12+`).
  final String? countText;
  final bool showCaret;
  final AppChipTone tone;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.countText,
    this.showCaret = false,
    this.tone = AppChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (badgeBg, badgeFg) = selected
        ? (colors.primary, colors.onPrimary)
        : switch (tone) {
            AppChipTone.warning => (colors.warningContainer, colors.warning),
            AppChipTone.danger => (colors.dangerContainer, colors.danger),
            AppChipTone.neutral => (colors.surfaceSoft, colors.textSecondary),
          };

    return Pressable(
      onTap: onTap,
      haptic: true,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? Border.all(color: colors.primary, width: 1.2)
              : (isDark ? Border.all(color: colors.border) : null),
          boxShadow: selected || isDark
              ? null
              : [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: selected ? colors.primary : colors.textPrimary,
              ),
            ),
            if (count != null || countText != null) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  countText ?? '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: badgeFg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
            if (showCaret) ...[
              const SizedBox(width: 6),
              Icon(
                PhosphorIconsRegular.caretDown,
                size: 13,
                color: selected ? colors.primary : colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
