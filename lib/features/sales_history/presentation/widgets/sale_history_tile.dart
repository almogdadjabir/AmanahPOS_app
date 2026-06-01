import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleHistoryTile extends StatelessWidget {
  const SaleHistoryTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final SaleHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final borderColor = item.isOfflinePending
        ? AppColors.warning.withValues(alpha: 0.45)
        : colors.border;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            highlightColor: colors.primary.withValues(alpha: 0.08),
            splashColor: colors.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  _StatusIconBox(item: item),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: _SaleMainInfo(item: item),
                  ),
                  const SizedBox(width: AppDims.s3),
                  _SaleAmountInfo(item: item),
                  const SizedBox(width: AppDims.s2),
                  DirectionalIcon(
                    icon: SolarIconsOutline.altArrowRight,
                    size: 18,
                    color: colors.textHint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaleMainInfo extends StatelessWidget {
  const _SaleMainInfo({
    required this.item,
  });

  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _LtrValueText(
                item.displayRef,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  height: 1.1,
                ),
              ),
            ),
            if (item.isOfflinePending) ...[
              const SizedBox(width: 6),
              const _OfflinePill(),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _PaymentDot(color: _paymentColor(context, item.paymentLabel)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                _metaText(context, item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                textDirection: Directionality.of(context),
                style: AppTextStyles.sm300(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaleAmountInfo extends StatelessWidget {
  const _SaleAmountInfo({
    required this.item,
  });

  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 118),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _LtrValueText(
            AppFormat.moneyWithUnit(item.total),
            textAlign: TextAlign.end,
            style: AppTextStyles.bs200(context).copyWith(
              fontWeight: FontWeight.w900,
              color: _amountColor(colors, item.status),
              height: 1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          _StatusBadge(status: item.status),
        ],
      ),
    );
  }
}

class _LtrValueText extends StatelessWidget {
  const _LtrValueText(
      this.value, {
        required this.style,
        this.textAlign = TextAlign.start,
      });

  final String value;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
      style: style,
    );
  }
}

class _StatusIconBox extends StatelessWidget {
  const _StatusIconBox({
    required this.item,
  });

  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = _iconBg(colors, item);
    final fg = _iconColor(item);
    final icon = _iconData(item);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: fg.withValues(alpha: 0.14),
        ),
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(
          icon,
          size: 21,
          color: fg,
        ),
      ),
    );
  }
}

class _PaymentDot extends StatelessWidget {
  const _PaymentDot({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 6,
        height: 6,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final SaleHistoryStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        child: Text(
          _statusLabel(context, status),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.sm300(context).copyWith(
            fontWeight: FontWeight.w900,
            color: fg,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              SolarIconsOutline.wifiRouterRound,
              size: 10,
              color: AppColors.warning,
            ),
            const SizedBox(width: 3),
            Text(
              context.tr.offline,
              style: AppTextStyles.sm300(context).copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.warning,
                height: 1,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _metaText(BuildContext context, SaleHistoryItem item) {
  final date = _formatDate(context, item.createdAt);
  final payment = _paymentLabel(context, item.paymentLabel);
  final count = context.tr.itemCount(item.itemCount);

  return '$date · $payment · $count';
}

String _formatDate(BuildContext context, DateTime dateTime) {
  final now = DateTime.now();
  final localDate = dateTime.toLocal();

  final today = DateTime(now.year, now.month, now.day);
  final saleDay = DateTime(localDate.year, localDate.month, localDate.day);
  final diffDays = today.difference(saleDay).inDays;

  final locale = Localizations.localeOf(context).toLanguageTag();
  final time = DateFormat.Hm(locale).format(localDate);

  if (diffDays == 0) return context.tr.todayWithTime(time);
  if (diffDays == 1) return context.tr.yesterdayWithTime(time);

  return DateFormat('d MMM · HH:mm', locale).format(localDate);
}

String _paymentLabel(BuildContext context, String label) {
  final normalized = label.toLowerCase().trim();

  if (normalized.contains('cash')) return context.tr.cash;
  if (normalized.contains('card')) return context.tr.card;
  if (normalized.contains('bankak')) return context.tr.bankak;
  if (normalized.contains('transfer')) return context.tr.bankTransfer;

  return label.trim().isEmpty ? context.tr.payment : label;
}

Color _paymentColor(BuildContext context, String label) {
  final normalized = label.toLowerCase().trim();

  if (normalized.contains('cash')) return AppColors.cash;
  if (normalized.contains('card')) return AppColors.card;
  if (normalized.contains('bankak')) return context.appColors.primary;
  if (normalized.contains('transfer')) return context.appColors.primary;

  return AppColors.slate400;
}

Color _iconBg(AppThemeColors colors, SaleHistoryItem item) {
  if (item.isOfflinePending) return AppColors.warningLight;

  return switch (item.status) {
    SaleHistoryStatus.completed => AppColors.primaryLight,
    SaleHistoryStatus.refunded => AppColors.dangerLight,
    SaleHistoryStatus.partialRefund => AppColors.dangerLight,
    SaleHistoryStatus.cancelled => AppColors.dangerLight,
    SaleHistoryStatus.failed => AppColors.dangerLight,
    SaleHistoryStatus.pending => AppColors.warningLight,
    _ => colors.surfaceSoft,
  };
}

IconData _iconData(SaleHistoryItem item) {
  if (item.isOfflinePending) return SolarIconsOutline.wifiRouterRound;

  return switch (item.status) {
    SaleHistoryStatus.completed => SolarIconsOutline.checkCircle,
    SaleHistoryStatus.refunded => SolarIconsOutline.undoLeft,
    SaleHistoryStatus.partialRefund => SolarIconsOutline.undoLeft,
    SaleHistoryStatus.cancelled => SolarIconsOutline.closeCircle,
    SaleHistoryStatus.failed => SolarIconsOutline.dangerTriangle,
    SaleHistoryStatus.pending => SolarIconsOutline.clockCircle,
    _ => SolarIconsOutline.billList,
  };
}

Color _iconColor(SaleHistoryItem item) {
  if (item.isOfflinePending) return AppColors.warning;

  return switch (item.status) {
    SaleHistoryStatus.completed => AppColors.primary,
    SaleHistoryStatus.refunded => AppColors.danger,
    SaleHistoryStatus.partialRefund => AppColors.danger,
    SaleHistoryStatus.cancelled => AppColors.danger,
    SaleHistoryStatus.failed => AppColors.danger,
    SaleHistoryStatus.pending => AppColors.warning,
    _ => AppColors.slate500,
  };
}

Color _amountColor(AppThemeColors colors, SaleHistoryStatus status) {
  return switch (status) {
    SaleHistoryStatus.completed => AppColors.secondary,
    SaleHistoryStatus.refunded => AppColors.danger,
    SaleHistoryStatus.partialRefund => AppColors.danger,
    SaleHistoryStatus.cancelled => colors.textHint,
    SaleHistoryStatus.failed => colors.textHint,
    _ => colors.textPrimary,
  };
}

(Color, Color) _statusColors(SaleHistoryStatus status) {
  return switch (status) {
    SaleHistoryStatus.completed =>
    (AppColors.primaryLight, AppColors.primaryDark),
    SaleHistoryStatus.refunded => (AppColors.dangerLight, AppColors.danger),
    SaleHistoryStatus.partialRefund =>
    (AppColors.dangerLight, AppColors.danger),
    SaleHistoryStatus.cancelled => (AppColors.dangerLight, AppColors.danger),
    SaleHistoryStatus.pending => (AppColors.warningLight, AppColors.warning),
    SaleHistoryStatus.failed => (AppColors.dangerLight, AppColors.danger),
    _ => (AppColors.slate100, AppColors.slate500),
  };
}

String _statusLabel(BuildContext context, SaleHistoryStatus status) {
  return switch (status) {
    SaleHistoryStatus.completed => context.tr.completed,
    SaleHistoryStatus.refunded => context.tr.returned,
    SaleHistoryStatus.partialRefund => context.tr.partiallyReturned,
    SaleHistoryStatus.cancelled => context.tr.cancelled,
    SaleHistoryStatus.pending => context.tr.pending,
    SaleHistoryStatus.failed => context.tr.failed,
    _ => context.tr.unknown,
  };
}