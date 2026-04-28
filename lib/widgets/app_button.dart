import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;

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
  }) : width = double.infinity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;

    final (height, horizontalPad, textStyle) = switch (size) {
      AppButtonSize.small  => (36.0, 12.0, theme.textTheme.labelMedium!),
      AppButtonSize.medium => (48.0, 20.0, theme.textTheme.labelLarge!),
      AppButtonSize.large  => (56.0, 24.0, theme.textTheme.titleSmall!),
    };

    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.primary => (
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      theme.colorScheme.onPrimary,
      Colors.transparent,
      ),
      AppButtonVariant.secondary => (
      isDisabled ? theme.colorScheme.secondary.withValues(alpha: 0.4) : theme.colorScheme.secondary,
      theme.colorScheme.onSecondary,
      Colors.transparent,
      ),
      AppButtonVariant.outline => (
      Colors.transparent,
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      ),
      AppButtonVariant.ghost => (
      Colors.transparent,
      isDisabled ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.primary,
      Colors.transparent,
      ),
    };

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: Center(
                child: isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefixIcon != null) ...[
                      prefixIcon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: textStyle.copyWith(color: fgColor),
                    ),
                    if (suffixIcon != null) ...[
                      const SizedBox(width: 8),
                      suffixIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}