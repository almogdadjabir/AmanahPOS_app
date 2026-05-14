import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_bankak_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/owner_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/set_password_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/setting_section_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_action_tile.dart';
import 'package:amana_pos/features/settings/presentation/widgets/theme_picker_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    context.read<AuthBloc>().add(const OnLoadProfileEvent());
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  void _openProfileSheet(BuildContext context, User profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: EditProfileSheet(
          fullName: profile.fullName ?? '',
          email: profile.email ?? '',
          bankakAccountNumber: profile.bankakAccount?.accountNumber ?? '',
        ),
      ),
    );
  }

  void _openBankakSheet(BuildContext context, User profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: EditBankakSheet(
          fullName: profile.fullName ?? '',
          email: profile.email ?? '',
          currentAccountNumber: profile.bankakAccount?.accountNumber ?? '',
        ),
      ),
    );
  }

  void _openPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: const SetPasswordSheet(),
      ),
    );
  }

  void _openThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeBloc>(),
        child: const ThemePickerSheet(),
      ),
    );
  }

  static String _modeLabel(ScreenMode? mode) {
    switch (mode) {
      case ScreenMode.light:
        return 'Light';
      case ScreenMode.dark:
        return 'Dark';
      case ScreenMode.device:
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final overlayStyle = SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: colors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (prev, curr) =>
        prev.submitStatus != curr.submitStatus ||
            prev.passwordStatus != curr.passwordStatus,
        listener: (context, state) {
          if (state.submitStatus == SettingsSubmitStatus.success) {
            Navigator.of(context).maybePop();
            GlobalSnackBar.show(
              message: 'Settings updated successfully',
              isInfo: true,
            );
          }

          if (state.submitStatus == SettingsSubmitStatus.failure) {
            GlobalSnackBar.show(
              message: state.submitError ?? 'Failed to update settings',
              isError: true,
              isAutoDismiss: false,
            );
          }

          if (state.passwordStatus == SettingsSubmitStatus.success) {
            Navigator.of(context).maybePop();
            GlobalSnackBar.show(
              message: 'Password updated successfully',
              isInfo: true,
            );
          }

          if (state.passwordStatus == SettingsSubmitStatus.failure) {
            GlobalSnackBar.show(
              message: state.passwordError ?? 'Failed to update password',
              isError: true,
              isAutoDismiss: false,
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) =>
          prev.profile != curr.profile ||
              prev.authStatus != curr.authStatus,
          builder: (context, authState) {
            if (authState.profile == null ||
                authState.authStatus == AuthStatus.loading) {
              return const _SettingsLoadingView();
            }

            final profile = authState.profile!;
            final permissions = authState.permissions;
            final isOwner = permissions.isOwner;

            return Scaffold(
              backgroundColor: colors.background,
              body: RefreshIndicator(
                color: colors.primary,
                onRefresh: () => _refresh(context),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    const _SettingsAppBar(),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        AppDims.s4,
                        AppDims.s4,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: OwnerHeader(
                          fullName: profile.fullName,
                          phone: profile.phone,
                          role: profile.role,
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        AppDims.s6,
                        AppDims.s4,
                        AppDims.s3,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: SettingSectionHeader(
                          title: 'Account',
                          subtitle: isOwner
                              ? 'Manage your profile and business payment setup.'
                              : 'Manage your name and contact details.',
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s4,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SettingsActionTile(
                              icon: SolarIconsOutline.user,
                              iconColor: colors.primary,
                              title: 'Profile',
                              subtitle: _profileSubtitle(profile),
                              trailingText: 'Edit',
                              onTap: () => _openProfileSheet(context, profile),
                            ),
                            if (isOwner) ...[
                              const SizedBox(height: AppDims.s3),
                              SettingsActionTile(
                                icon: SolarIconsOutline.card,
                                iconColor: const Color(0xFF2DD4BF),
                                title: 'Bankak Payments',
                                subtitle: _bankakSubtitle(profile),
                                trailingText:
                                _hasBankak(profile) ? 'Active' : 'Setup',
                                logoAsset: 'assets/images/bankak_logo.png',
                                onTap: () => _openBankakSheet(context, profile),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        AppDims.s6,
                        AppDims.s4,
                        AppDims.s3,
                      ),
                      sliver: const SliverToBoxAdapter(
                        child: SettingSectionHeader(
                          title: 'Security',
                          subtitle: 'Keep your AmanaPOS account protected.',
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s4,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: SettingsActionTile(
                          icon: SolarIconsOutline.lockPassword,
                          iconColor: const Color(0xFF94A3B8),
                          title: 'Password',
                          subtitle: 'Last changed information will appear here.',
                          trailingText: 'Change',
                          onTap: () => _openPasswordSheet(context),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        AppDims.s6,
                        AppDims.s4,
                        AppDims.s3,
                      ),
                      sliver: const SliverToBoxAdapter(
                        child: SettingSectionHeader(
                          title: 'Appearance',
                          subtitle:
                          'Customize how AmanaPOS looks on your device.',
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        AppDims.s8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: BlocSelector<ThemeBloc, ThemeState, ScreenMode?>(
                          selector: (s) => s.mode,
                          builder: (context, mode) {
                            return _AppearancePicker(
                              selectedMode: mode ?? ScreenMode.device,
                              onOpenFullPicker: () => _openThemeSheet(context),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _hasBankak(User profile) {
    return profile.bankakAccount?.accountNumber?.trim().isNotEmpty == true;
  }

  String _bankakSubtitle(User profile) {
    final account = profile.bankakAccount?.accountNumber?.trim();

    if (account == null || account.isEmpty) {
      return 'Not configured. Add Bankak to accept sales.';
    }

    return 'Account ${_maskAccount(account)} · ready for POS sales.';
  }

  String _profileSubtitle(User profile) {
    final email = profile.email?.trim();
    final phone = profile.phone?.trim();

    if (email != null && email.isNotEmpty) return email;
    if (phone != null && phone.isNotEmpty) return phone;

    return 'Owner name, email and account details';
  }

  String _maskAccount(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }
}

class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: 88,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            _BackButton(colors: colors),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Text(
                'Settings',
                style: AppTextStyles.bs600(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            const _SyncedPill(),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final AppThemeColors colors;

  const _BackButton({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.76),
            ),
          ),
          child: Icon(
            SolarIconsOutline.altArrowLeft,
            color: colors.textPrimary,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _SyncedPill extends StatelessWidget {
  const _SyncedPill();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s3,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.65),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'SYNCED',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearancePicker extends StatelessWidget {
  final ScreenMode selectedMode;
  final VoidCallback onOpenFullPicker;

  const _AppearancePicker({
    required this.selectedMode,
    required this.onOpenFullPicker,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemePreviewCard(
              mode: ScreenMode.light,
              label: 'Light',
              selectedMode: selectedMode,
              onTap: () {
                context.read<ThemeBloc>().add(
                  const OnThemeChangeEvent(mode: ScreenMode.light),
                );
              },
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: _ThemePreviewCard(
              mode: ScreenMode.device,
              label: 'System',
              selectedMode: selectedMode,
              onTap: () {
                context.read<ThemeBloc>().add(
                  const OnThemeChangeEvent(mode: ScreenMode.device),
                );
              },
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: _ThemePreviewCard(
              mode: ScreenMode.dark,
              label: 'Dark',
              selectedMode: selectedMode,
              onTap: () {
                context.read<ThemeBloc>().add(
                  const OnThemeChangeEvent(mode: ScreenMode.dark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final ScreenMode mode;
  final String label;
  final ScreenMode selectedMode;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.mode,
    required this.label,
    required this.selectedMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = mode == selectedMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border.withValues(alpha: 0.0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.16,
              child: Container(
                decoration: BoxDecoration(
                  color: _previewBackground(mode),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.65)
                        : colors.border,
                  ),
                ),
                child: Stack(
                  children: [
                    if (mode == ScreenMode.device)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _SystemThemePainter(),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 7,
                      right: 7,
                      bottom: 7,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              label,
              style: AppTextStyles.bs200(context).copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _previewBackground(ScreenMode mode) {
    switch (mode) {
      case ScreenMode.light:
        return const Color(0xFFF8FAFC);
      case ScreenMode.dark:
        return const Color(0xFF111827);
      case ScreenMode.device:
      default:
        return const Color(0xFFF8FAFC);
    }
  }
}

class _SystemThemePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = const Color(0xFFF8FAFC);
    final darkPaint = Paint()..color = const Color(0xFF020617);

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawRect(Offset.zero & size, lightPaint);
    canvas.drawPath(path, darkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SettingsLoadingView extends StatelessWidget {
  const _SettingsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: context.appColors.primary,
        ),
      ),
    );
  }
}