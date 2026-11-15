import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class ExpiryAlertCard extends StatelessWidget {
  final ExpiryAlertData item;

  const ExpiryAlertCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final expired = item.isExpiredSafe;

    final statusColor = expired ? colors.danger : colors.warning;

    final statusLabel = expired
        ? context.tr.invExpiryExpired
        : context.tr.invExpiryExpiringSoon;

    final statusIcon = expired
        ? PhosphorIconsRegular.warningCircle
        : PhosphorIconsRegular.warning;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
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
            child: Icon(statusIcon, color: statusColor, size: 26),
          ),

          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? context.tr.product,
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
                        PhosphorIconsRegular.storefront,
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
                  _expiryLabel(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.w800),
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
                    style: AppTextStyles.bs100(
                      context,
                    ).copyWith(color: statusColor, fontWeight: FontWeight.w900),
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
                context.tr.qty,
                style: AppTextStyles.bs200(
                  context,
                ).copyWith(color: colors.textHint, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _expiryLabel(BuildContext context) {
    final tr = context.tr;
    final date = item.parsedExpiryDate;
    if (date == null) return item.expiryDate ?? '';

    final formatted = DateFormat('dd MMM yyyy').format(date);
    final days = item.calculatedExpiresInDays;

    if (days == null) return formatted;

    if (days < 0) {
      return '$formatted · ${tr.exExpiredAgo(-days)}';
    }

    if (days == 0) {
      return '$formatted · ${tr.exToday}';
    }

    return '$formatted · ${tr.exInDays(days)}';
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
