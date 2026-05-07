import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ShopQuickStats extends StatelessWidget {
  final List<Shops> shops;

  const ShopQuickStats({super.key,
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = shops.where((shop) => shop.isActive == true).length;
    final inactiveCount = shops.length - activeCount;

    return Row(
      children: [
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.store_mall_directory_outlined,
            label: 'Total Shops',
            value: '${shops.length}',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.check_circle_outline_rounded,
            label: 'Active',
            value: '$activeCount',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.pause_circle_outline_rounded,
            label: 'Inactive',
            value: '$inactiveCount',
          ),
        ),
      ],
    );
  }

  Widget statCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: colors.primary,
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            value,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}