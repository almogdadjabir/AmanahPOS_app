import 'package:amana_pos/features/inventory/data/models/responses/expiry_alert_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiryAlertCard extends StatelessWidget {
  final ExpiryAlertData item;

  const ExpiryAlertCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors   = context.appColors;
    final expired  = item.isExpiredSafe;

    final statusColor  = expired ? const Color(0xFFDC2626) : const Color(0xFFEA580C);
    final statusLabel  = expired ? 'Expired' : 'Expiring Soon';
    final statusIcon   = expired ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: [
          // ── Status icon ────────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),

          const SizedBox(width: AppDims.s3),

          // ── Product info ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs500(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),

                if (item.shopName != null) ...[
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, size: 12, color: colors.textHint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.shopName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs100(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                ],

                // Expiry date
                Text(
                  _expiryLabel(),
                  style: AppTextStyles.bs100(context).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppDims.s2),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s2,
                    vertical: 3,
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

          // ── Quantity ──────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatQty(item.qty),
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Qty',
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w700,
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
      return '$formatted · Expired ${(-days)} day${(-days) == 1 ? '' : 's'} ago';
    }
    if (days == 0) return '$formatted · Expires today';
    return '$formatted · In $days day${days == 1 ? '' : 's'}';
  }

  String _formatQty(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
