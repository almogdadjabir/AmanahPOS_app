import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_extensions.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';

// Column flex weights — shared by header and rows so they stay aligned.
const _kDateFlex = 2;
const _kReceiptFlex = 2;
const _kCustomerFlex = 3;
const _kItemsFlex = 1;
const _kPaymentFlex = 2;
const _kTotalFlex = 2;
const _kStatusFlex = 2;

// Padding constants
const _kHeaderVerticalPad = AppDims.s2 + 2.0;
const _kPillVerticalPad = 4.0;
const _kPillIconGap = 4.0;

/// Sliver widget: a decorated card (rounded border) containing the table header
/// + a [SliverList] of sale rows, wrapped in [SliverMainAxisGroup]/[DecoratedSliver].
class DesktopSalesTable extends StatelessWidget {
  const DesktopSalesTable({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<SaleHistoryItem> items;
  final ValueChanged<SaleHistoryItem> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: const _DesktopSalesTableHeader(),
          ),
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _DesktopSalesTableRow(
                item: item,
                onTap: () => onTap(item),
              )
                  .mAnimate(delay: (index % 20 * 15).ms)
                  .fadeIn(duration: 200.ms);
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopSalesTableHeader extends StatelessWidget {
  const _DesktopSalesTableHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String h(String s) => isAr ? s : s.toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: _kHeaderVerticalPad,
        ),
        child: Row(
          children: [
            Expanded(flex: _kDateFlex, child: _HeaderCell(h(context.tr.date))),
            Expanded(flex: _kReceiptFlex, child: _HeaderCell(h(context.tr.receipt))),
            Expanded(flex: _kCustomerFlex, child: _HeaderCell(h(context.tr.customer))),
            Expanded(flex: _kItemsFlex, child: _HeaderCell(h(context.tr.items))),
            Expanded(flex: _kPaymentFlex, child: _HeaderCell(h(context.tr.payment))),
            Expanded(flex: _kTotalFlex, child: _HeaderCell(h(context.tr.total))),
            Expanded(flex: _kStatusFlex, child: _HeaderCell(h(context.tr.status))),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.sm100(context).copyWith(
        color: context.appColors.textHint,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: Localizations.localeOf(context).languageCode == 'ar' ? 0 : 0.5,
      ),
    );
  }
}

class _DesktopSalesTableRow extends StatelessWidget {
  const _DesktopSalesTableRow({
    required this.item,
    required this.onTap,
  });

  final SaleHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4,
            vertical: AppDims.s3,
          ),
          child: Row(
            children: [
              Expanded(
                flex: _kDateFlex,
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    item.dateTimeLabel,
                    style: AppTextStyles.sm200(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
              Expanded(
                flex: _kReceiptFlex,
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    item.displayRef,
                    style: AppTextStyles.sm200(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: _kCustomerFlex,
                child: Text(
                  item.customerName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm200(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Expanded(
                flex: _kItemsFlex,
                child: Text(
                  item.itemCount.toString(),
                  style: AppTextStyles.sm200(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Expanded(
                flex: _kPaymentFlex,
                child: Text(
                  item.paymentLabel,
                  style: AppTextStyles.sm200(context)
                      .copyWith(color: item.paymentColor),
                ),
              ),
              Expanded(
                flex: _kTotalFlex,
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    AppFormat.moneyWithUnit(item.total),
                    style: AppTextStyles.sm200(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: _kStatusFlex,
                child: _StatusPill(item: item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.item});
  final SaleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s2,
          vertical: _kPillVerticalPad,
        ),
        decoration: BoxDecoration(
          color: item.displayStatusBg,
          borderRadius: BorderRadius.circular(AppDims.rSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.displayStatusIcon, size: 12, color: item.displayStatusFg),
            const SizedBox(width: _kPillIconGap),
            Text(
              _statusLabel(context, item),
              style: AppTextStyles.sm100(context).copyWith(
                color: item.displayStatusFg,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(BuildContext context, SaleHistoryItem item) {
  if (item.isOfflinePending) return context.tr.pending;
  return switch (item.status) {
    SaleHistoryStatus.completed => context.tr.completed,
    SaleHistoryStatus.refunded => context.tr.returned,
    SaleHistoryStatus.partialRefund => context.tr.partiallyReturned,
    SaleHistoryStatus.cancelled => context.tr.cancelled,
    SaleHistoryStatus.pending => context.tr.pending,
    SaleHistoryStatus.failed => context.tr.failed,
    SaleHistoryStatus.unknown => context.tr.unknown,
  };
}
