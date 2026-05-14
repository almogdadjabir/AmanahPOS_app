import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_icons/solar_icons.dart';

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
          final user = users[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == users.length - 1 ? 0 : AppDims.s3,
            ),
            child: _CashierCard(user: user)
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 24 + (index % 6) * 18),
              duration: 220.ms,
            )
                .slideY(
              begin: 0.025,
              end: 0,
              duration: 220.ms,
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

    final fullName = user.fullName?.trim().isNotEmpty == true
        ? user.fullName!.trim()
        : 'Cashier';

    final phone = user.phone?.trim();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            RouteStrings.userDetailScreen,
            arguments: {'user': user},
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
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
          child: Row(
            children: [
              _CashierAvatar(user: user),

              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: AppDims.s2,
                      runSpacing: AppDims.s1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _RoleBadge(role: user.role),
                        if (phone != null && phone.isNotEmpty)
                          _PhoneBadge(phone: phone),
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
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      SolarIconsOutline.altArrowRight,
                      color: colors.textHint,
                      size: 17,
                    ),
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
    final roleColor = _roleColor(context, user.role);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: roleColor.withValues(alpha: 0.20),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user.fullName?.initials ?? '?',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: roleColor,
          height: 1,
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

    final normalizedRole = role?.toLowerCase().trim();

    final text = switch (normalizedRole) {
      'manager' => 'Can manage inventory, reports and operations',
      'cashier' => 'Can process sales and use POS terminal',
      'admin' => 'Can manage business settings and staff access',
      _ => 'Staff account',
    };

    return Row(
      children: [
        Icon(
          SolarIconsOutline.shieldCheck,
          size: 14,
          color: colors.textHint,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
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
      'manager' => 'Manager',
      'cashier' => 'Cashier',
      'admin' => 'Admin',
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

class _PhoneBadge extends StatelessWidget {
  final String phone;

  const _PhoneBadge({
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 150,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            SolarIconsOutline.phone,
            size: 12,
            color: colors.textHint,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs100(context).copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                height: 1,
              ),
            ),
          ),
        ],
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
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

Color _roleColor(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    'admin' => const Color(0xFF8B5CF6),
    _ => context.appColors.textHint,
  };
}