import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger, link }

enum AppButtonSize { small, medium, large }

/// The one button. Filled brand by default, radius 12 (pill for compact
/// actions), press scale 0.97, no ripple, spinner inside while loading,
/// 40% opacity when disabled.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;
  final bool pill;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.pill = false,
  });

  const AppButton.wide({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.pill = false,
  }) : width = double.infinity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isDisabled = onPressed == null && !isLoading;
    final isInert = onPressed == null || isLoading;
    final isLink = variant == AppButtonVariant.link;

    final (height, horizontalPad, textStyle) = switch (size) {
      AppButtonSize.small => (
        AppDims.buttonHeightSmall,
        AppDims.s3,
        theme.textTheme.labelMedium!,
      ),
      AppButtonSize.medium => (
        AppDims.buttonHeight,
        AppDims.s5,
        theme.textTheme.labelLarge!,
      ),
      AppButtonSize.large => (
        AppDims.buttonHeightLarge,
        AppDims.s6,
        theme.textTheme.titleSmall!,
      ),
    };

    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.primary => (
        colors.primary,
        colors.onPrimary,
        Colors.transparent,
      ),
      AppButtonVariant.secondary => (
        colors.surfaceSoft,
        colors.textPrimary,
        Colors.transparent,
      ),
      AppButtonVariant.outline => (
        Colors.transparent,
        colors.textPrimary,
        colors.border,
      ),
      AppButtonVariant.ghost => (
        Colors.transparent,
        colors.primary,
        Colors.transparent,
      ),
      AppButtonVariant.danger => (
        colors.danger,
        theme.colorScheme.onError,
        Colors.transparent,
      ),
      AppButtonVariant.link => (
        Colors.transparent,
        colors.primary,
        Colors.transparent,
      ),
    };

    final radius = BorderRadius.circular(pill ? AppDims.rPill : AppDims.rMd);

    final content = AnimatedSwitcher(
      duration: Motion.duration(AppDims.medium),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prefixIcon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: fgColor, size: 18),
                    child: prefixIcon!,
                  ),
                  const SizedBox(width: AppDims.s2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: AppDims.s2),
                  IconTheme.merge(
                    data: IconThemeData(color: fgColor, size: 18),
                    child: suffixIcon!,
                  ),
                ],
              ],
            ),
    );

    final body = isLink
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDims.s2),
            child: Center(widthFactor: 1, child: content),
          )
        : SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: radius,
                border: borderColor == Colors.transparent
                    ? null
                    : Border.all(color: borderColor),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                child: Center(widthFactor: 1, child: content),
              ),
            ),
          );

    return Pressable(
      onTap: isInert ? null : onPressed,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.4 : 1,
        duration: Motion.duration(AppDims.medium),
        child: body,
      ),
    );
  }
}
