import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Unified search field widget used across the app.
///
/// Provides consistent styling and behavior for search inputs with optional:
/// - Clear button via [suffixWidget]
/// - Custom [focusNode] for focus management
/// - Customizable [hint] text
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final Widget? suffixWidget;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hint,
    this.suffixWidget,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDims.s3),
          Icon(SolarIconsOutline.magnifier, size: 18, color: colors.textHint),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.bs300(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          suffixWidget ?? const SizedBox.shrink(),
          const SizedBox(width: AppDims.s2),
        ],
      ),
    );
  }
}
