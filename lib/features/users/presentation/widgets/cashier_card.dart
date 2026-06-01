import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class CashierCard extends StatelessWidget {
  const CashierCard({
    super.key,
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = user.isActive ?? false;

    final fullName = _safeText(
      user.fullName,
      context.tr.cashier,
    );

    final phone = user.phone?.trim();

    return RepaintBoundary(
      child: Material(
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
          child: DecoratedBox(
            decoration: BoxDecoration(
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
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppDims.s4),
              child: Row(
                children: [
                  _CashierAvatar(user: user),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: _CashierMainInfo(
                      fullName: fullName,
                      role: user.role,
                      phone: phone,
                    ),
                  ),
                  const SizedBox(width: AppDims.s2),
                  _CashierTrailing(active: isActive),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CashierMainInfo extends StatelessWidget {
  const _CashierMainInfo({
    required this.fullName,
    required this.role,
    required this.phone,
  });

  final String fullName;
  final String? role;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
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
            _RoleBadge(role: role),
            if (phone != null && phone!.isNotEmpty) _PhoneBadge(phone: phone!),
          ],
        ),
        const SizedBox(height: AppDims.s2),
        _AccessHint(role: role),
      ],
    );
  }
}

class _CashierTrailing extends StatelessWidget {
  const _CashierTrailing({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatusBadge(active: active),
        const SizedBox(height: AppDims.s3),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: SizedBox(
            width: 30,
            height: 30,
            child: DirectionalIcon(
              icon: SolarIconsOutline.altArrowRight,
              color: colors.textHint,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
}

class _CashierAvatar extends StatelessWidget {
  const _CashierAvatar({
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(context, user.role);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: roleColor.withValues(alpha: 0.20),
        ),
      ),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Text(
            user.fullName?.initials ?? '?',
            style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w900,
              color: roleColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessHint extends StatelessWidget {
  const _AccessHint({
    required this.role,
  });

  final String? role;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = _accessHintText(context, role);

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

    return _PillBadge(
      label: _roleLabel(context, normalizedRole),
      color: color,
    );
  }
}

class _PhoneBadge extends StatelessWidget {
  const _PhoneBadge({
    required this.phone,
  });

  final String phone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s2,
            vertical: 5,
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
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
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
              ),
            ],
          ),
        ),
      ),
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

    return _PillBadge(
      label: active ? context.tr.active : context.tr.inactive,
      color: color,
      alpha: active ? 0.12 : 0.08,
      borderAlpha: active ? 0.20 : 0.12,
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.label,
    required this.color,
    this.alpha = 0.12,
    this.borderAlpha = 0.20,
  });

  final String label;
  final Color color;
  final double alpha;
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: borderAlpha),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDims.s2,
          vertical: 5,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs100(context).copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
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

String _roleLabel(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => context.tr.manager,
    'cashier' => context.tr.cashier,
    'admin' => context.tr.admin,
    _ => role ?? '—',
  };
}

String _accessHintText(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => context.tr.managerAccessHint,
    'cashier' => context.tr.cashierAccessHint,
    'admin' => context.tr.adminAccessHint,
    _ => context.tr.staffAccountHint,
  };
}

Color _roleColor(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    'admin' => const Color(0xFF8B5CF6),
    _ => context.appColors.textHint,
  };
}