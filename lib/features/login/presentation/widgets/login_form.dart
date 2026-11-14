import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
import 'package:amana_pos/theme/phosphor_icons.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focus = FocusNode();

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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (prev, curr) =>
          prev.mobileError != curr.mobileError ||
          prev.isLoading != curr.isLoading ||
          prev.isMobileValid != curr.isMobileValid ||
          prev.country != curr.country,
      builder: (context, state) {
        final tr = context.tr;
        final colors = context.appColors;
        final hasError = state.mobileError != null;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: false,
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s6,
                  AppDims.s6,
                  AppDims.s6,
                  AppDims.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDims.s6),

                    const AmanaPosLogo()
                        .mAnimate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppDims.s8),

                    Text(
                          tr.loginWelcomeTitle,
                          style: AppTextStyles.bs400(
                            context,
                            weight: AppTextStyles.extraBold,
                            color: colors.textPrimary,
                          ),
                        )
                        .mAnimate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppDims.s2),

                    Text(
                          tr.loginSubtitle,
                          style: AppTextStyles.bs200(
                            context,
                            color: colors.textSecondary,
                          ),
                        )
                        .mAnimate()
                        .fadeIn(delay: 250.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppDims.s8),

                    Text(
                      tr.loginMobileLabel,
                      style: AppTextStyles.bs100(
                        context,
                        weight: AppTextStyles.semibold,
                        color: colors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppDims.s2),

                    PhoneNumberField(
                          controller: _phoneController,
                          focusNode: _focus,
                          error: hasError,
                          country: state.country,
                          onCountryChanged: (c) => context
                              .read<LoginBloc>()
                              .add(OnCountryChangedEvent(country: c)),
                          onCompleted: (_) => context.read<LoginBloc>().add(
                            OnLoginSubmitEvent(),
                          ),
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
                                Icon(
                                  PhosphorIconsRegular.warningCircle,
                                  size: 14,
                                  color: colors.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.mobileError!,
                                  style: AppTextStyles.sm200(
                                    context,
                                    weight: AppTextStyles.semibold,
                                    color: colors.danger,
                                  ),
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
                AppDims.s6,
                AppDims.s3,
                AppDims.s6,
                MediaQuery.paddingOf(context).bottom + AppDims.s3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton.wide(
                        label: tr.loginContinue,
                        onPressed: state.isMobileValid
                            ? () => context.read<LoginBloc>().add(
                                OnLoginSubmitEvent(),
                              )
                            : null,
                        isLoading: state.isLoading,
                      )
                      .mAnimate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: AppDims.s3),

                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.sm200(
                        context,
                        color: colors.textHint,
                      ),
                      children: [
                        TextSpan(text: tr.loginTermsPrefix),
                        TextSpan(
                          text: tr.loginTermsLink,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: tr.loginTermsSeparator),
                        TextSpan(
                          text: tr.loginPrivacyLink,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDims.s4),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
