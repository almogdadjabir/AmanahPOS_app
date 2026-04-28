import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const AppFormField({super.key,
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.prefixIcon,
    this.nextFocus,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted ??
              (_) => nextFocus?.requestFocus(),
      style: AppTextStyles.bs500(context).copyWith(
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bs400(context).copyWith(
          color: context.appColors.textHint,
        ),
        prefixIcon: Icon(prefixIcon,
            size: 18, color: context.appColors.textHint),
        filled: true,
        fillColor: context.appColors.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: context.appColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(
              color: context.appColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: context.appColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(
              color: context.appColors.danger, width: 1.5),
        ),
        errorStyle: AppTextStyles.bs400(context).copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.danger,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3, vertical: AppDims.s3),
      ),
    );
  }
}