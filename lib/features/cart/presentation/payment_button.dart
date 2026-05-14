import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class PaymentButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PaymentButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<PaymentButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
          decoration: BoxDecoration(
            color: widget.selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surfaceSoft.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.selected
                  ? colors.primary.withValues(alpha: 0.95)
                  : colors.border.withValues(alpha: 0.78),
              width: widget.selected ? 1.45 : 1.05,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: widget.selected
                            ? colors.primary
                            : colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s3),

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? colors.primary.withValues(alpha: 0.16)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.selected ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}