import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_view.dart';
import 'dart:ui' show PathMetric;
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class SaleReceiptSheet extends StatelessWidget {
  final String? receiptNumber;
  final String clientSaleId;
  final List<PosCartItem> items;
  final double total;
  final String paymentMethod;
  final bool isOffline;
  final String businessName;
  final double subtotal;
  final double taxAmount;
  final String taxName;
  final String taxRateLabel;
  final bool taxInclusive;

  const SaleReceiptSheet({
    super.key,
    required this.receiptNumber,
    required this.clientSaleId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.isOffline,
    required this.businessName,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.taxName = 'VAT',
    this.taxRateLabel = '0',
    this.taxInclusive = false,
  });

  static void show(
    BuildContext context, {
    required String? receiptNumber,
    required String clientSaleId,
    required List<PosCartItem> items,
    required double total,
    required String paymentMethod,
    required bool isOffline,
    required String businessName,
    double subtotal = 0,
    double taxAmount = 0,
    String taxName = 'VAT',
    String taxRateLabel = '0',
    bool taxInclusive = false,
  }) {
    showAppSheet<void>(
      context,
      builder: (_) => SaleReceiptSheet(
        receiptNumber: receiptNumber,
        clientSaleId: clientSaleId,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        isOffline: isOffline,
        businessName: businessName,
        subtotal: subtotal,
        taxAmount: taxAmount,
        taxName: taxName,
        taxRateLabel: taxRateLabel,
        taxInclusive: taxInclusive,
      ),
    );
  }

  String get _paymentLabel => switch (paymentMethod) {
    'cash' => 'Cash',
    'bankak' => 'Bankak',
    'card' => 'Card',
    'split' => 'Split',
    'credit' => 'On account',
    'bank_transfer' => 'Bank Transfer',
    'mobile_wallet' => 'Mobile Wallet',
    _ => paymentMethod,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final tone = isOffline ? colors.warning : colors.success;
    final toneBg = isOffline
        ? colors.warningContainer
        : colors.successContainer;

    return AppSheet(
      title: isOffline ? tr.savedOffline : tr.saleComplete,
      maxHeightFactor: 0.92,
      keyboardSafe: false,
      footer: AppButton.wide(
        label: tr.newSale,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDims.s2),
          Center(
            child: _SuccessMark(
              offline: isOffline,
              color: tone,
              background: toneBg,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            taxAmount > 0 && taxInclusive
                ? tr.totalInclTax(taxName, taxRateLabel)
                : tr.totalPaid,
            textAlign: TextAlign.center,
            style: text.bodyMedium!.copyWith(color: colors.textHint),
          ),
          const SizedBox(height: AppDims.s1),
          Center(
            child: _CountUpAmount(
              value: total,
              style: text.displaySmall!.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 40,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _paymentLabel,
            textAlign: TextAlign.center,
            style: text.bodySmall!.copyWith(color: colors.textHint),
          ),
          if (isOffline) ...[
            const SizedBox(height: AppDims.s4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.warningContainer,
                borderRadius: AppDims.borderMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDims.s3),
                child: Text(
                  'Real receipt number will be assigned once synced. '
                  'You can share this temporary reference now.',
                  style: text.bodySmall!.copyWith(
                    color: colors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppDims.s5),
          ReceiptView(saleId: clientSaleId, showPaper: false),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({
    required this.offline,
    required this.color,
    required this.background,
  });

  final bool offline;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: SizedBox(
        width: 88,
        height: 88,
        child: offline
            ? Icon(PhosphorIconsRegular.wifiSlash, size: 40, color: color)
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Motion.duration(const Duration(milliseconds: 520)),
                curve: AppDims.ease,
                builder: (context, progress, _) => CustomPaint(
                  painter: _CheckPainter(progress: progress, color: color),
                ),
              ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.29, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.71, size.height * 0.36);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final PathMetric metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

class _CountUpAmount extends StatelessWidget {
  const _CountUpAmount({required this.value, required this.style});

  final double value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Motion.duration(AppDims.slow * 2),
      curve: AppDims.soft,
      builder: (context, v, _) => AppAmount(
        value: AppFormat.money(v),
        unit: AppFormat.currency,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Print row driven by the live [PrinterBloc] state: set-up shortcut when no
/// printer is saved, spinner while connecting/printing.