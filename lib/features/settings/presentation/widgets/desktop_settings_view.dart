import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/app_progress_line.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/settings/presentation/widgets/desktop_manage_tile.dart';
import 'package:amana_pos/features/settings/presentation/widgets/desktop_settings_row.dart';
import 'package:amana_pos/features/settings/presentation/widgets/desktop_settings_sidebar.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_actions.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_group_card.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_sync_pill.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

const double _kSidebarWidth = 320;
const double _kMaxContentWidth = 1600;

/// Desktop settings layout: a fixed identity/sign-out sidebar alongside a
/// content column of grouped settings sections. Replaces the single
/// stretched mobile list with a proper two-pane "preferences" composition.
class DesktopSettingsView extends StatelessWidget {
  final User profile;
  final bool isOwner;
  final String? businessName;

  const DesktopSettingsView({
    super.key,
    required this.profile,
    required this.isOwner,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _DesktopSettingsTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDims.s6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _kSidebarWidth,
                      child: SingleChildScrollView(
                        child: DesktopSettingsSidebar(
                          profile: profile,
                          businessName: businessName,
                          onSignOut: () => confirmLogout(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDims.s6),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: AppDims.s6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _kMaxContentWidth,
                          ),
                          child: _DesktopSettingsContent(
                            profile: profile,
                            isOwner: isOwner,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _DesktopSettingsTopBar extends StatelessWidget {
  const _DesktopSettingsTopBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 74,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDims.s5,
            ),
            child: Row(
              children: [
                _BackButton(onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: AppDims.s4),
                Text(
                  context.tr.navSettings,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const SettingsSyncPill(),
              ],
            ),
          ),
        ),
        const AppProgressLine(),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            color: colors.surfaceSoft.withValues(alpha: 0.55),
            border: Border.all(color: colors.border.withValues(alpha: 0.70)),
          ),
          child: DirectionalIcon(
            icon: SolarIconsOutline.altArrowLeft,
            size: 18,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Content column ────────────────────────────────────────────────────────────

class _DesktopSettingsContent extends StatelessWidget {
  final User profile;
  final bool isOwner;

  const _DesktopSettingsContent({required this.profile, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceSectionHeader(
          title: tr.settingsSectionManage,
          color: colors.primary,
        ),
        const SizedBox(height: AppDims.s4),
        _ManageGrid(),
        const SizedBox(height: AppDims.s6),

        WorkspaceSectionHeader(
          title: tr.settingsSectionAccount,
          color: colors.primary,
        ),
        const SizedBox(height: AppDims.s4),
        SettingsGroupCard(
          items: [
            DesktopSettingsRow(
              icon: SolarIconsOutline.user,
              title: tr.settingsProfile,
              subtitle: profileSubtitle(context, profile),
              trailing: tr.commonEdit,
              onTap: () => openProfileSheet(context, profile),
            ),
            if (isOwner)
              DesktopSettingsRow(
                icon: SolarIconsOutline.card,
                iconColor: const Color(0xFF2DD4BF),
                title: tr.settingsBankakPayments,
                subtitle: bankakSubtitle(context, profile),
                trailing: hasBankakAccount(profile)
                    ? tr.commonActive
                    : tr.commonSetup,
                onTap: () => openBankakSheet(context, profile),
              ),
            DesktopSettingsRow(
              icon: SolarIconsOutline.lockPassword,
              iconColor: const Color(0xFF94A3B8),
              title: tr.settingsPassword,
              subtitle: tr.settingsPasswordSubtitle,
              trailing: tr.commonChange,
              onTap: () => openPasswordSheet(context),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s6),
        WorkspaceSectionHeader(
          title: tr.settingsSectionSupport,
          color: colors.primary,
        ),
        const SizedBox(height: AppDims.s4),
        SettingsGroupCard(
          items: [
            DesktopSettingsRow(
              icon: SolarIconsOutline.chatRound,
              iconColor: const Color(0xFF25D366),
              title: tr.settingsWhatsappSupport,
              subtitle: '+249 91 230 0000',
              onTap: () {
                // TODO: Open WhatsApp support.
              },
            ),
          ],
        ),
        const SizedBox(height: AppDims.s6),
      ],
    );
  }
}

// ── Manage grid ────────────────────────────────────────────────────────────────

class _ManageGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final tiles = [
      DesktopManageTile(
        icon: SolarIconsOutline.layersMinimalistic,
        accentColor: AppColors.primary,
        title: tr.settingsCategories,
        subtitle: tr.settingsCategoriesSubtitle,
        onTap: () => selectMainFeature(context, AppFeature.categories),
      ),
      DesktopManageTile(
        icon: SolarIconsOutline.userPlus,
        accentColor: AppColors.secondary,
        title: tr.settingsCashiers,
        subtitle: tr.settingsCashiersSubtitle,
        onTap: () => selectMainFeature(context, AppFeature.users),
      ),
      DesktopManageTile(
        icon: SolarIconsOutline.usersGroupTwoRounded,
        accentColor: AppColors.info,
        title: tr.settingsCustomers,
        subtitle: tr.settingsCustomersSubtitle,
        onTap: () => selectMainFeature(context, AppFeature.customers),
      ),
      DesktopManageTile(
        icon: SolarIconsOutline.roundArrowLeftUp,
        accentColor: AppColors.danger,
        title: tr.settingsReturns,
        subtitle: tr.settingsReturnsSubtitle,
        onTap: () =>
            Navigator.of(context).pushNamed(RouteStrings.returnsScreen),
      ),
      DesktopManageTile(
        icon: SolarIconsOutline.notebook,
        accentColor: AppColors.success,
        title: tr.settingsSalesHistory,
        subtitle: tr.settingsSalesHistorySubtitle,
        onTap: () =>
            Navigator.of(context).pushNamed(RouteStrings.salesHistoryScreen),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDims.s3,
      crossAxisSpacing: AppDims.s3,
      childAspectRatio: 2.6,
      children: tiles,
    );
  }
}
