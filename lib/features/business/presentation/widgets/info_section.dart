import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  final BusinessData business;
  const InfoSection({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final isActive = business.isActive ?? false;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          _InfoRow(
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
          if (business.address != null)  ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: business.address!,
            ),
            Divider(
              height: 1, thickness: 1,
              indent: AppDims.s4,
              color: context.appColors.border,
            ),
          ],
          if (business.phone != null) ...[
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: business.phone!,
            ),
            Divider(
              height: 1, thickness: 1,
              indent: AppDims.s4,
              color: context.appColors.border,
            ),
          ],
          if (business.email != null) ...[
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: business.email!,
            ),
            Divider(
              height: 1, thickness: 1,
              indent: AppDims.s4,
              color: context.appColors.border,
            ),
          ],
          _InfoRow(
            icon: Icons.store_outlined,
            label: 'Shops',
            value: '${business.shopCount ?? 0} shop${(business.shopCount ?? 0) == 1 ? '' : 's'}',
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
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: iconColor ?? context.appColors.textHint),
          const SizedBox(width: AppDims.s3),
          Text(
            label,
            style: AppTextStyles.bs400(context).copyWith(
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
              style: AppTextStyles.bs400(context).copyWith(
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