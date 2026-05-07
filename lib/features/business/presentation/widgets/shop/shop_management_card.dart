import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ShopManagementCard extends StatelessWidget {
  final Shops shop;
  final String? businessId;

  const ShopManagementCard({super.key,
    required this.shop,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = shop.isActive ?? false;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDims.rLg),
        onTap: () {
          if (businessId == null) return;

          Navigator.of(context).pushNamed(
            RouteStrings.shopDetailScreen,
            arguments: {
              'businessId': businessId,
              'shop': shop,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: colors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name ?? 'Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (shop.address?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.address!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs200(context).copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDims.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                            : colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.bs100(context).copyWith(
                          color: isActive ? const Color(0xFF16A34A) : colors.textHint,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s2),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
