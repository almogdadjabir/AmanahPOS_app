import 'dart:async';
import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/services/sale_receipt_pdf_service.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleDetailSheet extends StatefulWidget {
  const SaleDetailSheet({
    super.key,
    required this.item,
    required this.onReturnTap,
  });

  final SaleHistoryItem item;
  final VoidCallback? onReturnTap;

  static void show(
      BuildContext context, {
        required SaleHistoryItem item,
        VoidCallback? onReturnTap,
      }) {
    showAdaptivePanel<void>(
      context,
      desktopWidth: 480,
      builder: (_) => SaleDetailSheet(
        item: item,
        onReturnTap: onReturnTap,
      ),
    );
  }

  @override
  State<SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<SaleDetailSheet> {
  bool _isSharingPdf = false;

  SaleHistoryItem get item => widget.item;

  Future<void> _copyRef() async {
    await Clipboard.setData(
      ClipboardData(text: item.displayRef),
    );

    if (!mounted) return;

    _showSnackBar(
      context,
      message: context.tr.refCopied,
      backgroundColor: AppColors.slate800,
    );
  }

  Future<void> _shareReceiptPdf() async {
    if (_isSharingPdf) return;

    setState(() => _isSharingPdf = true);

    try {
      await SaleReceiptPdfService.sharePdf(
        item,
        strings: SaleReceiptPdfStrings.fromContext(context),
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        context,
        message: context.tr.saleReceiptFailure,
        backgroundColor: AppColors.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingPdf = false);
      }
    }
  }

  void _handleReturnTap() {
    Navigator.of(context).pop();
    widget.onReturnTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDims.s4,
                0,
                AppDims.s4,
                AppDims.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReceiptReferenceCard(
                    item: item,
                    onTap: _copyRef,
                  ),
                  const SizedBox(height: AppDims.s3),
                  _MetaChips(item: item),
                  const SizedBox(height: AppDims.s4),
                  _ItemsCard(item: item),
                  const SizedBox(height: AppDims.s4),
                  if (item.isOfflinePending) ...[
                    _AlertBanner(
                      icon: SolarIconsOutline.wifiRouterRound,
                      message: context.tr.salePendingSyncDescription,
                      color: AppColors.warning,
                      background: AppColors.warningLight,
                    ),
                    const SizedBox(height: AppDims.s2),
                  ],
                  if (item.status == SaleHistoryStatus.refunded ||
                      item.status == SaleHistoryStatus.partialRefund) ...[
                    _AlertBanner(
                      icon: SolarIconsOutline.infoCircle,
                      message: context.tr.saleAlreadyRefunded,
                      color: AppColors.danger,
                      background: AppColors.dangerLight,
                    ),
                    const SizedBox(height: AppDims.s2),
                  ],
                  if (item.canBeReturned && widget.onReturnTap != null) ...[
                    _ReturnItemsButton(onPressed: _handleReturnTap),
                    const SizedBox(height: AppDims.s2),
                  ],
                  _ShareReceiptButton(
                    isLoading: _isSharingPdf,
                    onPressed: _shareReceiptPdf,
                  ),
                  const SizedBox(height: AppDims.s2),
                  Text(
                    context.tr.receiptPdfShareHint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bs300(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const SizedBox(width: 36, height: 4),
    );
  }
}

class _ReceiptReferenceCard extends StatelessWidget {
  const _ReceiptReferenceCard({
    required this.item,
    required this.onTap,
  });

  final SaleHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasReceiptNumber = item.receiptNumber?.trim().isNotEmpty == true;

    return Material(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDims.s4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasReceiptNumber
                          ? SolarIconsOutline.billList
                          : SolarIconsOutline.hourglass,
                      size: 12,
                      color: colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasReceiptNumber
                          ? context.tr.receiptNumberLabel
                          : context.tr.temporaryReferenceLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textHint,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDims.s2),
                Text(
                  item.displayRef,
                  textDirection: ui.TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      SolarIconsOutline.copy,
                      size: 12,
                      color: colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr.tapToCopy,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.item,
  });

  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final shopName = item.shopName?.trim();

    return Wrap(
      spacing: AppDims.s2,
      runSpacing: AppDims.s2,
      children: [
        _Chip(
          _statusLabel(context, item.status),
          color: _statusColor(item.status),
          icon: _statusIcon(item.status),
        ),
        _Chip(
          _paymentLabel(context, item.paymentLabel),
          color: _paymentColor(item.paymentLabel),
          icon: SolarIconsOutline.walletMoney,
        ),
        _Chip(
          _formatDate(context, item.createdAt),
          icon: SolarIconsOutline.clockCircle,
          forceLtr: true,
        ),
        if (shopName != null && shopName.isNotEmpty)
          _Chip(
            shopName,
            icon: SolarIconsOutline.shop,
          ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.item,
  });

  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: item.items.isEmpty
            ? _EmptyItems()
            : Column(
          children: [
            for (int i = 0; i < item.items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: colors.border.withValues(alpha: 0.6),
                ),
              _ItemRow(
                name: item.items[i].productName,
                quantity: item.items[i].quantity,
                subtotal: item.items[i].subtotal,
              ),
            ],
            Divider(
              height: 1,
              color: colors.border,
            ),
            _TotalRow(total: item.total),
          ],
        ),
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppDims.s4),
      child: Text(
        context.tr.noItemDetailsAvailable,
        style: AppTextStyles.bs100(context).copyWith(
          color: colors.textHint,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final double quantity;
  final double subtotal;

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
          Expanded(
            child: Text(
              name.trim().isEmpty ? context.tr.product : name.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          _QuantityPill(quantity: quantity),
          const SizedBox(width: AppDims.s3),
          Flexible(
            child: Text(
              AppFormat.moneyWithUnit(subtotal),
              textDirection: ui.TextDirection.ltr,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({
    required this.quantity,
  });

  final double quantity;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 7,
          vertical: 3,
        ),
        child: Text(
          '×${quantity.toStringAsFixed(0)}',
          textDirection: ui.TextDirection.ltr,
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.total,
  });

  final double total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(17),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr.total,
                style: AppTextStyles.bs200(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Flexible(
              child: Text(
                AppFormat.moneyWithUnit(total),
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs500(context).copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.secondaryDark,
                  fontSize: 18,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 17,
              color: color,
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bs100(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnItemsButton extends StatelessWidget {
  const _ReturnItemsButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        SolarIconsOutline.undoLeft,
        size: 18,
      ),
      label: Text(context.tr.returnItemsAction),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.dangerLight,
        foregroundColor: AppColors.danger,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _ShareReceiptButton extends StatelessWidget {
  const _ShareReceiptButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: isLoading
            ? const SizedBox(
          key: ValueKey('loading'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
          SolarIconsOutline.documentText,
          key: ValueKey('icon'),
          size: 18,
        ),
      ),
      label: Text(
        isLoading ? context.tr.preparingReceipt : context.tr.shareReceiptPdf,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      this.label, {
        this.color,
        this.icon,
        this.forceLtr = false,
      });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = color ?? colors.textSecondary;
    final bg = (color ?? colors.border).withValues(alpha: 0.12);
    final border = (color ?? colors.border).withValues(alpha: 0.25);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: fg,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              textDirection:
              forceLtr ? ui.TextDirection.ltr : Directionality.of(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sm100(context).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: fg,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSnackBar(
    BuildContext context, {
      required String message,
      required Color backgroundColor,
    }) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

String _formatDate(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('d MMM · HH:mm', locale).format(dateTime.toLocal());
}

String _paymentLabel(BuildContext context, String label) {
  final normalized = label.toLowerCase().trim();

  if (normalized.contains('cash')) return context.tr.cash;
  if (normalized.contains('card')) return context.tr.card;
  if (normalized.contains('bankak')) return context.tr.bankak;
  if (normalized.contains('transfer')) return context.tr.bankTransfer;
  if (normalized.contains('wallet')) return context.tr.wallet;

  return label.trim().isEmpty ? context.tr.payment : label.trim();
}

Color _paymentColor(String label) {
  final value = label.toLowerCase();

  if (value.contains('cash')) return AppColors.cash;
  if (value.contains('card')) return AppColors.card;
  if (value.contains('transfer')) return AppColors.primary;
  if (value.contains('bankak')) return AppColors.primary;
  if (value.contains('wallet')) return AppColors.primary;

  return AppColors.slate500;
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

Color _statusColor(SaleHistoryStatus status) {
  return switch (status) {
    SaleHistoryStatus.completed => AppColors.primary,
    SaleHistoryStatus.refunded => AppColors.danger,
    SaleHistoryStatus.partialRefund => AppColors.danger,
    SaleHistoryStatus.cancelled => AppColors.danger,
    SaleHistoryStatus.failed => AppColors.danger,
    SaleHistoryStatus.pending => AppColors.warning,
    _ => AppColors.slate500,
  };
}

IconData _statusIcon(SaleHistoryStatus status) {
  return switch (status) {
    SaleHistoryStatus.completed => SolarIconsOutline.checkCircle,
    SaleHistoryStatus.refunded => SolarIconsOutline.undoLeft,
    SaleHistoryStatus.partialRefund => SolarIconsOutline.undoLeft,
    SaleHistoryStatus.cancelled => SolarIconsOutline.closeCircle,
    SaleHistoryStatus.failed => SolarIconsOutline.dangerTriangle,
    SaleHistoryStatus.pending => SolarIconsOutline.clockCircle,
    _ => SolarIconsOutline.clockCircle,
  };
}