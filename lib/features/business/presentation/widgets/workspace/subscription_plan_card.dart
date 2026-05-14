import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_icons/solar_icons.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final BusinessData data;

  const SubscriptionPlanCard({super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sub = data.activeSubscription;

    final isFree = sub?.isFree ?? true;
    final daysLeft = sub?.daysRemaining ?? 0;
    final isExpired = sub != null && !isFree && daysLeft <= 0;
    final isExpiringSoon = sub != null && !isFree && daysLeft > 0 && daysLeft <= 7;

    final accentColor = _resolveAccentColor(
      subExists: sub != null,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
    );

    final title = sub?.name ?? 'No active subscription';
    final expiryLabel = _expiryLabel(
      isFree: isFree,
      isExpired: isExpired,
      daysLeft: daysLeft,
      hasSubscription: sub != null,
    );

    final priceText = _priceText(
      isFree: isFree,
      price: sub?.price,
      currency: sub?.currency,
      hasSubscription: sub != null,
    );

    final progress = _progressValue(
      isFree: isFree,
      isExpired: isExpired,
      daysLeft: daysLeft,
      hasSubscription: sub != null,
    );

    return Container(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.30),
                  ),
                ),
                child: Icon(
                  isFree ? SolarIconsOutline.gift : SolarIconsOutline.medalRibbon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s3,
                  vertical: AppDims.s1,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Text(
                  expiryLabel,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.border.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),

          const SizedBox(height: AppDims.s3),

          Row(
            children: [
              Text(
                sub == null ? 'Activate plan' : 'Upgrade',
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                SolarIconsOutline.arrowRight,
                size: 16,
                color: colors.textSecondary,
              ),
              const Spacer(),
              planLimitText(
                context: context,
                label: 'Shops',
                value: sub?.maxShops,
              ),
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: AppDims.s2),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),

              planLimitText(
                context: context,
                label: 'Products',
                value: sub?.maxProducts,
              ),

              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: AppDims.s2),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),

              planLimitText(
                context: context,
                label: 'Users',
                value: sub?.maxUsers,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: 120.ms)
        .slideY(
      begin: 0.08,
      end: 0,
      curve: Curves.easeOutCubic,
    );
  }

  Color _resolveAccentColor({
    required bool subExists,
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    if (!subExists) return const Color(0xFFF59E0B);
    if (isExpired) return const Color(0xFFEF4444);
    if (isExpiringSoon) return const Color(0xFFF59E0B);
    return const Color(0xFF0D9488);
  }

  double _progressValue({
    required bool isFree,
    required bool isExpired,
    required int daysLeft,
    required bool hasSubscription,
  }) {
    if (!hasSubscription) return 0;
    if (isFree) return 1;
    if (isExpired) return 0;

    const assumedBillingCycleDays = 30;
    return (daysLeft / assumedBillingCycleDays).clamp(0.0, 1.0);
  }

  String _expiryLabel({
    required bool isFree,
    required bool isExpired,
    required int daysLeft,
    required bool hasSubscription,
  }) {
    if (!hasSubscription) return 'Inactive';
    if (isFree) return 'No expiry';
    if (isExpired) return 'Expired';
    if (daysLeft == 1) return '1 day';
    return '$daysLeft days';
  }

  String _priceText({
    required bool isFree,
    required dynamic price,
    required String? currency,
    required bool hasSubscription,
  }) {
    if (!hasSubscription) return 'Contact support to activate your plan';
    if (isFree) return 'Free';

    final cleanCurrency = currency?.trim() ?? '';
    final cleanPrice = price?.toString().trim() ?? '';

    if (cleanPrice.isEmpty) return 'Paid plan';
    return '$cleanPrice $cleanCurrency'.trim();
  }

  Widget planLimitText({
    required BuildContext context,
    required String label,
    required int? value,
}){
    final colors = context.appColors;

    return Text(
      '$label ${_limitText(value)}',
      style: AppTextStyles.bs100(context).copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _limitText(int? value) {
    if (value == null || value <= 0) return 'Unlimited';
    return value.toString();
  }
}
