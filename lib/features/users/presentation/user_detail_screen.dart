import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/deactivate_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/edit_user_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class UserDetailScreen extends StatelessWidget {
  final UserData user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, UserData?>(
      selector: (state) {
        final matches = state.userList.where((item) => item.id == user.id);
        return matches.isEmpty ? null : matches.first;
      },
      builder: (context, data) {
        final currentUser = data ?? user;

        return Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _UserAppBar(user: currentUser),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s6,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _SectionTitle(
                        title: 'Account Info',
                        subtitle: 'Basic cashier profile and access status.',
                      ),
                      const SizedBox(height: AppDims.s2),
                      _InfoSection(user: currentUser),

                      const SizedBox(height: AppDims.s5),

                      _SectionTitle(
                        title: 'Activity',
                        subtitle: 'Login and account creation details.',
                      ),
                      const SizedBox(height: AppDims.s2),
                      _ActivitySection(user: currentUser),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserAppBar extends StatelessWidget {
  final UserData user;

  const _UserAppBar({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = user.isActive ?? false;
    final roleColor = _roleColor(context, user.role);

    final fullName = user.fullName?.trim().isNotEmpty == true
        ? user.fullName!.trim()
        : 'Cashier';

    return SliverAppBar(
      expandedHeight: 235,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            _AppBarIconButton(
              icon: SolarIconsOutline.altArrowLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _AppBarIconButton(
              icon: SolarIconsOutline.penNewSquare,
              onTap: () => showEditUserSheet(context, user: user),
            ),
            if (isActive) ...[
              const SizedBox(width: AppDims.s2),
              _AppBarIconButton(
                icon: SolarIconsOutline.forbiddenCircle,
                color: const Color(0xFFDC2626),
                backgroundColor:
                const Color(0xFFDC2626).withValues(alpha: 0.08),
                borderColor:
                const Color(0xFFDC2626).withValues(alpha: 0.18),
                onTap: () => showDeactivateUserSheet(context, user),
              ),
            ],
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: colors.background,
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            0,
            AppDims.s4,
            AppDims.s4,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.24),
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.fullName?.initials ?? '?',
                    style: AppTextStyles.lg100(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: roleColor,
                      height: 1,
                    ),
                  ),
                ),

                const SizedBox(height: AppDims.s3),

                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs700(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    height: 1.05,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: AppDims.s2),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppDims.s2,
                  runSpacing: AppDims.s1,
                  children: [
                    _RoleBadge(role: user.role),
                    _StatusBadge(active: isActive),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final UserData user;

  const _InfoSection({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final verified = user.isVerified ?? false;
    final active = user.isActive ?? false;

    return _Card(
      children: [
        _InfoRow(
          icon: SolarIconsOutline.phone,
          label: 'Phone',
          value: user.phone?.trim().isNotEmpty == true ? user.phone!.trim() : '—',
        ),
        _InfoRow(
          icon: SolarIconsOutline.userId,
          label: 'Role',
          value: _capitalize(user.role),
        ),
        _InfoRow(
          icon: verified
              ? SolarIconsOutline.verifiedCheck
              : SolarIconsOutline.closeCircle,
          label: 'Verified',
          value: verified ? 'Yes' : 'No',
          valueColor: verified ? const Color(0xFF16A34A) : null,
          iconColor: verified ? const Color(0xFF16A34A) : null,
        ),
        _InfoRow(
          icon: SolarIconsOutline.recordCircle,
          iconColor: active ? const Color(0xFF16A34A) : null,
          label: 'Status',
          value: active ? 'Active' : 'Inactive',
          valueColor: active ? const Color(0xFF16A34A) : null,
          isLast: true,
        ),
      ],
    );
  }

  String _capitalize(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return '—';
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _ActivitySection extends StatelessWidget {
  final UserData user;

  const _ActivitySection({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _InfoRow(
          icon: SolarIconsOutline.login,
          label: 'Last login',
          value: _formatDate(user.lastLoginAt) ?? 'Never',
          valueColor:
          user.lastLoginAt == null ? context.appColors.textHint : null,
        ),
        _InfoRow(
          icon: SolarIconsOutline.calendar,
          label: 'Joined',
          value: _formatDate(user.createdAt) ?? '—',
          isLast: true,
        ),
      ],
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;

    try {
      final date = DateTime.parse(iso).toLocal();

      return '${date.day} ${_month(date.month)} ${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _month(int month) {
    return const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month];
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bs600(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4,
            vertical: AppDims.s3,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (iconColor ?? colors.primary).withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: iconColor ?? colors.textHint,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bs300(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bs300(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: valueColor ?? colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: AppDims.s4 + 34 + AppDims.s3,
            color: colors.border,
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String? role;

  const _RoleBadge({
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role?.toLowerCase().trim();

    if (normalizedRole == null || normalizedRole.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _roleColor(context, normalizedRole);

    final label = switch (normalizedRole) {
      'admin' => 'Admin',
      'manager' => 'Manager',
      'cashier' => 'Cashier',
      _ => normalizedRole,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? const Color(0xFF16A34A) : colors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.20 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: AppTextStyles.bs100(context).copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: backgroundColor ?? colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: borderColor ?? colors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

Color _roleColor(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'admin' => const Color(0xFF8B5CF6),
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    _ => context.appColors.textHint,
  };
}