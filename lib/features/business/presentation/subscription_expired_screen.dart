import 'package:amana_pos/common/auth_bloc/auth_bloc.dart' hide BusinessStatus;
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Blocks the app when the plan has ended. Cannot be dismissed.
class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const SubscriptionExpiredScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  static void close(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  static void reset() => _isShowing = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    return PopScope(
      // The back button must not dismiss the blocker.
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colors.warningContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.clock,
                            size: 34,
                            color: colors.warning,
                          ),
                        ),
                        const SizedBox(height: AppDims.s4),
                        Text(
                          tr.obExpiredTitle,
                          textAlign: TextAlign.center,
                          style: text.headlineMedium!.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            tr.obExpiredBody,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge!.copyWith(
                              fontSize: 16,
                              height: 1.45,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(
                    top: BorderSide(color: colors.border, width: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDims.s4,
                    10,
                    AppDims.s4,
                    10 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton.wide(
                        label: tr.obExpiredAction,
                        prefixIcon: Icon(
                          PhosphorIconsRegular.whatsappLogo,
                          size: 22,
                          color: colors.onPrimary,
                        ),
                        // TODO(support-number): open the WhatsApp support chat
                        // once the real number is known.
                        onPressed: () {},
                      ),
                      const SizedBox(height: 4),
                      AppButton.wide(
                        label: tr.obExpiredSignOut,
                        variant: AppButtonVariant.link,
                        onPressed: () =>
                            context.read<AuthBloc>().add(OnLogoutEvent()),
                      ),
                    ],
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
