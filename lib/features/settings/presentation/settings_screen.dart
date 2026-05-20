import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_bankak_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/owner_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/set_password_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/theme_picker_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── Sheet helpers ─────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) =>
      prev.submitStatus != curr.submitStatus ||
          prev.passwordStatus != curr.passwordStatus,
      listener: (context, state) {
        if (state.submitStatus == SettingsSubmitStatus.success) {
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(message: 'Updated successfully', isInfo: true);
        }
        if (state.submitStatus == SettingsSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Failed to update',
            isError: true,
            isAutoDismiss: false,
          );
        }
        if (state.passwordStatus == SettingsSubmitStatus.success) {
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(message: 'Password updated', isInfo: true);
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
            return Scaffold(
              backgroundColor: colors.background,
              body: Center(child: CircularProgressIndicator(color: colors.primary)),
            );
          }

          final profile = authState.profile!;
          final business = authState.defaultBusiness;
          final isOwner = authState.permissions.isOwner;
          final fullName = profile.fullName ?? profile.phone ?? 'User';

          return BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, navState) {
              return Scaffold(
                backgroundColor: colors.background,
                appBar: AppBar(
                  backgroundColor: colors.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(SolarIconsOutline.altArrowLeft,
                        color: colors.textPrimary, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppDims.s3),
                      child: _SyncedPill(),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(AppDims.s4),
                  children: [

                    // ── Profile ─────────────────────────────────────
                    OwnerHeader(
                      fullName: profile.fullName,
                      phone: profile.phone,
                      role: profile.role,
                    ),
                    const SizedBox(height: AppDims.s8),

                    // ── Manage ──────────────────────────────────────
                    const _SectionLabel('MANAGE'),
                    const SizedBox(height: AppDims.s2),
                    _GroupCard(items: [
                      _RowItem(
                        icon: SolarIconsOutline.layersMinimalistic,
                        title: 'Categories',
                        subtitle: 'Organize products',
                        onTap: () {
                          context.read<NavigationBloc>().add(
                              NavigationFeatureSelected(AppFeature.categories));
                          Navigator.of(context).pop();
                        },
                      ),
                      _RowItem(
                        icon: SolarIconsOutline.userPlus,
                        title: 'Cashiers',
                        subtitle: 'Staff access & shifts',
                        onTap: () {
                          context.read<NavigationBloc>().add(
                              NavigationFeatureSelected(AppFeature.users));
                          Navigator.of(context).pop();
                        },
                      ),
                      _RowItem(
                        icon: SolarIconsOutline.usersGroupTwoRounded,
                        title: 'Customers',
                        subtitle: 'Profiles & loyalty',
                        onTap: () {
                          context.read<NavigationBloc>().add(
                              NavigationFeatureSelected(AppFeature.customers));
                          Navigator.of(context).pop();
                        },
                      ),
                      _RowItem(
                        icon: SolarIconsOutline.roundArrowLeftUp,
                        title: 'Returns',
                        subtitle: 'Process customer item returns',
                        onTap: () => Navigator.of(context).pushNamed(RouteStrings.returnsScreen),
                      ),
                      _RowItem(
                        icon: SolarIconsOutline.notebook,
                        title: 'Sales history',
                        subtitle: 'Browse and search all transactions',
                        onTap: () => Navigator.of(context).pushNamed(RouteStrings.salesHistoryScreen),
                      ),

                    ]),

                    const SizedBox(height: AppDims.s5),

                    // ── Account & Security ──────────────────────────
                    const _SectionLabel('ACCOUNT & SECURITY'),
                    const SizedBox(height: AppDims.s2),
                    _GroupCard(items: [
                      _RowItem(
                        icon: SolarIconsOutline.user,
                        title: 'Profile',
                        subtitle: _profileSubtitle(profile),
                        trailing: 'Edit',
                        onTap: () => _openProfileSheet(context, profile),
                      ),
                      if (isOwner)
                        _RowItem(
                          icon: SolarIconsOutline.card,
                          iconColor: const Color(0xFF2DD4BF),
                          title: 'Bankak Payments',
                          subtitle: _bankakSubtitle(profile),
                          trailing: _hasBankak(profile) ? 'Active' : 'Setup',
                          onTap: () => _openBankakSheet(context, profile),
                        ),
                      _RowItem(
                        icon: SolarIconsOutline.lockPassword,
                        iconColor: const Color(0xFF94A3B8),
                        title: 'Password',
                        subtitle: 'Change your account password',
                        trailing: 'Change',
                        onTap: () => _openPasswordSheet(context),
                      ),
                    ]),

                    const SizedBox(height: AppDims.s5),

                    // ── Appearance ──────────────────────────────────
                    const _SectionLabel('APPEARANCE'),
                    const SizedBox(height: AppDims.s2),
                    BlocSelector<ThemeBloc, ThemeState, ScreenMode?>(
                      selector: (s) => s.mode,
                      builder: (context, mode) => _ThemePicker(
                        selectedMode: mode ?? ScreenMode.device,
                        onModeSelected: (m) => context
                            .read<ThemeBloc>()
                            .add(OnThemeChangeEvent(mode: m)),
                      ),
                    ),

                    const SizedBox(height: AppDims.s5),

                    // ── Support ─────────────────────────────────────
                    const _SectionLabel('SUPPORT'),
                    const SizedBox(height: AppDims.s2),
                    _GroupCard(items: [
                      _RowItem(
                        icon: SolarIconsOutline.chatRound,
                        iconColor: const Color(0xFF25D366),
                        title: 'WhatsApp Support',
                        subtitle: '+249 91 230 0000',
                        onTap: () {},
                      ),
                      _RowItem(
                        icon: SolarIconsOutline.global,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: AppDims.s6),

                    // ── Sign out ────────────────────────────────────
                    TextButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: Icon(Icons.logout_rounded,
                          size: 18, color: colors.danger),
                      label: Text(
                        'Sign out',
                        style: AppTextStyles.bs200(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.danger,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDims.s6),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static bool _hasBankak(User profile) =>
      profile.bankakAccount?.accountNumber?.trim().isNotEmpty == true;

  static String _bankakSubtitle(User profile) {
    final account = profile.bankakAccount?.accountNumber?.trim();
    if (account == null || account.isEmpty) {
      return 'Not configured — add Bankak to accept sales';
    }
    final masked = account.length > 4
        ? '•••• ${account.substring(account.length - 4)}'
        : account;
    return 'Account $masked · ready for POS sales';
  }

  static String _profileSubtitle(User profile) {
    final email = profile.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return profile.phone?.trim() ?? 'Name, email and contact details';
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _LogoutDialog(),
    );
    if (confirmed == true) {
      getIt<AuthBloc>().add(const OnLogoutEvent());
    }
  }
}

// ─── _GroupCard ───────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final List<_RowItem> items;
  const _GroupCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = items.where((e) => true).toList(); // supports future filtering

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            visible[i],
            if (i < visible.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: AppDims.s4 + 44 + AppDims.s3,
                color: colors.border.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── _RowItem ─────────────────────────────────────────────────────────────────

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? trailing; // optional right-side label (e.g. "Edit", "Active")

  const _RowItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = iconColor ?? colors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4, vertical: AppDims.s3),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: color, bgColor: color.withValues(alpha: 0.12)),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bs600(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bs400(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDims.s2),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Icon(SolarIconsOutline.altArrowRight,
                  size: 15, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── _ThemePicker ─────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  final ScreenMode selectedMode;
  final ValueChanged<ScreenMode> onModeSelected;

  const _ThemePicker({
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      child: Row(
        children: [
          _ThemeOption(
            mode: ScreenMode.light,
            label: 'Light',
            selectedMode: selectedMode,
            onTap: () => onModeSelected(ScreenMode.light),
          ),
          const SizedBox(width: AppDims.s2),
          _ThemeOption(
            mode: ScreenMode.device,
            label: 'System',
            selectedMode: selectedMode,
            onTap: () => onModeSelected(ScreenMode.device),
          ),
          const SizedBox(width: AppDims.s2),
          _ThemeOption(
            mode: ScreenMode.dark,
            label: 'Dark',
            selectedMode: selectedMode,
            onTap: () => onModeSelected(ScreenMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ScreenMode mode;
  final String label;
  final ScreenMode selectedMode;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.selectedMode,
    required this.onTap,
  });

  static Color _bg(ScreenMode m) => switch (m) {
    ScreenMode.light => const Color(0xFFF8FAFC),
    ScreenMode.dark => const Color(0xFF111827),
    _ => const Color(0xFFF8FAFC),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = mode == selectedMode;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 1.8,
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.16,
                child: Container(
                  decoration: BoxDecoration(
                    color: _bg(mode),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.5)
                          : colors.border,
                    ),
                  ),
                  child: mode == ScreenMode.device
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CustomPaint(painter: _HalfHalfPainter()),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                label,
                style: AppTextStyles.bs200(context).copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HalfHalfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF111827),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Atoms ────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _IconBadge({required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDims.rMd),
    ),
    child: Icon(icon, size: 20, color: color),
  );
}

class _Avatar extends StatelessWidget {
  final String initials;
  final AppThemeColors colors;
  const _Avatar({required this.initials, required this.colors});

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(AppDims.rMd),
    ),
    child: Center(
      child: Text(
        initials,
        style: AppTextStyles.bs700(context).copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    ),
  );
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});
  static const _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: _teal.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _teal.withValues(alpha: 0.30)),
    ),
    child: Text(
      label,
      style: AppTextStyles.bs100(context).copyWith(
        color: _teal,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _OutlinedChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlinedChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: colors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.bs400(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTextStyles.bs100(context).copyWith(
      color: context.appColors.textHint,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

class _SyncedPill extends StatelessWidget {
  const _SyncedPill();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s3, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.65),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'SYNCED',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logout dialog ────────────────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.rXl)),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rLg),
              ),
              child: const Icon(Icons.logout_rounded, size: 26, color: _red),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              'Sign out?',
              style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900, color: colors.textPrimary),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              'Make sure all your sales are synced before signing out. '
                  'Offline sales that have not synced will be lost.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppDims.s5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Sign out',
                      style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}