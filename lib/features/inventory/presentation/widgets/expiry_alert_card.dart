import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class ExpiryAlertCard extends StatelessWidget {
  final ExpiryAlertData item;

  const ExpiryAlertCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expired = item.isExpiredSafe;

    final statusColor = expired
        ? const Color(0xFFDC2626)
        : const Color(0xFFEA580C);

    final statusLabel = expired ? 'Expired' : 'Expiring Soon';

    final statusIcon = expired
        ? SolarIconsOutline.dangerCircle
        : SolarIconsOutline.dangerTriangle;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 26,
            ),
          ),

          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                if (item.shopName?.trim().isNotEmpty == true) ...[
                  Row(
                    children: [
                      Icon(
                        SolarIconsOutline.shop,
                        size: 15,
                        color: colors.textHint,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.shopName!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],

                Text(
                  _expiryLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppDims.s2),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.bs100(context).copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDims.s3),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatQty(item.qty),
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty',
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _expiryLabel() {
    final date = item.parsedExpiryDate;
    if (date == null) return item.expiryDate ?? '';

    final formatted = DateFormat('dd MMM yyyy').format(date);
    final days = item.calculatedExpiresInDays;

    if (days == null) return formatted;

    if (days < 0) {
      final count = -days;
      return '$formatted · Expired $count day${count == 1 ? '' : 's'} ago';
    }

    if (days == 0) {
      return '$formatted · Expires today';
    }

    return '$formatted · In $days day${days == 1 ? '' : 's'}';
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}