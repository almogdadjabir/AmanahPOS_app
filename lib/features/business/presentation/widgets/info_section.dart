import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  final BusinessData business;

  const InfoSection({
    super.key,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = business.isActive ?? false;

    final rows = <_InfoItem>[
      _InfoItem(
        icon: Icons.circle,
        iconColor: isActive
            ? const Color(0xFF22C55E)
            : context.appColors.textHint,
        label: 'Status',
        value: isActive ? 'Active' : 'Inactive',
      ),
      if (business.address?.trim().isNotEmpty == true)
        _InfoItem(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: business.address!.trim(),
        ),
      if (business.phone?.trim().isNotEmpty == true)
        _InfoItem(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: business.phone!.trim(),
        ),
      if (business.email?.trim().isNotEmpty == true)
        _InfoItem(
          icon: Icons.email_outlined,
          label: 'Email',
          value: business.email!.trim(),
        ),
      _InfoItem(
        icon: Icons.store_outlined,
        label: 'Shops',
        value:
        '${business.shopCount ?? 0} shop${(business.shopCount ?? 0) == 1 ? '' : 's'}',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final item = rows[index];

          return Column(
            children: [
              _InfoRow(item: item),
              if (index < rows.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: context.appColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });
}

class _InfoRow extends StatelessWidget {
  final _InfoItem item;

  const _InfoRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rSm),
            ),
            child: Icon(
              item.icon,
              size: item.icon == Icons.circle ? 10 : 16,
              color: item.iconColor ?? colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppDims.s3),

          Text(
            item.label,
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),

          const Spacer(),

          Flexible(
            child: Text(
              item.value,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}