import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';

class BusinessSummaryCard extends StatelessWidget {
  final BusinessData data;

  const BusinessSummaryCard({super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = data.isActive ?? false;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                alignment: Alignment.center,
                child: Text(
                  data.name?.initials ?? '?',
                  style: AppTextStyles.bs600(context).copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                )
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name ?? 'Business',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.address?.isNotEmpty == true
                          ? data.address!
                          : 'No address added yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          Row(
            children: [
              Expanded(
                child: metricTile(
                  context: context,
                  icon: Icons.store_outlined,
                  label: 'Shops',
                  value: '${data.shopCount ?? 0}',
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: metricTile(
                  context: context,
                  icon: isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  label: 'Status',
                  value: isActive ? 'Active' : 'Inactive',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget metricTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
}){
    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: context.appColors.primary,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: context.appColors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}