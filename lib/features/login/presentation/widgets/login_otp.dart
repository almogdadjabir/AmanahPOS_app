import 'dart:math' as math;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/features/login/presentation/widgets/otp_input_square.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class LoginOtp extends StatelessWidget {
  const LoginOtp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading ||
          prev.otpError != curr.otpError ||
          prev.isPinMatched != curr.isPinMatched ||
          prev.otpResendSeconds != curr.otpResendSeconds ||
          prev.phoneNumber != curr.phoneNumber ||
          prev.otp != curr.otp,
      builder: (context, state) {
        final tr = context.tr;
        final colors = context.appColors;
        final filled = (state.otp ?? '').length == 6;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s6,
                  AppDims.s4,
                  AppDims.s6,
                  AppDims.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDims.s5),

                    Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: AppDims.borderLg,
                          ),
                          child: Icon(
                            PhosphorIconsRegular.shield,
                            color: colors.primary,
                            size: 26,
                          ),
                        )
                        .mAnimate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1),
                        ),

                    const SizedBox(height: AppDims.s5),

                    Text(
                          tr.otpTitle,
                          style: AppTextStyles.lg200(
                            context,
                            weight: AppTextStyles.extraBold,
                            color: colors.textPrimary,
                          ),
                        )
                        .mAnimate()
                        .fadeIn(delay: 150.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppDims.s2),

                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.bs400(
                          context,
                          color: colors.textSecondary,
                        ),
                        children: [
                          TextSpan(text: tr.otpSentPrefix),
                          TextSpan(
                            text: '+249 ${state.phoneNumber ?? ''}  ',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: AppTextStyles.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () => context.read<LoginBloc>().add(
                                const OnResetEvent(isPhoneChange: true),
                              ),
                              child: Text(
                                tr.otpChange,
                                style: AppTextStyles.bs400(
                                  context,
                                  weight: AppTextStyles.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).mAnimate().fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: AppDims.s8),

                    OTPInputSquare(
                      state: state.otp ?? '',
                      is6Digit: true,
                      hasError: state.otpError != null,
                      isLoading: state.isLoading,
                      isOTPMatched: state.isPinMatched,
                      onChanged: (code) => context.read<LoginBloc>().add(
                        OnChangeOtpEvent(otpCode: code),
                      ),
                      onCompleted: () =>
                          context.read<LoginBloc>().add(OnSubmitOtpEvent()),
                    ),

                    SizedBox(
                      height: 36,
                      child: state.otpError != null
                          ? _StatusBanner(
                              message: state.otpError!,
                              isError: true,
                            ).mAnimate().fadeIn(duration: 200.ms)
                          : state.isPinMatched
                          ? _StatusBanner(
                                  message: tr.otpVerifiedSigningIn,
                                  isError: false,
                                )
                                .mAnimate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.2, end: 0)
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppDims.s6),

                    Center(
                      child: state.otpResendSeconds > 0
                          ? Text.rich(
                              TextSpan(
                                style: AppTextStyles.sm300(
                                  context,
                                  color: colors.textSecondary,
                                ),
                                children: [
                                  TextSpan(text: tr.otpResendIn),
                                  TextSpan(
                                    text:
                                        '0:${state.otpResendSeconds.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontWeight: AppTextStyles.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton.icon(
                              onPressed: state.isLoading
                                  ? null
                                  : () => context.read<LoginBloc>().add(
                                      const OnResendOtpEvent(),
                                    ),
                              icon: Icon(
                                PhosphorIconsRegular.arrowsClockwise,
                                size: 16,
                                color: colors.primary,
                              ),
                              label: Text(
                                tr.otpResendButton,
                                style: AppTextStyles.sm300(
                                  context,
                                  weight: AppTextStyles.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDims.s6,
                AppDims.s3,
                AppDims.s6,
                MediaQuery.paddingOf(context).bottom + AppDims.s3,
              ),
              child: AppButton.wide(
                label: state.isPinMatched
                    ? tr.otpVerifiedButton
                    : tr.otpVerifyButton,
                onPressed: (filled && !state.isLoading && !state.isPinMatched)
                    ? () => context.read<LoginBloc>().add(OnSubmitOtpEvent())
                    : null,
                isLoading: state.isLoading,
                suffixIcon: state.isPinMatched
                    ? const Icon(
                        PhosphorIconsRegular.check,
                        size: 20,
                        color: Colors.white,
                      )
                    : const Icon(
                        PhosphorIconsRegular.arrowRight,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = isError ? colors.danger : colors.success;
    final bg = isError ? colors.dangerContainer : colors.successContainer;

    final pill = Container(
      padding: const EdgeInsets.fromLTRB(7, 6, 12, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon chip
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? PhosphorIconsRegular.exclamationMark : PhosphorIconsRegular.check,
              size: 13,
              color: accent,
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Flexible(
            child: Text(
              message,
              style: AppTextStyles.bs100(
                context,
                weight: AppTextStyles.semibold,
                color: accent,
              ),
            ),
          ),
          // Live spinner for the "verified, signing in…" success state.
          if (!isError) ...[
            const SizedBox(width: AppDims.s2),
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: accent),
            ),
          ],
        ],
      ),
    );

    // Errors get a short, decaying horizontal shake to signal "try again".
    // Keyed by message so each new error re-triggers it.
    if (isError) {
      return _ShakeOnce(key: ValueKey(message), child: pill);
    }
    return pill;
  }
}

/// Runs a single decaying horizontal shake when first built. Re-triggers when
/// given a new [Key]. Dependency-free (no flutter_animate version coupling).
class _ShakeOnce extends StatelessWidget {
  const _ShakeOnce({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (_, t, child) {
        final dx = math.sin(t * math.pi * 5) * (1 - t) * 5;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
