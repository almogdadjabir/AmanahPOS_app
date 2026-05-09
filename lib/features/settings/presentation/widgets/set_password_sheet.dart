import 'package:amana_pos/features/settings/data/models/set_password_request_dto.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/app_bottom_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/primary_sheet_button.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class SetPasswordSheet extends StatefulWidget {
  const SetPasswordSheet({super.key});

  @override
  State<SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends State<SetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SettingsBloc>().add(
      OnSetPassword(
        dto: SetPasswordRequestDto(
          password: _passwordCtrl.text,
          passwordConfirm: _confirmCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Set Password',
      subtitle: 'Use a strong password to protect your AmanaPOS account.',
      icon: Icons.lock_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            FieldLabel(label: 'New Password', required: true),
            const SizedBox(height: AppDims.s1),
            _PasswordField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              nextFocus: _confirmFocus,
              hint: 'New password',
              obscureText: _obscurePassword,
              onToggle: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              validator: (v) {
                final value = v ?? '';

                if (value.isEmpty) return 'Password is required';
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }

                return null;
              },
            ),
            const SizedBox(height: AppDims.s3),
            FieldLabel(label: 'Confirm Password', required: true),
            const SizedBox(height: AppDims.s1),
            _PasswordField(
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              hint: 'Confirm password',
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onToggle: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
              validator: (v) {
                final value = v ?? '';

                if (value.isEmpty) return 'Please confirm password';
                if (value != _passwordCtrl.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),
            const SizedBox(height: AppDims.s5),
            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) =>
              prev.passwordStatus != curr.passwordStatus,
              builder: (context, state) {
                return PrimarySheetButton(
                  label: 'Update Password',
                  isLoading:
                  state.passwordStatus == SettingsSubmitStatus.loading,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggle,
    this.focusNode,
    this.nextFocus,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted ?? (_) => nextFocus?.requestFocus(),
      style: AppTextStyles.bs500(context).copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bs400(context).copyWith(
          color: colors.textHint,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: colors.textHint,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: colors.textHint,
          ),
        ),
        filled: true,
        fillColor: colors.surfaceSoft,
        errorMaxLines: 2,
        errorStyle: AppTextStyles.sm200(context).copyWith(
          fontWeight: FontWeight.w600,
          color: colors.danger,
          height: 1.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s3,
        ),
      ),
    );
  }
}