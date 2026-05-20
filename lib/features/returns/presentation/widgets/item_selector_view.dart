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
    final colors = context.appColors;
    final sale = state.selectedSale!;
    final isLoading = state.submitStatus == ReturnsSubmitStatus.loading;
    final selectedCount = state.selectedItems.values.fold(0, (a, b) => a + b);
    final totalItems = sale.items.fold(0, (a, b) => a + b.quantity.toInt());

    return Column(
      children: [
        Divider(height: 1, color: colors.border),

        Container(
          color: AppColors.dangerLight,
          padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4, vertical: 8),
          child: Row(
            children: [
              Icon(SolarIconsOutline.sale,
                  size: 24, color: AppColors.danger),
              const SizedBox(width: 6),
              Text(
                'Original sale',
                style: AppTextStyles.bs300(context)
                    .copyWith(color: AppColors.danger),
              ),
              const Spacer(),
              Text(
                '${sale.items.length} item${sale.items.length == 1 ? '' : 's'}'
                    ' · ${AppFormat.moneyWithUnit(sale.total)}',
                style: AppTextStyles.bs300(context).copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDims.s4, AppDims.s2, AppDims.s4, AppDims.s2),
          child: Row(
            children: [
              Text(
                state.hasSelection
                    ? '$selectedCount of $totalItems selected'
                    : 'Tap items to select',
                style: AppTextStyles.bs300(context)
                    .copyWith(color: colors.textSecondary),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalItems > 0
                        ? selectedCount / totalItems
                        : 0.0,
                    minHeight: 4,
                    backgroundColor: colors.surfaceSoft,
                    color: AppColors.danger,
                  ),
                ),
              ),
              if (state.hasSelection) ...[
                const SizedBox(width: AppDims.s3),
                Text(
                  AppFormat.moneyWithUnit(state.refundTotal),
                  style: AppTextStyles.bs300(context).copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),

        Divider(height: 1, color: colors.border),

        // ── Items list ────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: AppDims.s3),
            itemCount: sale.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDims.s2),
            itemBuilder: (context, index) {
              final item = sale.items[index];
              final isSelected =
              state.selectedItems.containsKey(item.productId);
              final returnQty =
                  state.selectedItems[item.productId] ?? item.quantity.toInt();

              return ReturnItemTile(
                item: item,
                isSelected: isSelected,
                returnQty: returnQty,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  context
                      .read<ReturnsBloc>()
                      .add(ReturnsItemToggled(item.productId));
                },
                onQtyChanged: (qty) => context
                    .read<ReturnsBloc>()
                    .add(ReturnsQuantityChanged(item.productId, qty)),
              );
            },
          ),
        ),

        // ── Error banner ──────────────────────────────────────────────────
        if (state.errorMessage != null)
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppDims.s4, 0, AppDims.s4, AppDims.s2),
            padding: const EdgeInsets.all(AppDims.s3),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 16, color: AppColors.danger),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: AppTextStyles.bs100(context)
                        .copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),

        // ── Bottom action bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDims.s4),
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
                    margin: const EdgeInsets.only(bottom: AppDims.s3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s4, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(SolarIconsOutline.undoLeft,
                            size: 15, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Text(
                          'Refund total',
                          style: AppTextStyles.bs200(context)
                              .copyWith(color: AppColors.danger),
                        ),
                        const Spacer(),
                        Text(
                          AppFormat.moneyWithUnit(state.refundTotal),
                          style: AppTextStyles.bs300(context).copyWith(
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
                  height: 56,
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                        : state.hasSelection
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Process return',
                          style:
                          AppTextStyles.bs400(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$selectedCount item${selectedCount == 1 ? '' : 's'}',
                            style:
                            AppTextStyles.bs300(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Select items to return',
                      style: AppTextStyles.bs400(context).copyWith(
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