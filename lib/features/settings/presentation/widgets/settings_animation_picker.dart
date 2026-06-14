import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SettingsAnimationPicker extends StatelessWidget {
  final AnimationPreference selected;
  final ValueChanged<AnimationPreference> onSelected;

  const SettingsAnimationPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;

    final options = <(AnimationPreference, String)>[
      (AnimationPreference.auto, tr.animationsAuto),
      (AnimationPreference.alwaysOn, tr.animationsAlwaysOn),
      (AnimationPreference.alwaysOff, tr.animationsAlwaysOff),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppDims.s2),
            _AnimationOption(
              label: options[i].$2,
              isSelected: options[i].$1 == selected,
              onTap: () => onSelected(options[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimationOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimationOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // No AnimatedContainer here on purpose: this control toggles motion.
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 1.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs200(context).copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
