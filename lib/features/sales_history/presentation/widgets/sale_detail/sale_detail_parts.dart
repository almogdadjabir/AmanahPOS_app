import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// "Section" caption above a card (HTML .sec: 22pt above, 13pt hint).
class SaleSectionLabel extends StatelessWidget {
  final String text;
  final double top;

  const SaleSectionLabel(this.text, {super.key, this.top = 22});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, top, 20, 7),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: context.appColors.textHint),
      ),
    );
  }
}

/// Bottom dock (HTML .dock): blurred background, hairline on top.
class SaleDock extends StatelessWidget {
  final Widget child;

  const SaleDock({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDims.s4,
        10,
        AppDims.s4,
        keyboard ? 10 : MediaQuery.viewPaddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: child,
    );
  }
}

/// One label / value row (HTML .kvs): 46pt tall, value in secondary ink.
class SaleKvRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool numeric;
  final bool bold;
  final bool danger;
  final VoidCallback? onTap;

  const SaleKvRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.numeric = false,
    this.bold = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final valueStyle = TextStyle(
      fontSize: 17,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold
          ? colors.textPrimary
          : danger
          ? colors.danger
          : colors.textSecondary,
      fontFeatures: AppTextStyles.tabularFigures,
    );

    Widget v =
        valueWidget ??
        Text(
          value ?? '',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: valueStyle,
        );
    if (numeric && valueWidget == null) {
      v = Directionality(textDirection: TextDirection.ltr, child: v);
    }

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Align(alignment: AlignmentDirectional.centerEnd, child: v),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Pressable(onTap: onTap, scale: 1, child: row);
  }
}

/// Hero: payment tile, big amount, status pill, when.
class SaleDetailHero extends StatelessWidget {
  final SaleHistoryItem sale;

  const SaleDetailHero({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final pill =
        SaleStatusPill.forSale(context, sale) ??
        (sale.status == SaleHistoryStatus.cancelled
            ? SaleStatusPill(label: tr.shStatusCancelled)
            : SaleStatusPill.completed(context));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      child: Column(
        children: [
          SalePaymentTile(method: sale.paymentMethod, size: 56),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: saleNumber(sale.total),
                    style: TextStyle(
                      fontSize: 46,
                      height: 50 / 46,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                      color: colors.textPrimary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                  TextSpan(
                    text: ' ${tr.shUnit}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.textHint,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 8),
          pill,
          const SizedBox(height: 8),
          Text(
            saleWhen(context, sale.createdAt),
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Info / error banner above the cards (HTML .bn).
class SaleBanner extends StatelessWidget {
  final String text;
  final bool bad;
  final IconData icon;

  const SaleBanner({
    super.key,
    required this.text,
    this.bad = false,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = bad ? colors.danger : colors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: bad ? colors.dangerContainer : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, height: 20 / 15, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Items card: name, "qty × price · N returned", line total.
class SaleItemsCard extends StatelessWidget {
  final SaleHistoryItem sale;

  const SaleItemsCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final rows = <Widget>[];
    for (final line in sale.items) {
      final name = line.productName.trim().isEmpty
          ? tr.product
          : line.productName.trim();
      final qtyPrice =
          '${String.fromCharCode(0x202A)}${saleQty(line.quantity)} × ${saleNumber(line.unitPrice)}${String.fromCharCode(0x202C)}';
      rows.add(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: qtyPrice),
                            if (line.returnedQuantity > 0) ...[
                              const TextSpan(text: ' · '),
                              TextSpan(
                                text: tr.shLineReturned(
                                  saleQty(line.returnedQuantity),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.danger,
                                ),
                              ),
                            ],
                          ],
                        ),
                        style: TextStyle(fontSize: 13, color: colors.textHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    saleNumber(line.subtotal),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppFormGroup(children: rows);
  }
}

/// Subtotal, discount, tax, total, and net after returns.
class SaleTotalsCard extends StatelessWidget {
  final SaleHistoryItem sale;

  const SaleTotalsCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final subtotal = sale.items.fold<double>(0, (a, l) => a + l.subtotal);
    final returned = sale.refundedTotal;
    final hasReturns = returned > 0;

    String? taxLabel;
    if (sale.taxAmount > 0) {
      final rate = formatTaxLabelRate(sale.taxRate);
      taxLabel = sale.taxInclusive
          ? tr.shTaxIncluded(rate)
          : (sale.taxRate > 0 ? '${tr.shTax} $rate%' : tr.shTax);
    }

    return AppFormGroup(
      children: [
        SaleKvRow(
          label: tr.shSubtotal,
          value: saleNumber(subtotal),
          numeric: true,
        ),
        if (sale.discount > 0)
          SaleKvRow(
            label: tr.shDiscount,
            value: '−${saleNumber(sale.discount)}',
            numeric: true,
          ),
        if (taxLabel != null)
          SaleKvRow(
            label: taxLabel,
            value: saleNumber(sale.taxAmount),
            numeric: true,
          ),
        SaleKvRow(
          label: tr.shTotal,
          value: saleMoney(context, sale.total),
          numeric: true,
          bold: !hasReturns,
        ),
        if (hasReturns) ...[
          SaleKvRow(
            label: tr.shReturnedTotal,
            value: '−${saleMoney(context, returned)}',
            numeric: true,
          ),
          SaleKvRow(
            label: tr.shNet,
            value: saleMoney(context, sale.total - returned),
            numeric: true,
            bold: true,
          ),
        ],
      ],
    );
  }
}

String formatTaxLabelRate(double rate) =>
    rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(2);

/// Returns made on this sale: reference, −amount, time.
class SaleRefundsCard extends StatelessWidget {
  final SaleHistoryItem sale;

  const SaleRefundsCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppFormGroup(
      children: [
        for (final r in sale.refunds)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
              child: Row(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      r.reference,
                      style: TextStyle(
                        fontSize: 17,
                        color: colors.textPrimary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '−${saleMoney(context, r.total)}',
                                style: TextStyle(color: colors.danger),
                              ),
                              TextSpan(
                                text: '  ${saleTime(r.createdAt)}',
                                style: TextStyle(color: colors.textHint),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Copy glyph used next to the receipt reference.
const IconData kSaleCopyIcon = PhosphorIconsRegular.copy;
