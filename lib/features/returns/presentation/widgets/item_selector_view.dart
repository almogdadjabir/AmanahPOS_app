import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/returns/presentation/widgets/return_item_tile.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ItemSelectorView extends StatelessWidget {
  final ReturnsState state;
  const ItemSelectorView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _ItemSelectorContent(
          state: state,
          compact: constraints.maxWidth < 440,
        );
      },
    );
  }
}

class _ItemSelectorContent extends StatelessWidget {
  const _ItemSelectorContent({
    required this.state,
    required this.compact,
  });

  final ReturnsState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sale = state.selectedSale!;
    final isLoading = state.submitStatus == ReturnsSubmitStatus.loading;
    final selectedCount = state.selectedItems.values.fold(0, (a, b) => a + b);
    final totalItems = sale.items.fold(0, (a, b) => a + b.quantity.toInt());

    final hPad = compact ? AppDims.s3 : AppDims.s4;
    final bodyStyle = compact ? AppTextStyles.sm200(context) : AppTextStyles.bs100(context);
    final captionStyle = compact ? AppTextStyles.sm100(context) : AppTextStyles.sm200(context);

    return Column(
      children: [
        Divider(height: 1, color: colors.border),

        // ── Sale header ──────────────────────────────────────────────
        Container(
          color: AppColors.dangerLight,
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: compact ? 6 : 8,
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.saleSquare,
                size: compact ? 15 : 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr.originalSale,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Text(
                '${sale.items.length} · ${AppFormat.moneyWithUnit(sale.total)}',
                overflow: TextOverflow.ellipsis,
                style: bodyStyle.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        // ── Selection progress bar ──────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, compact ? 6 : AppDims.s2, hPad, compact ? 6 : AppDims.s2),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  state.hasSelection
                      ? context.tr.itemsSelected(selectedCount, totalItems)
                      : context.tr.tapItemsToSelect,
                  overflow: TextOverflow.ellipsis,
                  style: captionStyle.copyWith(color: colors.textSecondary),
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalItems > 0 ? selectedCount / totalItems : 0.0,
                    minHeight: compact ? 3 : 4,
                    backgroundColor: colors.surfaceSoft,
                    color: AppColors.danger,
                  ),
                ),
              ),
              if (state.hasSelection) ...[
                const SizedBox(width: AppDims.s3),
                Text(
                  AppFormat.moneyWithUnit(state.refundTotal),
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),

        Divider(height: 1, color: colors.border),

        // ── Items list ──────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: compact ? AppDims.s2 : AppDims.s3,
            ),
            itemCount: sale.items.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: compact ? AppDims.s1 + 2 : AppDims.s2),
            itemBuilder: (context, index) {
              final item = sale.items[index];
              final isSelected =
                  state.selectedItems.containsKey(item.productId);
              final returnQty =
                  state.selectedItems[item.productId] ?? item.quantity.toInt();

              return RepaintBoundary(
                child: ReturnItemTile(
                  item: item,
                  isSelected: isSelected,
                  returnQty: returnQty,
                  compact: compact,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    context
                        .read<ReturnsBloc>()
                        .add(ReturnsItemToggled(item.productId));
                  },
                  onQtyChanged: (qty) => context
                      .read<ReturnsBloc>()
                      .add(ReturnsQuantityChanged(item.productId, qty)),
                ),
              );
            },
          ),
        ),

        // ── Error banner ────────────────────────────────────────────
        if (state.errorMessage != null)
          Container(
            margin: EdgeInsets.fromLTRB(hPad, 0, hPad, AppDims.s2),
            padding: const EdgeInsets.all(AppDims.s3),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(SolarIconsOutline.dangerTriangle,
                    size: compact ? 13 : 16, color: AppColors.danger),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: captionStyle.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),

        // ── Bottom action bar ───────────────────────────────────────
        Container(
          padding: EdgeInsets.all(hPad),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.hasSelection) ...[
                  Container(
                    margin: EdgeInsets.only(
                        bottom: compact ? AppDims.s2 : AppDims.s3),
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: compact ? 7 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(SolarIconsOutline.undoLeft,
                            size: compact ? 13 : 15, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Text(
                          context.tr.refundTotal,
                          style: bodyStyle.copyWith(color: AppColors.danger),
                        ),
                        const Spacer(),
                        Text(
                          AppFormat.moneyWithUnit(state.refundTotal),
                          style: (compact
                                  ? AppTextStyles.bs100(context)
                                  : AppTextStyles.bs200(context))
                              .copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: compact ? 46 : 56,
                  child: FilledButton(
                    onPressed: (!state.hasSelection || isLoading)
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            context
                                .read<ReturnsBloc>()
                                .add(const ReturnsSubmitted());
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      disabledBackgroundColor: colors.border,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(compact ? 14 : 20),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: compact ? 18 : 22,
                            height: compact ? 18 : 22,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : state.hasSelection
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr.processReturn,
                                    style: bodyStyle.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${state.selectedItems.values.fold<int>(0, (a, b) => a + b)} ${context.tr.items}',
                                      style: captionStyle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                context.tr.selectItemsToReturn,
                                style: bodyStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
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
