import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_actions.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_sheets.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The More screen: you, what you manage, your business, this device,
/// preferences, security and sign out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) =>
          p.profile != c.profile ||
          p.authStatus != c.authStatus ||
          p.defaultBusiness != c.defaultBusiness,
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

        return _MoreScreen(
          profile: profile,
          permissions: authState.permissions,
          businessName: authState.defaultBusiness?.name?.trim() ?? '',
        );
      },
    );
  }
}

class _MoreScreen extends StatefulWidget {
  final User profile;
  final AppPermissions permissions;
  final String businessName;

  const _MoreScreen({
    required this.profile,
    required this.permissions,
    required this.businessName,
  });

  @override
  State<_MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<_MoreScreen> {
  bool _pinEnrolled = false;
  BiometricKind? _kind;
  bool _bioEnabled = false;
  bool _busy = false;

  String? get _userId => widget.profile.id;

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

  Future<void> _lock() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (!await getIt<PinVaultService>().hasAnyEnrolled()) return;
    navigator.pushNamedAndRemoveUntil(
      RouteStrings.pinUnlockScreen,
      (route) => false,
      arguments: {'autoBiometric': false},
    );
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

  String _roleLabel() {
    final tr = context.tr;
    final p = widget.permissions;
    if (p.isOwner) return tr.mrRoleOwner;
    if (p.isManager) return tr.mrRoleManager;
    return tr.mrRoleCashier;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final perms = widget.permissions;
    final nav = Navigator.of(context);

    final manage = <Widget>[
      if (perms.canAccessCustomers)
        SettingsRow(
          tile: SettingsTile.teal,
          icon: PhosphorIconsRegular.users,
          title: tr.mrCustomers,
          onTap: () => selectMainFeature(context, AppFeature.customers),
        ),
      if (!perms.isCashier && perms.canAccessCategories)
        SettingsRow(
          tile: SettingsTile.indigo,
          icon: PhosphorIconsRegular.stack,
          title: tr.mrCategories,
          onTap: () => selectMainFeature(context, AppFeature.categories),
        ),
      if (perms.canAccessSalesHistory) ...[
        SettingsRow(
          tile: SettingsTile.slate,
          icon: PhosphorIconsRegular.receipt,
          title: tr.mrSalesHistory,
          onTap: () => nav.pushNamed(RouteStrings.salesHistoryScreen),
        ),
        SettingsRow(
          tile: SettingsTile.red,
          icon: PhosphorIconsRegular.arrowUUpLeft,
          title: tr.mrReturns,
          onTap: () => nav.pushNamed(RouteStrings.returnsScreen),
        ),
      ],
      if (perms.canAccessReports)
        SettingsRow(
          tile: SettingsTile.green,
          icon: PhosphorIconsRegular.chartLine,
          title: tr.mrReports,
          onTap: () => nav.pushNamed(RouteStrings.reportsScreen),
        ),
      if (perms.canAccessUsers)
        SettingsRow(
          tile: SettingsTile.amber,
          icon: PhosphorIconsRegular.users,
          title: tr.mrTeam,
          onTap: () => nav.pushNamed(RouteStrings.cashiersScreen),
        ),
    ];

    final hasBankak =
        widget.profile.bankakAccount?.accountNumber?.trim().isNotEmpty == true;

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
            SettingsNavBar(backLabel: tr.back),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  AppDims.s6 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  AppLargeTitle(title: tr.mrTitle),
                  _ProfileCard(
                    profile: widget.profile,
                    role: _roleLabel(),
                    manager: perms.isManager,
                    onTap: () => nav.pushNamed(RouteStrings.profileScreen),
                  ),
                  if (manage.isNotEmpty)
                    SettingsGroup(header: tr.mrManage, children: manage),
                  if (perms.isOwner)
                    SettingsGroup(
                      header: tr.mrBusinessGroup,
                      children: [
                        SettingsRow(
                          tile: SettingsTile.teal,
                          icon: PhosphorIconsRegular.storefront,
                          title: tr.mrBusinessRow,
                          value: widget.businessName.isEmpty
                              ? null
                              : widget.businessName,
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
                    header: tr.mrThisDevice,
                    children: [
                      BlocBuilder<PrinterBloc, PrinterState>(
                        builder: (context, state) {
                          final saved = state.hasSavedPrinter;
                          final connected = saved && state.status.isConnected;
                          return SettingsRow(
                            tile: SettingsTile.slate,
                            icon: PhosphorIconsRegular.printer,
                            title: tr.mrPrinter,
                            value: !saved
                                ? tr.mrPrinterNotSetUp
                                : connected
                                ? tr.mrPrinterConnected
                                : tr.mrPrinterNotConnected,
                            dot: saved,
                            valueColor: connected
                                ? colors.success
                                : colors.disabled,
                            onTap: () => nav.pushNamed(
                              RouteStrings.printerSettingsScreen,
                            ),
                          );
                        },
                      ),
                      BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
                        bloc: getIt<OfflineStatusBloc>(),
                        buildWhen: (p, c) =>
                            p.pendingSalesCount != c.pendingSalesCount,
                        builder: (context, state) {
                          final n = state.pendingSalesCount;
                          return SettingsRow(
                            tile: SettingsTile.blue,
                            icon: PhosphorIconsRegular.arrowsClockwise,
                            title: tr.mrSync,
                            value: n > 0
                                ? tr.mrSyncWaiting(n)
                                : tr.mrSyncUpToDate,
                            valueColor: n > 0 ? colors.warning : null,
                            onTap: () =>
                                nav.pushNamed(RouteStrings.pendingSyncScreen),
                          );
                        },
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
                          icon: PhosphorIconsRegular.globe,
                          title: tr.mrLanguage,
                          value: tr.currentLanguageName,
                          onTap: () => openLanguageSheet(context),
                        ),
                      ),
                      SettingsRow(
                        tile: SettingsTile.slate,
                        icon: PhosphorIconsRegular.moon,
                        title: tr.mrAppearance,
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
                        if (_pinEnrolled) ...[
                          SettingsRow(
                            tile: SettingsTile.slate,
                            icon: PhosphorIconsRegular.key,
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
                          SettingsRow(
                            tile: SettingsTile.teal,
                            icon: PhosphorIconsRegular.lock,
                            title: tr.mrLockNow,
                            chevron: false,
                            onTap: _lock,
                          ),
                        ],
                      ],
                    ),
                  // TODO(support-number): add the WhatsApp support row once
                  // the real support number is known.
                  const SizedBox(height: 22),
                  _SignOutCard(onTap: () => confirmLogout(context)),
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

class _ProfileCard extends StatelessWidget {
  final User profile;
  final String role;
  final bool manager;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.role,
    required this.manager,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = profile.fullName?.trim() ?? '';
    final initials = name.isEmpty ? '?' : name.initials;
    final roleBg = manager ? colors.digitalTint : colors.primaryContainer;
    final roleFg = manager ? colors.digitalInk : colors.primary;

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            profile.phone?.trim() ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: AppDims.borderPill,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 2,
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: roleFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              context.tr.mrSignOut,
              style: TextStyle(fontSize: 17, color: colors.danger),
            ),
          ),
        ),
      ),
    );
  }
}
