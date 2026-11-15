import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// Sale is returnable from the Returns entry.
bool saleIsReturnable(SaleHistoryItem sale) => sale.canBeReturned;

/// One grouped-list row: payment tile, receipt number, "time · items ·
/// customer", amount, status pill, chevron.
class SaleRow extends StatelessWidget {
  final SaleHistoryItem sale;
  final bool pickMode;
  final VoidCallback? onTap;

  const SaleRow({
    super.key,
    required this.sale,
    this.pickMode = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    final dim = pickMode && !saleIsReturnable(sale);
    final customer = (sale.customerName?.trim().isNotEmpty ?? false)
        ? sale.customerName!.trim()
        : tr.shWalkIn;
    final time = saleTime(sale.createdAt);

    final String subtitle;
    if (pickMode) {
      if (dim) {
        final notSynced =
            sale.isOfflinePending ||
            sale.status == SaleHistoryStatus.pending ||
            sale.status == SaleHistoryStatus.failed;
        subtitle =
            '$time · ${notSynced ? tr.rtNotSynced : tr.rtAlreadyReturned}';
      } else {
        subtitle = '$time · $customer';
      }
    } else {
      subtitle = '$time · ${tr.shItems(sale.items.length)} · $customer';
    }

    final pill = pickMode ? null : SaleStatusPill.forSale(context, sale);

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            child: Row(
              children: [
                SalePaymentTile(method: sale.paymentMethod, dimmed: dim),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          sale.displayRef,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: text.bodyLarge!
                              .copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              )
                              .tabular,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!.copyWith(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAmount(
                      value: saleNumber(sale.total),
                      unit: tr.shUnit,
                      style: text.bodyLarge!.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: dim ? colors.textSecondary : colors.textPrimary,
                      ),
                    ),
                    if (pill != null) ...[const SizedBox(height: 3), pill],
                  ],
                ),
                if (!dim) ...[
                  const SizedBox(width: AppDims.s2),
                  DirectionalIcon(
                    icon: PhosphorIconsRegular.caretRight,
                    size: 16,
                    color: colors.borderStrong,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Day header + inset grouped card of rows. Hairlines inset past the tile.
class SalesDayGroup extends StatelessWidget {
  final String label;
  final List<SaleHistoryItem> sales;
  final bool pickMode;
  final bool first;
  final ValueChanged<SaleHistoryItem> onTap;
  final List<AppSwipeAction> Function(SaleHistoryItem sale)? swipeActions;

  const SalesDayGroup({
    super.key,
    required this.label,
    required this.sales,
    required this.pickMode,
    required this.onTap,
    this.first = false,
    this.swipeActions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(20, first ? 4 : 22, 20, 7),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textHint),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: AppDims.borderLg,
            child: Column(
              children: [
                for (var i = 0; i < sales.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 68,
                      color: colors.border,
                    ),
                  _wrap(
                    sales[i],
                    SaleRow(
                      key: ValueKey(sales[i].clientSaleId),
                      sale: sales[i],
                      pickMode: pickMode,
                      onTap: (pickMode && !saleIsReturnable(sales[i]))
                          ? null
                          : () => onTap(sales[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _wrap(SaleHistoryItem sale, Widget row) {
    final actions = swipeActions?.call(sale);
    if (actions == null || actions.isEmpty) return row;
    return AppSwipeActions(actions: actions, child: row);
  }
}
