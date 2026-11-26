import 'dart:async';

import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_actions.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
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
        );
      },
    );
  }
}

class _MoreScreen extends StatefulWidget {
  final User profile;
  final AppPermissions permissions;

  const _MoreScreen({required this.profile, required this.permissions});

  @override
  State<_MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<_MoreScreen> {
  bool _pinEnrolled = false;
  bool _shiftsOn = false;
  bool _accountOn = false;
  StreamSubscription<BusinessFeatures>? _featuresSub;

  String? get _userId => widget.profile.id;

  @override
  void initState() {
    super.initState();
    _loadPin();
    final features = getIt<BusinessFeaturesService>();
    _featuresSub = features.changes.listen((f) {
      if (mounted) {
        setState(() {
          _shiftsOn = f.shiftsEnabled;
          _accountOn = f.onAccount;
        });
      }
    });
    features.load().then((f) {
      if (mounted) {
        setState(() {
          _shiftsOn = f.shiftsEnabled;
          _accountOn = f.onAccount;
        });
      }
    });
  }

  @override
  void dispose() {
    _featuresSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPin() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    final enrolled = await getIt<PinVaultService>().isUserEnrolled(id);
    if (!mounted) return;
    setState(() => _pinEnrolled = enrolled);
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

    // Ordered by how often the work is done. Sales and returns is one door:
    // a return starts from a sale.
    final manage = <Widget>[
      if (perms.canAccessSalesHistory)
        SettingsRow(
          tile: SettingsTile.slate,
          icon: PhosphorIconsRegular.receipt,
          title: tr.mrSalesReturns,
          onTap: () => nav.pushNamed(RouteStrings.salesHistoryScreen),
        ),
      if (perms.canAccessCustomers)
        SettingsRow(
          tile: SettingsTile.teal,
          icon: PhosphorIconsRegular.addressBook,
          title: tr.mrCustomers,
          onTap: () => nav.pushNamed(RouteStrings.customersScreen),
        ),
      if (_accountOn)
        SettingsRow(
          tile: SettingsTile.amber,
          icon: PhosphorIconsRegular.notebook,
          title: tr.dtDebtsTitle,
          onTap: () => nav.pushNamed(RouteStrings.debtsScreen),
        ),
      if (_shiftsOn && perms.canAccessSalesHistory)
        SettingsRow(
          tile: SettingsTile.blue,
          icon: PhosphorIconsRegular.clock,
          title: tr.sfTitle,
          onTap: () => nav.pushNamed(RouteStrings.shiftsScreen),
        ),
      if (perms.canAccessReports)
        SettingsRow(
          tile: SettingsTile.green,
          icon: PhosphorIconsRegular.chartBar,
          title: tr.mrReports,
          onTap: () => nav.pushNamed(RouteStrings.reportsScreen),
        ),
      if (!perms.isCashier && perms.canAccessCategories)
        SettingsRow(
          tile: SettingsTile.indigo,
          icon: PhosphorIconsRegular.squaresFour,
          title: tr.mrCategories,
          onTap: () => nav.pushNamed(RouteStrings.categoriesScreen),
        ),
      if (perms.canAccessUsers)
        SettingsRow(
          tile: SettingsTile.amber,
          icon: PhosphorIconsRegular.usersThree,
          title: tr.mrTeam,
          onTap: () => nav.pushNamed(RouteStrings.cashiersScreen),
        ),
    ];

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
                            // The icon tells the state before the text does.
                            icon: n > 0
                                ? PhosphorIconsRegular.cloudArrowUp
                                : PhosphorIconsRegular.cloudCheck,
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
                      if (_pinEnrolled)
                        SettingsRow(
                          tile: SettingsTile.teal,
                          icon: PhosphorIconsRegular.lockSimple,
                          title: tr.mrLockNow,
                          chevron: false,
                          onTap: _lock,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        tile: SettingsTile.slate,
                        icon: PhosphorIconsRegular.gearSix,
                        title: tr.mrSettings,
                        onTap: () =>
                            nav.pushNamed(RouteStrings.appSettingsScreen),
                      ),
                    ],
                  ),
                  // TODO(support-number): add the WhatsApp support row once
                  // the real support number is known.
                  const SizedBox(height: 22),
                  _SignOutCard(onTap: () => confirmLogout(context)),
                  const SizedBox(height: AppDims.s4),
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
