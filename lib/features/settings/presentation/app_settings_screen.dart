import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_sheets.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Settings: the things you set once and forget. Business and Bankak (owner),
/// language, appearance and security. Work shortcuts and device status live
/// on the More screen.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _pinEnrolled = false;
  BiometricKind? _kind;
  bool _bioEnabled = false;
  bool _busy = false;

  String? get _userId => context.read<AuthBloc>().state.profile?.id;

  @override
  void initState() {
    super.initState();
    _loadSecurity();
  }

  Future<void> _loadSecurity() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    final vault = getIt<PinVaultService>();
    final service = getIt<BiometricUnlockService>();
    final enrolled = await vault.isUserEnrolled(id);
    final offered = enrolled ? await service.offeredUser() : null;
    final kind = offered != null && offered.userId == id
        ? await service.availableKind()
        : null;
    final enabled = kind != null && await service.isEnabledFor(id);
    if (!mounted) return;
    setState(() {
      _pinEnrolled = enrolled;
      _kind = kind;
      _bioEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool on) async {
    final id = _userId;
    if (id == null || _busy) return;
    final service = getIt<BiometricUnlockService>();
    final reason = context.tr.pinBiometricReason;
    _busy = true;
    if (on) {
      final ok = await service.enable(id, reason);
      if (!mounted) return;
      setState(() => _bioEnabled = ok);
    } else {
      await service.disable();
      if (!mounted) return;
      setState(() => _bioEnabled = false);
    }
    _busy = false;
  }

  Future<void> _turnOffPin() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    final tr = context.tr;
    final confirmed = await showAppConfirmSheet(
      context,
      title: tr.mrPinOffTitle,
      message: tr.mrPinOffBody,
      confirmLabel: tr.mrPinOffAction,
    );
    if (!confirmed) return;
    await getIt<PinVaultService>().removeUser(id);
    await getIt<BiometricUnlockService>().disable();
    GlobalSnackBar.show(message: tr.mrPinOffDone, isInfo: true);
    if (!mounted) return;
    setState(() {
      _pinEnrolled = false;
      _kind = null;
      _bioEnabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final nav = Navigator.of(context);
    final auth = context.watch<AuthBloc>().state;
    final isOwner = auth.permissions.isOwner;
    final businessName = auth.defaultBusiness?.name?.trim() ?? '';
    final hasBankak =
        auth.profile?.bankakAccount?.accountNumber?.trim().isNotEmpty == true;

    final biometricLabel = _kind == BiometricKind.face
        ? tr.mrFaceId
        : tr.mrFingerprint;
    final showSecurity = _pinEnrolled || _kind != null;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SettingsNavBar(backLabel: tr.mrTitle),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  AppDims.s6 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  AppLargeTitle(title: tr.mrSettings),
                  if (isOwner)
                    SettingsGroup(
                      header: tr.mrBusinessGroup,
                      children: [
                        SettingsRow(
                          tile: SettingsTile.teal,
                          icon: PhosphorIconsRegular.storefront,
                          title: tr.mrBusinessRow,
                          value: businessName.isEmpty ? null : businessName,
                          onTap: () =>
                              nav.pushNamed(RouteStrings.businessDetailScreen),
                        ),
                        SettingsRow(
                          tile: SettingsTile.indigo,
                          icon: PhosphorIconsRegular.bank,
                          title: tr.mrBankak,
                          value: hasBankak ? tr.active : tr.mrBankakSetUp,
                          valueColor: hasBankak ? colors.success : null,
                          onTap: () => nav.pushNamed(RouteStrings.bankakScreen),
                        ),
                      ],
                    ),
                  SettingsGroup(
                    header: tr.mrPreferences,
                    children: [
                      BlocSelector<LocaleBloc, LocaleState, Locale>(
                        selector: (s) => s.locale,
                        builder: (context, locale) => SettingsRow(
                          tile: SettingsTile.blue,
                          icon: PhosphorIconsRegular.translate,
                          title: tr.mrLanguage,
                          value: tr.currentLanguageName,
                          onTap: () => openLanguageSheet(context),
                        ),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    header: tr.mrAppearance,
                    children: [
                      SettingsRow(
                        tile: SettingsTile.slate,
                        icon: PhosphorIconsRegular.circleHalf,
                        title: tr.mrTheme,
                        chevron: false,
                        trailing: SizedBox(
                          width: 168,
                          child:
                              BlocSelector<ThemeBloc, ThemeState, ScreenMode?>(
                                selector: (s) => s.mode,
                                builder: (context, mode) =>
                                    AppSegmented<ScreenMode>(
                                      selected: mode ?? ScreenMode.device,
                                      segments: [
                                        AppSegment(
                                          value: ScreenMode.device,
                                          label: tr.mrThemeSystem,
                                        ),
                                        AppSegment(
                                          value: ScreenMode.light,
                                          label: tr.mrThemeLight,
                                        ),
                                        AppSegment(
                                          value: ScreenMode.dark,
                                          label: tr.mrThemeDark,
                                        ),
                                      ],
                                      onChanged: (m) => context
                                          .read<ThemeBloc>()
                                          .add(OnThemeChangeEvent(mode: m)),
                                    ),
                              ),
                        ),
                      ),
                      BlocSelector<ThemeBloc, ThemeState, AnimationPreference>(
                        selector: (s) => s.animationPreference,
                        builder: (context, pref) => SettingsRow(
                          tile: SettingsTile.amber,
                          icon: PhosphorIconsRegular.lightning,
                          title: tr.mrAnimations,
                          value: animationLabel(context, pref),
                          onTap: () => openAnimationSheet(context),
                        ),
                      ),
                    ],
                  ),
                  if (showSecurity)
                    SettingsGroup(
                      header: tr.mrSecurity,
                      footer: _kind != null
                          ? tr.mrBiometricFoot(biometricLabel)
                          : null,
                      children: [
                        if (_kind != null)
                          SettingsRow(
                            tile: SettingsTile.green,
                            icon: _kind == BiometricKind.face
                                ? PhosphorIconsRegular.scanSmiley
                                : PhosphorIconsRegular.fingerprintSimple,
                            title: biometricLabel,
                            trailing: SettingsSwitch(
                              value: _bioEnabled,
                              onChanged: _toggleBiometric,
                            ),
                          ),
                        if (_pinEnrolled)
                          SettingsRow(
                            tile: SettingsTile.slate,
                            icon: PhosphorIconsRegular.password,
                            title: tr.mrChangePin,
                            onTap: () {
                              final id = _userId;
                              if (id == null || id.isEmpty) return;
                              nav.pushNamed(
                                RouteStrings.pinChangeScreen,
                                arguments: {'userId': id},
                              );
                            },
                          ),
                      ],
                    ),
                  if (_pinEnrolled)
                    Pressable(
                      onTap: _turnOffPin,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            tr.mrPinOff,
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
