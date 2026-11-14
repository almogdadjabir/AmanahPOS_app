import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final duration = Motion.duration(AppDims.medium);

    return RepaintBoundary(
      child: Pressable(
        onTap: onTap,
        haptic: true,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: duration,
          curve: AppDims.ease,
          height: 32,
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s3 + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : colors.surfaceSoft,
            borderRadius: AppDims.borderPill,
          ),
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: AppDims.ease,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: selected ? colors.background : colors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}
