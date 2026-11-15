import 'dart:math' as math;

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/login_country.dart';
import 'package:amana_pos/widgets/phone_number_field.dart' show phoneMaxLength;
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "912 345 678": digits only, capped at the national length, grouped in
/// threes for reading. The caret keeps its place among the digits.
class PhoneGroupFormatter extends TextInputFormatter {
  const PhoneGroupFormatter();

  static String group(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0 && i < 9) b.write(' ');
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    digits = digits.substring(
      0,
      math.min(digits.length, phoneMaxLength(digits)),
    );

    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBeforeCaret = newValue.text
        .substring(0, caret)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, digits.length);

    final text = group(digits);
    var offset = 0;
    var seen = 0;
    while (offset < text.length && seen < digitsBeforeCaret) {
      if (text[offset] != ' ') seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// One row in an inset group: tappable country chip, hairline, number field.
class LoginPhoneRow extends StatelessWidget {
  const LoginPhoneRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.country,
    required this.onCountryTap,
    required this.onSubmitted,
    this.error = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final LoginCountry country;
  final VoidCallback onCountryTap;
  final VoidCallback onSubmitted;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(
          color: error
              ? colors.danger
              : dark
              ? colors.border
              : Colors.transparent,
          width: error ? 1.5 : 1,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Pressable(
                onTap: onCountryTap,
                scale: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppDims.s4, right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(country.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        country.dialCode,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 17,
                          fontWeight: AppTextStyles.medium,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        PhosphorIconsRegular.caretDown,
                        size: 14,
                        color: colors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: colors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    cursorColor: colors.primary,
                    inputFormatters: const [PhoneGroupFormatter()],
                    onSubmitted: (_) => onSubmitted(),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 22,
                      fontWeight: AppTextStyles.medium,
                      fontFeatures: AppTextStyles.tabularFigures,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: PhoneGroupFormatter.group(country.hint),
                      hintTextDirection: TextDirection.ltr,
                      hintStyle: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: AppTextStyles.regular,
                        fontFeatures: AppTextStyles.tabularFigures,
                        color: colors.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
