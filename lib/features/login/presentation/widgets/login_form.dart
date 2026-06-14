import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/phone_number_field.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _LoginMode { otp, password }

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focus = FocusNode();

  _LoginMode _mode = _LoginMode.otp;
  bool _passwordVisible = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChange);
  }

  void _onPhoneChange() {
    context.read<LoginBloc>().add(
      OnMobileChangedEvent(mobile: _phoneController.text),
    );
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChange);
    _phoneController.dispose();
    _passwordController.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (prev, curr) =>
          prev.mobileError != curr.mobileError ||
          prev.isLoading != curr.isLoading ||
          prev.isMobileValid != curr.isMobileValid,
      builder: (context, state) {
        final tr = context.tr;
        final colors = context.appColors;
        final hasError = state.mobileError != null;

        if (context.isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.loginWelcomeTitle,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr.loginSubtitle,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  color: colors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _LoginModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 22),
              Text(
                tr.loginMobileLabel,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              PhoneNumberField(
                controller: _phoneController,
                focusNode: _focus,
                error: hasError,
                onCompleted: (_) =>
                    context.read<LoginBloc>().add(OnLoginSubmitEvent()),
              ),
              SizedBox(
                height: 28,
                child: hasError
                    ? Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: colors.danger,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              state.mobileError!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sm200(
                                context,
                                weight: AppTextStyles.semibold,
                                color: colors.danger,
                              ),
                            ),
                          ),
                        ],
                      ).mAnimate().shake(hz: 4, duration: 400.ms)
                    : const SizedBox.shrink(),
              ),
              if (_mode == _LoginMode.password) ...[
                const SizedBox(height: 4),
                _LoginPasswordField(
                  controller: _passwordController,
                  visible: _passwordVisible,
                  onToggle: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LoginRememberBox(
                      checked: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Forgot password',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              AppButton.wide(
                label: _mode == _LoginMode.otp ? tr.loginContinue : 'Sign In',
                onPressed: state.isMobileValid
                    ? () =>
                        context.read<LoginBloc>().add(OnLoginSubmitEvent())
                    : null,
                isLoading: state.isLoading,
                suffixIcon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: false,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    const AmanaPosLogo()
                        .mAnimate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      tr.loginWelcomeTitle,
                      style: AppTextStyles.lg200(context,
                          weight: AppTextStyles.extraBold,
                          color: colors.textPrimary),
                    )
                        .mAnimate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      tr.loginSubtitle,
                      style: AppTextStyles.bs400(context,
                          color: colors.textSecondary),
                    )
                        .mAnimate()
                        .fadeIn(delay: 250.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      tr.loginMobileLabel,
                      style: AppTextStyles.bs600(context,
                          weight: AppTextStyles.semibold,
                          color: colors.textSecondary),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    PhoneNumberField(
                      controller: _phoneController,
                      focusNode: _focus,
                      error: hasError,
                      onCompleted: (_) => context
                          .read<LoginBloc>()
                          .add(OnLoginSubmitEvent()),
                    )
                        .mAnimate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    // Fixed-height error slot — no layout jump when it appears
                    SizedBox(
                      height: 28,
                      child: hasError
                          ? Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 14, color: colors.danger),
                                const SizedBox(width: 4),
                                Text(
                                  state.mobileError!,
                                  style: AppTextStyles.sm200(context,
                                      weight: AppTextStyles.semibold,
                                      color: colors.danger),
                                ),
                              ],
                            ).mAnimate().shake(hz: 4, duration: 400.ms)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton.wide(
                    label: tr.loginContinue,
                    onPressed: state.isMobileValid
                        ? () => context
                            .read<LoginBloc>()
                            .add(OnLoginSubmitEvent())
                        : null,
                    isLoading: state.isLoading,
                  )
                      .mAnimate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: AppSpacing.sm),

                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.bs300(context,
                          color: colors.textHint),
                      children: [
                        TextSpan(text: tr.loginTermsPrefix),
                        TextSpan(
                          text: tr.loginTermsLink,
                          style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: tr.loginTermsSeparator),
                        TextSpan(
                          text: tr.loginPrivacyLink,
                          style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Desktop mode toggle ────────────────────────────────────────────────────────

class _LoginModeToggle extends StatelessWidget {
  const _LoginModeToggle({required this.mode, required this.onChanged});

  final _LoginMode mode;
  final void Function(_LoginMode) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeInOut,
            alignment: mode == _LoginMode.otp
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.10),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.06),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _LoginToggleBtn(
                  label: 'OTP Code',
                  active: mode == _LoginMode.otp,
                  onTap: () => onChanged(_LoginMode.otp),
                ),
              ),
              Expanded(
                child: _LoginToggleBtn(
                  label: 'Password',
                  active: mode == _LoginMode.password,
                  onTap: () => onChanged(_LoginMode.password),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginToggleBtn extends StatelessWidget {
  const _LoginToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? colors.textPrimary : colors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Desktop password field ─────────────────────────────────────────────────────

class _LoginPasswordField extends StatelessWidget {
  const _LoginPasswordField({
    required this.controller,
    required this.visible,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            obscureText: !visible,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: colors.textHint,
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.only(
                left: 16,
                right: 48,
                top: 16,
                bottom: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.primary),
              ),
              filled: true,
              fillColor: colors.surface,
              suffixIcon: IconButton(
                icon: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.textHint,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Desktop remember-me checkbox ───────────────────────────────────────────────

class _LoginRememberBox extends StatelessWidget {
  const _LoginRememberBox({required this.checked, required this.onChanged});

  final bool checked;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: checked ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: checked ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: checked
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Keep me signed in',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
