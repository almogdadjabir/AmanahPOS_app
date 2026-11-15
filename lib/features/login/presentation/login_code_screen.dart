import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_phone_row.dart';
import 'package:amana_pos/features/login/presentation/widgets/otp_input_square.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Enter the 6-digit code. Submits itself on the sixth digit (the bloc does
/// the verifying), so there is no Verify button. Pushed as a normal route so
/// iOS gets the native push and edge-swipe back.
class LoginCodeScreen extends StatelessWidget {
  const LoginCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Back (button or swipe) returns the bloc to the number step.
        if (didPop) {
          final bloc = context.read<LoginBloc>();
          if (bloc.state.loginStatus == LoginStatus.otp) {
            bloc.add(const OnResetEvent(isPhoneChange: true));
          }
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<LoginBloc, LoginState>(
            buildWhen: (p, c) =>
                p.isLoading != c.isLoading ||
                p.otpError != c.otpError ||
                p.isPinMatched != c.isPinMatched ||
                p.otpResendSeconds != c.otpResendSeconds ||
                p.phoneNumber != c.phoneNumber ||
                p.country != c.country ||
                p.otp != c.otp,
            builder: (context, state) {
              final digits = (state.phoneNumber ?? '').replaceAll(
                RegExp(r'\D'),
                '',
              );
              final phone =
                  '${state.country.dialCode} ${PhoneGroupFormatter.group(digits)}';
              final hasError = state.otpError != null;

              final Widget status;
              if (hasError) {
                status = Text(
                  state.otpError!,
                  key: const ValueKey('err'),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium!.copyWith(
                    fontSize: 15,
                    color: colors.danger,
                  ),
                );
              } else if (state.isPinMatched) {
                status = Row(
                  key: const ValueKey('ok'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.check,
                      size: 18,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr.codeVerified,
                      style: text.bodyMedium!.copyWith(
                        fontSize: 15,
                        color: colors.success,
                      ),
                    ),
                  ],
                );
              } else if (state.isLoading) {
                status = Row(
                  key: const ValueKey('busy'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr.codeVerifying,
                      style: text.bodyMedium!.copyWith(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                );
              } else {
                status = const SizedBox.shrink(key: ValueKey('none'));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Pressable(
                        onTap: () => Navigator.of(context).maybePop(),
                        scale: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DirectionalIcon(
                                icon: PhosphorIconsRegular.caretLeft,
                                size: 22,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                tr.back,
                                style: text.bodyLarge!.copyWith(
                                  fontSize: 17,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s6,
                        10,
                        AppDims.s6,
                        AppDims.s4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.codeTitle,
                            style: text.displayMedium!.copyWith(
                              letterSpacing: arabic ? 0 : -0.75,
                            ),
                          ),
                          const SizedBox(height: AppDims.s2),
                          Text.rich(
                            TextSpan(
                              style: text.bodyLarge!.copyWith(
                                fontSize: 17,
                                height: 24 / 17,
                                color: colors.textSecondary,
                              ),
                              children: [
                                // The number is isolated so it keeps its
                                // left-to-right order inside Arabic text.
                                TextSpan(
                                  text:
                                      '${tr.codeSentTo('\u2066$phone\u2069')} ',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: Pressable(
                                    scale: 1,
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                    child: Text(
                                      tr.codeWrongNumber,
                                      style: text.bodyLarge!.copyWith(
                                        fontSize: 17,
                                        height: 24 / 17,
                                        color: colors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          OTPInputSquare(
                            state: state.otp ?? '',
                            is6Digit: true,
                            hasError: hasError,
                            isLoading: state.isLoading,
                            isOTPMatched: state.isPinMatched,
                            onChanged: (code) => context.read<LoginBloc>().add(
                              OnChangeOtpEvent(otpCode: code),
                            ),
                            onCompleted: () => context.read<LoginBloc>().add(
                              OnSubmitOtpEvent(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 34,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: status,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: state.otpResendSeconds > 0
                                ? Text(
                                    tr.codeResendIn(
                                      '0:${state.otpResendSeconds.toString().padLeft(2, '0')}',
                                    ),
                                    style: text.bodyMedium!.copyWith(
                                      fontSize: 15,
                                      color: colors.textSecondary,
                                    ),
                                  )
                                : Pressable(
                                    onTap: state.isLoading
                                        ? null
                                        : () => context.read<LoginBloc>().add(
                                            const OnResendOtpEvent(),
                                          ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        tr.otpResendButton,
                                        style: text.bodyMedium!.copyWith(
                                          fontSize: 15,
                                          color: colors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
