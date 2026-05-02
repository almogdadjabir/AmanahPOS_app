import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserList extends StatelessWidget {
  final List<UserData> users;

  const UserList({
    super.key,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        0,
        AppDims.s4,
        0,
      ),
      child: Column(
        children: List.generate(users.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == users.length - 1 ? 0 : AppDims.s3,
            ),
            child: _CashierCard(user: users[index])
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 50 + (index * 35)),
              duration: 260.ms,
            )
                .slideY(
              begin: 0.04,
              end: 0,
              curve: Curves.easeOutCubic,
            ),
          );
        }),
      ),
    );
  }
}

class _CashierCard extends StatelessWidget {
  final UserData user;

  const _CashierCard({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = user.isActive ?? false;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          RouteStrings.userDetailScreen,
          arguments: {'user': user},
        ),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _CashierAvatar(user: user),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? 'Cashier',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _RoleBadge(role: user.role),
                        if (user.phone?.trim().isNotEmpty == true) ...[
                          const SizedBox(width: AppDims.s2),
                          Expanded(
                            child: Text(
                              user.phone!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs200(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDims.s2),
                    _AccessHint(role: user.role),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s2),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(active: isActive),
                  const SizedBox(height: AppDims.s3),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashierAvatar extends StatelessWidget {
  final UserData user;

  const _CashierAvatar({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final roleColor = _roleColor(context, user.role);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: roleColor.withValues(alpha: 0.16),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user.fullName?.initials ?? '?',
        style: AppTextStyles.bs500(context).copyWith(
          fontWeight: FontWeight.w900,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _AccessHint extends StatelessWidget {
  final String? role;

  const _AccessHint({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final text = switch (role) {
      'manager' => 'Can manage inventory, reports and operations',
      'cashier' => 'Can process sales and use POS terminal',
      _ => 'Staff account',
    };

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bs100(context).copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
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
    if (role == null) return const SizedBox.shrink();

    final color = _roleColor(context, role);
    final label = switch (role) {
      'manager' => 'Manager',
      'cashier' => 'Cashier',
      _ => role!,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: color,
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: active ? const Color(0xFF16A34A) : colors.textHint,
        ),
      ),
    );
  }
}

Color _roleColor(BuildContext context, String? role) {
  return switch (role) {
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    'admin' => const Color(0xFF8B5CF6),
    _ => context.appColors.textHint,
  };
}