import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (prev, curr) =>
      prev.stockList != curr.stockList || prev.filter != curr.filter,
      builder: (context, state) {
        final total = state.stockList.length;
        final low = state.stockList.where((s) => s.isLowStock ?? false).length;
        final out =
            state.stockList.where((s) => s.isOutOfStock ?? false).length;

        return Row(
          children: [
            summaryChip(
              context: context,
              label: 'All',
              count: total,
              color: context.appColors.primary,
              isSelected: state.filter == StockFilter.all,
              onTap: () {
                context.read<InventoryBloc>().add(
                  const OnInventoryFilterChanged(
                    filter: StockFilter.all,
                  ),
                );
              },
            ),
            const SizedBox(width: AppDims.s2),
            summaryChip(
              context: context,
              label: 'Low',
              count: low,
              color: const Color(0xFFEA580C),
              isSelected: state.filter == StockFilter.lowStock,
              onTap: () {
                context.read<InventoryBloc>().add(
                  const OnInventoryFilterChanged(
                    filter: StockFilter.lowStock,
                  ),
                );
              },
            ),
            const SizedBox(width: AppDims.s2),
            summaryChip(
              context: context,
              label: 'Out',
              count: out,
              color: const Color(0xFFDC2626),
              isSelected: state.filter == StockFilter.outOfStock,
              onTap: () {
                context.read<InventoryBloc>().add(
                  const OnInventoryFilterChanged(
                    filter: StockFilter.outOfStock,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  Widget summaryChip({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
}){
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: AppDims.s2,
            horizontal: AppDims.s2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.10) : colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : colors.border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.bs200(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}