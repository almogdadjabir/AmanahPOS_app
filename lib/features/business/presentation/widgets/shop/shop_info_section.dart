import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ShopInfoSection extends StatelessWidget {
  final Shops shop;
  const ShopInfoSection({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final isActive = shop.isActive ?? false;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          infoRow(
            context: context,
            icon: Icons.circle,
            iconColor: isActive
                ? const Color(0xFF22C55E)
                : context.appColors.textHint,
            label: 'Status',
            value: isActive ? 'Active' : 'Inactive',
          ),
          Divider(
            height: 1, thickness: 1,
            indent: AppDims.s4,
            color: context.appColors.border,
          ),

          if (shop.address != null) ...[
            infoRow(
              context: context,
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: shop.address!,
            ),
            Divider(
              height: 1, thickness: 1,
              indent: AppDims.s4,
              color: context.appColors.border,
            ),
          ],
          if (shop.phone != null)
            infoRow(
              context: context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: shop.phone!,
            ),
        ],
      ),
    );
  }

  Widget infoRow({required BuildContext context, Color? iconColor,required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Icon(icon, size: 24,
              color: iconColor ?? context.appColors.textHint),
          const SizedBox(width: AppDims.s3),
          Text(
            label,
            style: AppTextStyles.bs500(context).copyWith(
            fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs500(context).copyWith(
              fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}