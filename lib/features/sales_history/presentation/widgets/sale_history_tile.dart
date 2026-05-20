import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaleHistoryTile extends StatelessWidget {
  final SaleHistoryItem item;
  final VoidCallback onTap;

  const SaleHistoryTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Wrap in a border container, then Material+InkWell for the ripple
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isOfflinePending
              ? AppColors.warning.withValues(alpha: 0.45)
              : colors.border,
        ),
      ),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(13), // 1px inside the border
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          highlightColor: AppColors.primaryLight.withValues(alpha: 0.5),
          splashColor: AppColors.primaryLight.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: AppDims.s3),
            child: Row(
              children: [
                // ── Status icon ─────────────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBg(colors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconData, size: 20, color: _iconColor),
                ),
                const SizedBox(width: AppDims.s3),

                // ── Ref + meta ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reference number row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.displayRef,
                              style: AppTextStyles.bs100(context).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isOfflinePending) ...[
                            const SizedBox(width: 6),
                            const _OfflinePill(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Meta row with payment dot
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: _paymentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_formatDate(item.createdAt)} · '
                                  '${item.paymentLabel} · '
                                  '${item.itemCount} item${item.itemCount == 1 ? '' : 's'}',
                              style: AppTextStyles.sm100(context)
                                  .copyWith(color: colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s3),

                // ── Amount + badge ──────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormat.moneyWithUnit(item.total),
                      style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: _amountColor(colors),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: item.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isYesterday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1;
    final time = DateFormat('HH:mm').format(dt);
    if (isToday) return 'Today $time';
    if (isYesterday) return 'Yesterday $time';
    return DateFormat('d MMM · HH:mm').format(dt);
  }

  /// Colored dot showing payment method at a glance.
  Color get _paymentColor {
    final label = item.paymentLabel.toLowerCase();
    if (label.contains('cash')) return AppColors.cash;       // amber
    if (label.contains('card')) return AppColors.card;       // blue
    if (label.contains('transfer')) return AppColors.primary; // emerald
    return AppColors.slate400;
  }

  Color _iconBg(AppThemeColors colors) {
    if (item.isOfflinePending) return AppColors.warningLight;
    return switch (item.status) {
      SaleHistoryStatus.completed => AppColors.primaryLight,
      SaleHistoryStatus.refunded => AppColors.dangerLight,
      SaleHistoryStatus.partialRefund => AppColors.dangerLight,
      SaleHistoryStatus.cancelled => AppColors.dangerLight,
      SaleHistoryStatus.failed => AppColors.dangerLight,
      _ => colors.surfaceSoft,
    };
  }

  IconData get _iconData {
    if (item.isOfflinePending) return Icons.wifi_off_rounded;
    return switch (item.status) {
      SaleHistoryStatus.completed => Icons.check_circle_rounded,
      SaleHistoryStatus.refunded => Icons.keyboard_return_rounded,
      SaleHistoryStatus.partialRefund => Icons.keyboard_return_rounded,
      SaleHistoryStatus.cancelled => Icons.cancel_rounded,
      SaleHistoryStatus.failed => Icons.error_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  Color get _iconColor {
    if (item.isOfflinePending) return AppColors.warning;
    return switch (item.status) {
      SaleHistoryStatus.completed => AppColors.primary,   // emerald ✓
      SaleHistoryStatus.refunded => AppColors.danger,
      SaleHistoryStatus.partialRefund => AppColors.danger,
      SaleHistoryStatus.cancelled => AppColors.danger,
      SaleHistoryStatus.failed => AppColors.danger,
      _ => AppColors.slate500,
    };
  }

  Color _amountColor(AppThemeColors colors) => switch (item.status) {
    SaleHistoryStatus.completed => AppColors.secondary,  // amber for money
    SaleHistoryStatus.refunded => AppColors.danger,
    _ => colors.textPrimary,
  };
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final SaleHistoryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      SaleHistoryStatus.completed =>
      (AppColors.primaryLight, AppColors.primaryDark),
      SaleHistoryStatus.refunded =>
      (AppColors.dangerLight, AppColors.danger),
      SaleHistoryStatus.partialRefund =>
      (AppColors.dangerLight, AppColors.danger),
      SaleHistoryStatus.cancelled =>
      (AppColors.dangerLight, AppColors.danger),
      SaleHistoryStatus.pending =>
      (AppColors.warningLight, AppColors.warning),
      SaleHistoryStatus.failed =>
      (AppColors.dangerLight, AppColors.danger),
      _ => (AppColors.slate100, AppColors.slate500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Offline Pill ─────────────────────────────────────────────────────────────

class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 9, color: AppColors.warning),
          SizedBox(width: 3),
          Text(
            'offline',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
