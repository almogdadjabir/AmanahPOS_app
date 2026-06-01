import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ShopInfoSection extends StatelessWidget {
  final ShopData shop;

  const ShopInfoSection({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = shop.isActive ?? false;
    final address = shop.address?.trim();
    final phone = shop.phone?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: SolarIconsBold.recordCircle,
            iconColor: isActive
                ? const Color(0xFF22C55E)
                : colors.textHint,
            label: context.tr.status,
            value: isActive ? context.tr.active : context.tr.inactive,
          ),

          _InfoDivider(color: colors.border),

          if (address != null && address.isNotEmpty) ...[
            _InfoRow(
              icon: SolarIconsOutline.mapPoint,
              label: context.tr.address,
              value: address,
            ),
            _InfoDivider(color: colors.border),
          ],

          if (phone != null && phone.isNotEmpty)
            _InfoRow(
              icon: SolarIconsOutline.phone,
              label: context.tr.phone,
              value: phone,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor ?? colors.textHint,
          ),
          const SizedBox(width: AppDims.s3),
          Text(
            label,
            style: AppTextStyles.bs500(context).copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  final Color color;

  const _InfoDivider({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppDims.s4,
      endIndent: AppDims.s4,
      color: color,
    );
  }
}