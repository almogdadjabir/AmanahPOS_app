import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

/// A compact 4-digit obscured PIN input for form sheets (distinct from the
/// full-screen keypad). Digits only, max length 4.
class PinDigitsField extends StatelessWidget {
  const PinDigitsField({
    super.key,
    required this.controller,
    this.focusNode,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasError ? colors.danger : colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: AppTextStyles.bs400(
                context,
                color: colors.textPrimary,
              ).copyWith(letterSpacing: 8, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '••••',
                prefixIcon: Icon(
                  PhosphorIconsRegular.lockKey,
                  size: 18,
                  color: colors.textHint,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 22,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    errorText!,
                    style: AppTextStyles.sm200(context, color: colors.danger),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
