import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class UnitPicker extends StatelessWidget {
  final List<String> units;
  final String selected;
  final ValueChanged<String> onSelected;

  const UnitPicker({super.key,
    required this.units,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Wrap(
      spacing: AppDims.s2,
      runSpacing: AppDims.s2,
      children: units.map((unit) {
        final isSelected = unit == selected;
        return GestureDetector(
          onTap: () => onSelected(unit),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3, vertical: AppDims.s2),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.10)
                  : colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              unit,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight:  FontWeight.w800,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}