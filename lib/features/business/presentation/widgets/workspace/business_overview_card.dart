// lib/features/business/presentation/widgets/workspace/business_overview_card.dart

import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class BusinessOverviewCard extends StatelessWidget {
  final BusinessData data;

  const BusinessOverviewCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sub = data.activeSubscription;
    final isActive = data.isActive ?? false;

    final isFree = sub?.isFree ?? true;
    final daysLeft = sub?.daysRemaining ?? 0;
    final isExpired = sub != null && !isFree && daysLeft <= 0;
    final isExpiringSoon = sub != null && !isFree && daysLeft > 0 && daysLeft <= 7;

    final Color accentColor;
    if (sub == null) {
      accentColor = const Color(0xFFF59E0B); // no subscription → amber warning
    } else if (isExpired) {
      accentColor = const Color(0xFFEF4444);
    } else if (isExpiringSoon) {
      accentColor = const Color(0xFFF59E0B);
    } else {
      accentColor = const Color(0xFF0D9488);
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Zone 1: Business identity ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDims.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(data.name),
                    style: AppTextStyles.bs400(context).copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(width: AppDims.s3),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name ?? '—',
                        style: AppTextStyles.bs500(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeChip(
                            label: _businessTypeLabel(data.businessType),
                            colors: colors,
                          ),
                          const SizedBox(width: 6),
                          _StatusDot(isActive: isActive, colors: colors),
                        ],
                      ),
                    ],
                  ),
                ),

                if ((data.shopCount ?? 0) > 0)
                  _CountPill(
                    icon: Icons.store_rounded,
                    count: data.shopCount ?? 0,
                    colors: colors,
                  ),
              ],
            ),
          ),

          // ── Zone 2+3: Subscription or warning ───────────────────────────
          if (sub != null) ...[
            // Subscription band
            Divider(height: 1, color: colors.border),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Icon(
                    isFree
                        ? Icons.card_giftcard_rounded
                        : Icons.workspace_premium_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      sub.name ?? 'Free Plan',
                      style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _expiryLabel(isFree, isExpired, daysLeft),
                    style: AppTextStyles.bs100(context).copyWith(
                      color: (isExpired || isExpiringSoon)
                          ? accentColor
                          : colors.textSecondary,
                      fontWeight: (isExpired || isExpiringSoon)
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (!isFree && sub.price != null) ...[
                    const SizedBox(width: AppDims.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${sub.price} ${sub.currency ?? ''}'.trim(),
                        style: AppTextStyles.bs100(context).copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Capacity row
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  _CapacityItem(
                    icon: Icons.store_rounded,
                    label: 'Shops',
                    value: sub.maxShops,
                    colors: colors,
                  ),
                  Container(width: 1, height: 28, color: colors.border),
                  _CapacityItem(
                    icon: Icons.local_offer_rounded,
                    label: 'Products',
                    value: sub.maxProducts,
                    colors: colors,
                  ),
                  Container(width: 1, height: 28, color: colors.border),
                  _CapacityItem(
                    icon: Icons.people_rounded,
                    label: 'Users',
                    value: sub.maxUsers,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ] else ...[
            // No subscription warning band
            Divider(height: 1, color: colors.border),
            Container(
              padding: const EdgeInsets.all(AppDims.s4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDims.rLg - 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No active subscription',
                          style: AppTextStyles.bs200(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contact us to activate your plan and unlock all features.',
                          style: AppTextStyles.bs100(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _businessTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'restaurant': return 'Restaurant';
      case 'shop': return 'Shop';
      default: return type ?? 'Business';
    }
  }

  String _expiryLabel(bool isFree, bool isExpired, int daysLeft) {
    if (isFree) return 'No expiry';
    if (isExpired) return 'Expired';
    if (daysLeft == 1) return '1 day left';
    return '$daysLeft days left';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  const _TypeChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isActive;
  final AppThemeColors colors;
  const _StatusDot({required this.isActive, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF22C55E)
                : colors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: AppTextStyles.bs100(context).copyWith(
            color: isActive ? const Color(0xFF22C55E) : colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final int count;
  final AppThemeColors colors;
  const _CountPill({required this.icon, required this.count, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final AppThemeColors colors;
  const _CapacityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                value != null ? '$value' : '∞',
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}