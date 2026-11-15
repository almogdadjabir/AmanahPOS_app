import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/login/presentation/widgets/country_sheet.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_phone_row.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:amana_pos/widgets/login_country.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sign in: large title, one inset row for the number, Continue docked above
/// the keyboard.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _phone = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onChanged);
  }

  void _onChanged() =>
      context.read<LoginBloc>().add(OnMobileChangedEvent(mobile: _phone.text));

  void _submit() {
    final bloc = context.read<LoginBloc>();
    if (bloc.state.isMobileValid && !bloc.state.isLoading) {
      bloc.add(OnLoginSubmitEvent());
    }
  }

  Future<void> _pickCountry(LoginCountry current) async {
    final bloc = context.read<LoginBloc>();
    _focus.unfocus();
    final picked = await showCountrySheet(context, selected: current);
    if (picked != null) bloc.add(OnCountryChangedEvent(country: picked));
    if (mounted) _focus.requestFocus();
  }

  @override
  void dispose() {
    _phone.removeListener(_onChanged);
    _phone.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (p, c) => p.mobileError == null && c.mobileError != null,
      listener: (_, _) => HapticFeedback.heavyImpact(),
      child: BlocBuilder<LoginBloc, LoginState>(
        buildWhen: (prev, curr) =>
            prev.mobileError != curr.mobileError ||
            prev.isLoading != curr.isLoading ||
            prev.isMobileValid != curr.isMobileValid ||
            prev.country != curr.country,
        builder: (context, state) {
          final hasError = state.mobileError != null;
          final linkStyle = TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w500,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppDims.s6,
                    MediaQuery.paddingOf(context).top + 34,
                    AppDims.s6,
                    AppDims.s4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Hero(
                        tag: amanaMarkHeroTag,
                        child: AmanaPosLogoMark(size: 44),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        tr.signInTitle,
                        style: text.displayMedium!.copyWith(
                          letterSpacing: arabic ? 0 : -0.75,
                        ),
                      ),
                      const SizedBox(height: AppDims.s2),
                      Text(
                        tr.signInSubtitle,
                        style: text.bodyLarge!.copyWith(
                          fontSize: 17,
                          height: 24 / 17,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 26),
                      LoginPhoneRow(
                        controller: _phone,
                        focusNode: _focus,
                        country: state.country,
                        error: hasError,
                        onCountryTap: () => _pickCountry(state.country),
                        onSubmitted: _submit,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: AnimatedSwitcher(
                          duration: Motion.duration(AppDims.medium),
                          child: hasError
                              ? Row(
                                  key: const ValueKey('error'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Icon(
                                        PhosphorIconsRegular.warningCircle,
                                        size: 16,
                                        color: colors.danger,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tr.signInInvalidNumber,
                                        style: text.bodySmall!.copyWith(
                                          fontSize: 13,
                                          height: 18 / 13,
                                          color: colors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text.rich(
                                  key: const ValueKey('terms'),
                                  TextSpan(
                                    style: text.bodySmall!.copyWith(
                                      fontSize: 13,
                                      height: 18 / 13,
                                      color: colors.textHint,
                                    ),
                                    children: [
                                      TextSpan(text: tr.loginTermsPrefix),
                                      TextSpan(
                                        text: tr.loginTermsLink,
                                        style: linkStyle,
                                      ),
                                      TextSpan(text: tr.loginTermsSeparator),
                                      TextSpan(
                                        text: tr.loginPrivacyLink,
                                        style: linkStyle,
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          tr.signInNeedAccess,
                          style: text.bodyMedium!.copyWith(
                            fontSize: 15,
                            height: 20 / 15,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Dock(
                child: AppButton.wide(
                  label: tr.loginContinue,
                  isLoading: state.isLoading,
                  onPressed: state.isMobileValid ? _submit : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Primary action bar that rides on the keyboard: translucent, hairline on top.
class _Dock extends StatelessWidget {
  const _Dock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDims.s4,
          10,
          AppDims.s4,
          keyboardUp ? 12 : MediaQuery.paddingOf(context).bottom + 12,
        ),
        child: child,
      ),
    );
  }
}
