import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/devices/domain/entities/receipt_data.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/devices/presentation/printer_l10n.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'dart:ui' show PathMetric;
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  String get _displayRef => receiptNumber?.isNotEmpty == true
      ? receiptNumber!
      : 'TMP-${clientSaleId.substring(0, 8).toUpperCase()}';

  String get _paymentLabel => switch (paymentMethod) {
    'cash' => 'Cash',
    'bankak' => 'Bankak',
    'card' => 'Card',
    'bank_transfer' => 'Bank Transfer',
    'mobile_wallet' => 'Mobile Wallet',
    _ => paymentMethod,
  };

  String _buildReceiptText() {
    final now = DateTime.now();
    final pad = (int n) => n.toString().padLeft(2, '0');
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${now.day} ${months[now.month]} ${now.year} ${pad(now.hour)}:${pad(now.minute)}';

    final sb = StringBuffer();
    sb.writeln('🧾 RECEIPT — AmanaPOS');
    sb.writeln('Ref: $_displayRef');
    if (isOffline) sb.writeln('⚠️  Saved offline — pending sync');
    sb.writeln('Date: $dateStr');
    sb.writeln('─────────────────────────');
    for (final item in items) {
      final name = (item.product.name ?? 'Item').padRight(16).substring(0, 16);
      sb.writeln(
        '$name x${item.quantity}  ${AppFormat.moneyWithUnit(item.lineTotal)}',
      );
    }
    sb.writeln('─────────────────────────');
    if (taxAmount > 0 && !taxInclusive) {
      sb.writeln('Subtotal: ${AppFormat.moneyWithUnit(subtotal)}');
      sb.writeln(
        'Tax ($taxName $taxRateLabel%): ${AppFormat.moneyWithUnit(taxAmount)}',
      );
    }
    sb.writeln('TOTAL:   ${AppFormat.moneyWithUnit(total)}');
    if (taxAmount > 0 && taxInclusive) {
      sb.writeln(
        'Incl. $taxName $taxRateLabel%: ${AppFormat.moneyWithUnit(taxAmount)}',
      );
    }
    sb.writeln('Payment: $_paymentLabel');
    sb.writeln('─────────────────────────');
    sb.writeln(businessName);
    sb.writeln('Powered by AmanaPOS');
    return sb.toString();
  }

  /// Mirrors [_buildReceiptText] for the thermal printer, with amounts
  /// pre-formatted so the ESC/POS encoder stays presentation-free.
  ReceiptData _buildReceiptData() {
    final summary = <ReceiptRow>[];
    if (taxAmount > 0 && !taxInclusive) {
      summary.add(
        ReceiptRow(label: 'Subtotal', value: AppFormat.moneyWithUnit(subtotal)),
      );
      summary.add(
        ReceiptRow(
          label: 'Tax ($taxName $taxRateLabel%)',
          value: AppFormat.moneyWithUnit(taxAmount),
        ),
      );
    }
    summary.add(
      ReceiptRow(
        label: 'TOTAL',
        value: AppFormat.moneyWithUnit(total),
        emphasized: true,
      ),
    );
    if (taxAmount > 0 && taxInclusive) {
      summary.add(
        ReceiptRow(
          label: 'Incl. $taxName $taxRateLabel%',
          value: AppFormat.moneyWithUnit(taxAmount),
        ),
      );
    }

    return ReceiptData(
      businessName: businessName,
      reference: 'Ref: $_displayRef',
      dateLabel: AppFormat.receiptDate(DateTime.now()),
      lines: [
        for (final item in items)
          ReceiptLine(
            name: item.product.name ?? 'Item',
            quantity: item.quantity,
            amount: AppFormat.moneyWithUnit(item.lineTotal),
          ),
      ],
      summary: summary,
      paymentLabel: _paymentLabel,
      offlineNote: isOffline ? 'Saved offline - pending sync' : null,
    );
  }

  Future<void> _shareWhatsApp() async {
    final text = Uri.encodeComponent(_buildReceiptText());
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareGeneral() async {
    await Share.share(_buildReceiptText(), subject: 'Receipt $_displayRef');
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _displayRef));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.receiptCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
          _ReferenceTile(
            label: receiptNumber?.isNotEmpty == true
                ? 'Receipt number'
                : 'Temporary reference',
            reference: _displayRef,
            hint: tr.tapToCopy,
            onTap: () => _copy(context),
          ),
          const SizedBox(height: AppDims.s4),
          _ReceiptLines(items: items),
          const SizedBox(height: AppDims.s3),
          if (taxAmount > 0 && !taxInclusive) ...[
            _SummaryRow(label: tr.subtotal, value: AppFormat.money(subtotal)),
            _SummaryRow(
              label: tr.taxWithRate(taxName, taxRateLabel),
              value: AppFormat.money(taxAmount),
            ),
          ],
          if (taxAmount > 0 && taxInclusive)
            _SummaryRow(
              label: tr.taxIncluded,
              value: AppFormat.money(taxAmount),
            ),
          const SizedBox(height: AppDims.s5),
          AppGroup(
            children: [
              _PrintReceiptRow(buildReceipt: _buildReceiptData),
              AppGroupRow(
                title: tr.shareViaWhatsApp,
                icon: PhosphorIconsRegular.chatCircle,
                tint: AppTint.success,
                onTap: _shareWhatsApp,
              ),
              AppGroupRow(
                title: tr.shareVia,
                icon: PhosphorIconsRegular.export,
                tint: AppTint.neutral,
                onTap: _shareGeneral,
              ),
            ],
          ),
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

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.label,
    required this.reference,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String reference;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: AppDims.borderMd,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4,
            vertical: AppDims.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.bodySmall!.copyWith(color: colors.textHint),
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        reference,
                        style: text.titleMedium!
                            .copyWith(color: colors.textPrimary)
                            .tabular,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.copy, size: 16, color: colors.textHint),
              const SizedBox(width: 4),
              Text(
                hint,
                style: text.bodySmall!.copyWith(color: colors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptLines extends StatelessWidget {
  const _ReceiptLines({required this.items});

  final List<PosCartItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 0.5, thickness: 0.5, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].product.name ?? 'Item',
                      textDirection:
                          (items[i].product.name ?? 'Item').contentDirection,
                      style: text.bodyLarge!.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '×${items[i].quantity}',
                    style: text.bodyMedium!
                        .copyWith(color: colors.textSecondary)
                        .tabular,
                  ),
                  const SizedBox(width: AppDims.s3),
                  AppAmount(
                    value: AppFormat.money(items[i].lineTotal),
                    style: text.bodyLarge!.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s1, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium!.copyWith(color: colors.textSecondary),
            ),
          ),
          AppAmount(
            value: value,
            unit: AppFormat.currency,
            style: text.bodyMedium!.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Print row driven by the live [PrinterBloc] state: set-up shortcut when no
/// printer is saved, spinner while connecting/printing.
class _PrintReceiptRow extends StatelessWidget {
  final ReceiptData Function() buildReceipt;

  const _PrintReceiptRow({required this.buildReceipt});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocConsumer<PrinterBloc, PrinterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case PrinterStatus.printSuccess:
            GlobalSnackBar.showSuccess(
              message: context.tr.printerStatusPrintSuccess,
            );
          case PrinterStatus.printFailed:
          case PrinterStatus.connectionFailed:
            final error = state.error;
            if (error != null) {
              GlobalSnackBar.showError(
                message: printerErrorMessage(context, error),
              );
            }
          default:
            break;
        }
      },
      builder: (context, state) {
        if (!state.hasSavedPrinter) {
          return AppGroupRow(
            title: context.tr.printerSetUp,
            icon: PhosphorIconsRegular.printer,
            tint: AppTint.neutral,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(RouteStrings.printerSettingsScreen),
          );
        }

        final isBusy = state.status.isBusy;

        return AppGroupRow(
          title: isBusy ? state.status.label(context) : context.tr.printReceipt,
          icon: PhosphorIconsRegular.printer,
          tint: AppTint.brand,
          showChevron: !isBusy,
          trailing: isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : null,
          onTap: isBusy
              ? null
              : () => context.read<PrinterBloc>().add(
                  PrinterReceiptPrintRequested(buildReceipt()),
                ),
        );
      },
    );
  }
}
