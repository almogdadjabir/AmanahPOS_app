import 'dart:async';

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

class SaleDetailSheet extends StatefulWidget {
  final SaleHistoryItem item;
  final VoidCallback? onReturnTap;

  const SaleDetailSheet({
    super.key,
    required this.item,
    required this.onReturnTap,
  });

  static void show(
      BuildContext context, {
        required SaleHistoryItem item,
        VoidCallback? onReturnTap,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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

  Future<void> _copyRef(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.displayRef));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reference copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _shareReceiptPdf() async {
    if (_isSharingPdf) return;

    setState(() => _isSharingPdf = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await SaleReceiptPdfService.sharePdf(item);
    } catch (e) {
      print('error: ${e.toString()}');
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Failed to generate receipt PDF'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingPdf = false);
      }
    }
  }

  Color _statusColor(SaleHistoryStatus status) {
    return switch (status) {
      SaleHistoryStatus.completed => AppColors.primary,
      SaleHistoryStatus.refunded => AppColors.danger,
      SaleHistoryStatus.partialRefund => AppColors.danger,
      SaleHistoryStatus.cancelled => AppColors.danger,
      SaleHistoryStatus.failed => AppColors.danger,
      _ => AppColors.slate500,
    };
  }

  IconData _statusIcon(SaleHistoryStatus status) {
    return switch (status) {
      SaleHistoryStatus.completed => Icons.check_circle_rounded,
      SaleHistoryStatus.refunded => Icons.keyboard_return_rounded,
      SaleHistoryStatus.partialRefund => Icons.keyboard_return_rounded,
      SaleHistoryStatus.cancelled => Icons.cancel_rounded,
      SaleHistoryStatus.failed => Icons.error_rounded,
      _ => Icons.pending_rounded,
    };
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDims.s3),

          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          const SizedBox(height: AppDims.s4),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
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
                    onTap: () => _copyRef(context),
                  ),

                  const SizedBox(height: AppDims.s3),

                  Wrap(
                    spacing: AppDims.s2,
                    runSpacing: AppDims.s2,
                    children: [
                      _Chip(
                        item.status.label,
                        color: _statusColor(item.status),
                        icon: _statusIcon(item.status),
                      ),
                      _Chip(
                        item.paymentLabel,
                        color: _paymentColor(item.paymentLabel),
                        icon: Icons.payments_rounded,
                      ),
                      _Chip(
                        DateFormat('d MMM · HH:mm').format(item.createdAt),
                        icon: Icons.access_time_rounded,
                      ),
                      if (item.shopName != null && item.shopName!.trim().isNotEmpty)
                        _Chip(
                          item.shopName!,
                          icon: Icons.store_rounded,
                        ),
                    ],
                  ),

                  const SizedBox(height: AppDims.s4),

                  _ItemsCard(item: item),

                  const SizedBox(height: AppDims.s4),

                  if (item.isOfflinePending) ...[
                    const _AlertBanner(
                      icon: Icons.wifi_off_rounded,
                      message:
                      'This sale is pending sync. Returns and final receipt number are only available after the sale syncs to the server.',
                      color: AppColors.warning,
                      background: AppColors.warningLight,
                    ),
                    const SizedBox(height: AppDims.s2),
                  ],

                  if (item.status == SaleHistoryStatus.refunded ||
                      item.status == SaleHistoryStatus.partialRefund) ...[
                    const _AlertBanner(
                      icon: Icons.info_rounded,
                      message: 'This sale has already been refunded.',
                      color: AppColors.danger,
                      background: AppColors.dangerLight,
                    ),
                    const SizedBox(height: AppDims.s2),
                  ],

                  if (item.canBeReturned && widget.onReturnTap != null) ...[
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onReturnTap!();
                      },
                      icon: const Icon(
                        Icons.keyboard_return_rounded,
                        size: 18,
                      ),
                      label: const Text('Return items from this sale'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dangerLight,
                        foregroundColor: AppColors.danger,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDims.s2),
                  ],

                  FilledButton.icon(
                    onPressed: _isSharingPdf ? null : _shareReceiptPdf,
                    icon: _isSharingPdf
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _isSharingPdf ? 'Preparing receipt...' : 'Share receipt PDF',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDims.s2),

                  Text(
                    'The receipt will be shared as a PDF file. Choose WhatsApp from the share options.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sm100(context).copyWith(
                      color: colors.textHint,
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

class _ReceiptReferenceCard extends StatelessWidget {
  final SaleHistoryItem item;
  final VoidCallback onTap;

  const _ReceiptReferenceCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasReceiptNumber = item.receiptNumber?.isNotEmpty == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDims.s4),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasReceiptNumber
                      ? Icons.receipt_rounded
                      : Icons.hourglass_empty_rounded,
                  size: 11,
                  color: colors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  hasReceiptNumber ? 'RECEIPT NUMBER' : 'TEMPORARY REFERENCE',
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textHint,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDims.s2),

            Text(
              item.displayRef,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDims.s2),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 11,
                  color: colors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to copy',
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final SaleHistoryItem item;

  const _ItemsCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: item.items.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Text(
          'No item details available',
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      )
          : Column(
        children: [
          for (int i = 0; i < item.items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colors.border.withValues(alpha: 0.6),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.items[i].productName,
                      style: AppTextStyles.bs200(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${item.items[i].quantity.toStringAsFixed(0)}',
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Text(
                    AppFormat.moneyWithUnit(item.items[i].subtotal),
                    style: AppTextStyles.bs200(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Divider(
            height: 1,
            color: colors.border,
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s3,
            ),
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryDark,
                  ),
                ),
                Text(
                  AppFormat.moneyWithUnit(item.total),
                  style: AppTextStyles.bs500(context).copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.secondaryDark,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color background;

  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bs100(context).copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const _Chip(
      this.label, {
        this.color,
        this.icon,
      });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = color ?? colors.textSecondary;
    final bg = (color ?? colors.border).withValues(alpha: 0.12);
    final border = (color ?? colors.border).withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: fg,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}