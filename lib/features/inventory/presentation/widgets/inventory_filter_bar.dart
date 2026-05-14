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
      buildWhen: (prev, curr) {
        return prev.stockList != curr.stockList || prev.filter != curr.filter;
      },
      builder: (context, state) {
        final total = state.stockList.length;
        final low = state.stockList.where((s) => s.isLowStock ?? false).length;
        final out = state.stockList.where((s) => s.isOutOfStock ?? false).length;

        return Row(
          children: [
            _SummaryChip(
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
            _SummaryChip(
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
            _SummaryChip(
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
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              vertical: AppDims.s2,
              horizontal: AppDims.s2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.11)
                  : colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.90)
                    : colors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count.toString(),
                    style: AppTextStyles.bs500(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: isSelected ? color : colors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.bs300(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: isSelected ? color : colors.textSecondary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}