import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/devices/presentation/printer_l10n.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/owner_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_actions.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_group_card.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_row_item.dart';
import 'package:amana_pos/common/widgets/section_label.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_sync_pill.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_animation_picker.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_theme_picker.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus ||
          previous.passwordStatus != current.passwordStatus,
      listener: _onSettingsStateChanged,
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) =>
            previous.profile != current.profile ||
            previous.authStatus != current.authStatus ||
            previous.defaultBusiness != current.defaultBusiness,
        builder: (context, authState) {
          final profile = authState.profile;

          if (profile == null || authState.authStatus == AuthStatus.loading) {
            return Scaffold(
              backgroundColor: colors.background,
              body: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            );
          }

          final isOwner = authState.permissions.isOwner;

          return _MobileSettingsScreen(profile: profile, isOwner: isOwner);
        },
      ),
    );
  }

  void _onSettingsStateChanged(BuildContext context, SettingsState state) {
    final tr = context.tr;

    if (state.submitStatus == SettingsSubmitStatus.success) {
      Navigator.of(context).maybePop();
      GlobalSnackBar.show(message: tr.profileUpdatedSuccess, isInfo: true);
    }

    if (state.submitStatus == SettingsSubmitStatus.failure) {
      GlobalSnackBar.show(
        message: state.submitError ?? tr.profileUpdateFailed,
        isError: true,
        isAutoDismiss: false,
      );
    }

    if (state.passwordStatus == SettingsSubmitStatus.success) {
      Navigator.of(context).maybePop();
      GlobalSnackBar.show(message: tr.passwordUpdatedSuccess, isInfo: true);
    }

    if (state.passwordStatus == SettingsSubmitStatus.failure) {
      GlobalSnackBar.show(
        message: state.passwordError ?? tr.passwordUpdateFailed,
        isError: true,
        isAutoDismiss: false,
      );
    }
  }
}

/// Mobile/tablet settings: a single scrolling list of grouped cards.
class _MobileSettingsScreen extends StatelessWidget {
  final User profile;
  final bool isOwner;

  const _MobileSettingsScreen({required this.profile, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: DirectionalIcon(
            icon: PhosphorIconsRegular.caretLeft,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: AppDims.s3),
            child: SettingsSyncPill(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppDims.s4),
            children: [
              OwnerHeader(
                fullName: profile.fullName,
                phone: profile.phone,
                role: profile.role,
              ),
              const SizedBox(height: AppDims.s8),

              _ManageSection(),
              const SizedBox(height: AppDims.s5),

              _DevicesSection(),
              const SizedBox(height: AppDims.s5),

              _AccountSection(profile: profile, isOwner: isOwner),
              const SizedBox(height: AppDims.s5),

              _AppearanceSection(),
              const SizedBox(height: AppDims.s5),

              _SupportSection(),
              const SizedBox(height: AppDims.s6),

              _LockButton(),
              const SizedBox(height: AppDims.s2),

              _SignOutButton(),
              const SizedBox(height: AppDims.s6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageSection extends StatelessWidget {
  const _ManageSection();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: tr.settingsSectionManage),
        const SizedBox(height: AppDims.s2),
        SettingsGroupCard(
          items: [
            SettingsRowItem(
              icon: PhosphorIconsRegular.stack,
              title: tr.settingsCategories,
              subtitle: tr.settingsCategoriesSubtitle,
              onTap: () => selectMainFeature(context, AppFeature.categories),
            ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.userPlus,
              title: tr.settingsCashiers,
              subtitle: tr.settingsCashiersSubtitle,
              onTap: () => selectMainFeature(context, AppFeature.users),
            ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.users,
              title: tr.settingsCustomers,
              subtitle: tr.settingsCustomersSubtitle,
              onTap: () => selectMainFeature(context, AppFeature.customers),
            ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.arrowUUpLeft,
              title: tr.settingsReturns,
              subtitle: tr.settingsReturnsSubtitle,
              onTap: () {
                Navigator.of(context).pushNamed(RouteStrings.returnsScreen);
              },
            ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.notebook,
              title: tr.settingsSalesHistory,
              subtitle: tr.settingsSalesHistorySubtitle,
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(RouteStrings.salesHistoryScreen);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _DevicesSection extends StatelessWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: tr.settingsSectionDevices),
        const SizedBox(height: AppDims.s2),
        SettingsGroupCard(
          items: [
            BlocBuilder<PrinterBloc, PrinterState>(
              builder: (context, state) {
                final printer = state.savedPrinter;
                return SettingsRowItem(
                  icon: PhosphorIconsRegular.printer,
                  title: printer?.name ?? tr.settingsAddPrinter,
                  subtitle: printer != null
                      ? state.status.label(context)
                      : tr.settingsPrinterSubtitle,
                  trailing: printer != null && state.status.isConnected
                      ? tr.commonActive
                      : null,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(RouteStrings.printerSettingsScreen),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  final User profile;
  final bool isOwner;

  const _AccountSection({required this.profile, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: tr.settingsSectionAccount),
        const SizedBox(height: AppDims.s2),
        SettingsGroupCard(
          items: [
            SettingsRowItem(
              icon: PhosphorIconsRegular.user,
              title: tr.settingsProfile,
              subtitle: profileSubtitle(context, profile),
              trailing: tr.commonEdit,
              onTap: () => openProfileSheet(context, profile),
            ),
            if (isOwner)
              SettingsRowItem(
                icon: PhosphorIconsRegular.creditCard,
                iconColor: const Color(0xFF2DD4BF),
                title: tr.settingsBankakPayments,
                subtitle: bankakSubtitle(context, profile),
                trailing: hasBankakAccount(profile)
                    ? tr.commonActive
                    : tr.commonSetup,
                onTap: () => openBankakSheet(context, profile),
              ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.lockKey,
              iconColor: const Color(0xFF94A3B8),
              title: tr.settingsPassword,
              subtitle: tr.settingsPasswordSubtitle,
              trailing: tr.commonChange,
              onTap: () => openPasswordSheet(context),
            ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.lockKey,
              title: 'Change PIN',
              subtitle: 'Update your unlock PIN',
              onTap: () {
                final userId = profile.id;
                if (userId == null || userId.isEmpty) return;
                Navigator.of(context).pushNamed(
                  RouteStrings.pinChangeScreen,
                  arguments: {'userId': userId},
                );
              },
            ),
            SettingsRowItem(
              icon: PhosphorIconsRegular.prohibit,
              iconColor: const Color(0xFFEF4444),
              title: 'Disable PIN',
              subtitle: 'Remove PIN unlock on this device',
              onTap: () => _confirmDisablePin(context, profile.id),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _confirmDisablePin(BuildContext context, String? userId) async {
  if (userId == null || userId.isEmpty) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Disable PIN?'),
      content: const Text(
        'You\'ll sign in with your phone number next time instead of a PIN.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Disable'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await getIt<PinVaultService>().removeUser(userId);
  GlobalSnackBar.show(message: 'PIN disabled.', isInfo: true);
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: tr.settingsSectionAppearance),
        const SizedBox(height: AppDims.s2),
        BlocSelector<ThemeBloc, ThemeState, ScreenMode?>(
          selector: (state) => state.mode,
          builder: (context, mode) {
            return SettingsThemePicker(
              selectedMode: mode ?? ScreenMode.device,
              onModeSelected: (selectedMode) {
                context.read<ThemeBloc>().add(
                  OnThemeChangeEvent(mode: selectedMode),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppDims.s4),
        Text(
          tr.settingsAnimations,
          style: AppTextStyles.bs200(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppDims.s2),
        BlocSelector<ThemeBloc, ThemeState, AnimationPreference>(
          selector: (state) => state.animationPreference,
          builder: (context, pref) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsAnimationPicker(
                  selected: pref,
                  onSelected: (p) {
                    if (p == pref) return;
                    context.read<ThemeBloc>().add(
                      OnAnimationsPreferenceChanged(p),
                    );
                  },
                ),
                if (pref == AnimationPreference.auto) ...[
                  const SizedBox(height: AppDims.s1),
                  Text(
                    tr.settingsAnimationsAutoSubtitle,
                    style: AppTextStyles.bs100(
                      context,
                    ).copyWith(color: context.appColors.textSecondary),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: tr.settingsSectionSupport),
        const SizedBox(height: AppDims.s2),
        SettingsGroupCard(
          items: [
            SettingsRowItem(
              icon: PhosphorIconsRegular.chatCircle,
              iconColor: const Color(0xFF25D366),
              title: tr.settingsWhatsappSupport,
              subtitle: '+249 91 230 0000',
              onTap: () {
                // TODO: Open WhatsApp support.
              },
            ),
            BlocSelector<LocaleBloc, LocaleState, Locale>(
              selector: (state) => state.locale,
              builder: (context, locale) {
                return SettingsRowItem(
                  icon: PhosphorIconsRegular.globe,
                  title: tr.settingsLanguage,
                  subtitle: tr.currentLanguageName,
                  onTap: () => openLanguageSheet(context),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Back to the PIN screen without signing out: the session stays on the
/// device and the PIN (or Face ID) brings it back.
class _LockButton extends StatelessWidget {
  const _LockButton();

  Future<void> _lock(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (!await getIt<PinVaultService>().hasAnyEnrolled()) return;
    navigator.pushNamedAndRemoveUntil(
      RouteStrings.pinUnlockScreen,
      (route) => false,
      arguments: {'autoBiometric': false},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextButton.icon(
      onPressed: () => _lock(context),
      icon: Icon(PhosphorIconsRegular.lock, size: 18, color: colors.primary),
      label: Text(
        context.tr.menuLock,
        style: AppTextStyles.bs200(
          context,
        ).copyWith(fontWeight: FontWeight.w800, color: colors.primary),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;

    return TextButton.icon(
      onPressed: () => confirmLogout(context),
      icon: Icon(PhosphorIconsRegular.signOut, size: 18, color: colors.danger),
      label: Text(
        tr.settingsSignOut,
        style: AppTextStyles.bs200(
          context,
        ).copyWith(fontWeight: FontWeight.w800, color: colors.danger),
      ),
    );
  }
}
