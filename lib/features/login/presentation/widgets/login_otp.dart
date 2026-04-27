import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/login/presentation/widgets/app_button.dart';
import 'package:amana_pos/features/login/presentation/widgets/otp_input_square.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final colors = context.appColors;
        final filled = (state.otp ?? '').length == 6;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: AppRadius.borderLg,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: colors.primary,
                        size: 26,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Verification code',
                      style: AppTextStyles.lg200(
                        context,
                        weight: AppTextStyles.extraBold,
                        color: colors.textPrimary,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppSpacing.xs),

                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.bs100(
                          context,
                          color: colors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to\n'),
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
                              onTap: () => context
                                  .read<LoginBloc>()
                                  .add(const OnResetEvent(isPhoneChange: true)),
                              child: Text(
                                'Change',
                                style: AppTextStyles.bs100(
                                  context,
                                  weight: AppTextStyles.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: AppSpacing.xxl),

                    OTPInputSquare(
                      state: state.otp ?? '',
                      is6Digit: true,
                      hasError: state.otpError != null,
                      isLoading: state.isLoading,
                      isOTPMatched: state.isPinMatched,
                      onChanged: (code) => context
                          .read<LoginBloc>()
                          .add(OnChangeOtpEvent(otpCode: code)),
                      onCompleted: () => context
                          .read<LoginBloc>()
                          .add(OnSubmitOtpEvent()),
                    ).animate(target: state.otpError != null ? 1 : 0)
                        .shake(hz: 4, duration: 500.ms),

                    SizedBox(
                      height: 36,
                      child: state.otpError != null
                          ? _StatusBanner(
                        message: state.otpError!,
                        isError: true,
                      ).animate().fadeIn(duration: 200.ms)
                          : state.isPinMatched
                          ? _StatusBanner(
                        message: 'Verified — signing you in…',
                        isError: false,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0)
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Center(
                      child: state.otpResendSeconds > 0
                          ? Text.rich(
                        TextSpan(
                          style: AppTextStyles.sm300(
                            context,
                            color: colors.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Resend code in '),
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
                            : () => context
                            .read<LoginBloc>()
                            .add(const OnResendOtpEvent()),
                        icon: Icon(
                          Icons.refresh,
                          size: 16,
                          color: colors.primary,
                        ),
                        label: Text(
                          'Resend code',
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
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
              child: AppButton.wide(
                label: state.isPinMatched ? 'Verified' : 'Verify & continue',
                onPressed: (filled && !state.isLoading && !state.isPinMatched)
                    ? () => context.read<LoginBloc>().add(OnSubmitOtpEvent())
                    : null,
                isLoading: state.isLoading,
                suffixIcon: state.isPinMatched
                    ? Icon(Icons.check_rounded, size: 20, color: Colors.white,)
                    : Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
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

  const _StatusBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isError ? colors.dangerContainer : colors.successContainer,
        borderRadius: AppRadius.borderSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? colors.danger : colors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              message,
              style: AppTextStyles.sm200(
                context,
                weight: AppTextStyles.semibold,
                color: isError ? colors.danger : colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}