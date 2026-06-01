import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/deactivate_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/edit_user_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';
import 'dart:ui' as ui;

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({
    super.key,
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, UserData?>(
      selector: (state) {
        final userId = user.id?.trim();
        if (userId == null || userId.isEmpty) return null;

        for (final item in state.userList) {
          if (item.id == userId) return item;
        }

        return null;
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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s6,
                ),
                sliver: SliverList.list(
                  children: [
                    _SectionTitle(
                      title: context.tr.userInfoTitle,
                      subtitle: context.tr.userInfoSubtitle,
                    ),
                    const SizedBox(height: AppDims.s2),
                    _InfoSection(user: currentUser),
                    const SizedBox(height: AppDims.s5),
                    _SectionTitle(
                      title: context.tr.userActivityTitle,
                      subtitle: context.tr.userActivitySubtitle,
                    ),
                    const SizedBox(height: AppDims.s2),
                    _ActivitySection(user: currentUser),
                  ],
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
  const _UserAppBar({
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = user.isActive ?? false;
    final roleColor = _roleColor(context, user.role);

    final fullName = _safeText(
      user.fullName,
      context.tr.cashier,
    );

    return SliverAppBar(
      expandedHeight: 235,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDims.s4,
        ),
        child: Row(
          children: [
            _AppBarIconButton(
              icon: SolarIconsOutline.altArrowLeft,
              semanticLabel: context.tr.back,
              flipInRtl: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _AppBarIconButton(
              icon: SolarIconsOutline.penNewSquare,
              semanticLabel: context.tr.edit,
              onTap: () => showEditUserSheet(context, user: user),
            ),
            if (isActive) ...[
              const SizedBox(width: AppDims.s2),
              _AppBarIconButton(
                icon: SolarIconsOutline.forbiddenCircle,
                semanticLabel: context.tr.deactivateUser,
                color: const Color(0xFFDC2626),
                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.08),
                borderColor: const Color(0xFFDC2626).withValues(alpha: 0.18),
                onTap: () => showDeactivateUserSheet(context, user),
              ),
            ],
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: ColoredBox(
          color: colors.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDims.s4,
                0,
                AppDims.s4,
                AppDims.s4,
              ),
              child: Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Avatar(
                        initials: user.fullName?.initials ?? '?',
                        color: roleColor,
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
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.color,
  });

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.24),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Center(
          child: Text(
            initials,
            style: AppTextStyles.lg100(context).copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final verified = user.isVerified ?? false;
    final active = user.isActive ?? false;

    return _Card(
      children: [
        _InfoRow(
          icon: SolarIconsOutline.phone,
          label: context.tr.userDetailPhone,
          value: _safeText(user.phone, '—'),
          forceValueLtr: true,
        ),
        _InfoRow(
          icon: SolarIconsOutline.userId,
          label: context.tr.userDetailRole,
          value: _localizedRole(context, user.role),
        ),
        _InfoRow(
          icon: verified
              ? SolarIconsOutline.verifiedCheck
              : SolarIconsOutline.closeCircle,
          label: context.tr.userDetailVerified,
          value: verified ? context.tr.yes : context.tr.no,
          valueColor: verified ? const Color(0xFF16A34A) : null,
          iconColor: verified ? const Color(0xFF16A34A) : null,
        ),
        _InfoRow(
          icon: SolarIconsOutline.recordCircle,
          iconColor: active ? const Color(0xFF16A34A) : null,
          label: context.tr.userDetailStatus,
          value: active ? context.tr.active : context.tr.inactive,
          valueColor: active ? const Color(0xFF16A34A) : null,
          isLast: true,
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final lastLogin = _formatDate(context, user.lastLoginAt);
    final joined = _formatDate(context, user.createdAt);

    return _Card(
      children: [
        _InfoRow(
          icon: SolarIconsOutline.login,
          label: context.tr.userDetailLastLogin,
          value: lastLogin ?? context.tr.never,
          valueColor: lastLogin == null ? context.appColors.textHint : null,
        ),
        _InfoRow(
          icon: SolarIconsOutline.calendar,
          label: context.tr.userDetailJoined,
          value: joined ?? '—',
          isLast: true,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

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
  const _Card({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(color: colors.border),
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.forceValueLtr = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool forceValueLtr;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: AppTextStyles.bs300(context).copyWith(
        fontWeight: FontWeight.w900,
        color: valueColor ?? colors.textPrimary,
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s4,
            vertical: AppDims.s3,
          ),
          child: Row(
            children: [
              _InfoIcon(
                icon: icon,
                iconColor: iconColor,
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
                child: forceValueLtr
                    ? Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: valueWidget,
                )
                    : valueWidget,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: AppDims.s4 + 34 + AppDims.s3,
            endIndent: AppDims.s4,
            color: colors.border,
          ),
      ],
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({
    required this.icon,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = iconColor ?? colors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppDims.rSm),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 17,
          color: iconColor ?? colors.textHint,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    this.role,
  });

  final String? role;

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role?.toLowerCase().trim();

    if (normalizedRole == null || normalizedRole.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _roleColor(context, normalizedRole);

    return _Badge(
      label: _localizedRole(context, normalizedRole),
      color: color,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? const Color(0xFF16A34A) : colors.textHint;

    return _Badge(
      label: active ? context.tr.active : context.tr.inactive,
      color: color,
      showDot: true,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.showDot = false,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDims.s2,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 6, height: 6),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.bs100(context).copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.flipInRtl = false,
  });

  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool flipInRtl;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
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
            child: DirectionalIcon(
              icon: icon,
              size: 20,
              color: color ?? colors.textPrimary,
              flipInRtl: flipInRtl,
            ),
          ),
        ),
      ),
    );
  }
}

String _safeText(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String _localizedRole(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'admin' => context.tr.admin,
    'manager' => context.tr.manager,
    'cashier' => context.tr.cashier,
    _ => '—',
  };
}

String? _formatDate(BuildContext context, String? iso) {
  final value = iso?.trim();
  if (value == null || value.isEmpty) return null;

  try {
    final date = DateTime.parse(value).toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();

    return DateFormat.yMMMd(locale).add_Hm().format(date);
  } catch (_) {
    return value;
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