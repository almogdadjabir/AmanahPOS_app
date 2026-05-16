import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class InventoryHeader extends StatelessWidget {
  final List<StockData> stockList;
  final StockFilter selectedFilter;
  final ValueChanged<StockFilter> onFilterChanged;

  const InventoryHeader({
    super.key,
    required this.stockList,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final total = stockList.length;

    final low = stockList.where((s) {
      return s.isLowStock ?? false;
    }).length;

    final out = stockList.where((s) {
      return s.isOutOfStock ?? false;
    }).length;

    final healthy = stockList.where((s) {
      final isLow = s.isLowStock ?? false;
      final isOut = s.isOutOfStock ?? false;
      return !isLow && !isOut;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  SolarIconsOutline.box,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Control',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track quantities, low stock alerts, and shop-level stock movements.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s4),
          Row(
            children: [
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Total',
                  value: '$total',
                  icon: SolarIconsOutline.boxMinimalistic,
                  color: colors.primary,
                  isSelected: selectedFilter == StockFilter.all,
                  onTap: () => onFilterChanged(StockFilter.all),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Healthy',
                  value: '$healthy',
                  icon: SolarIconsOutline.checkCircle,
                  color: const Color(0xFF16A34A),
                  isSelected: selectedFilter == StockFilter.healthy,
                  onTap: () => onFilterChanged(StockFilter.healthy),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Low',
                  value: '$low',
                  icon: SolarIconsOutline.dangerTriangle,
                  color: const Color(0xFFEA580C),
                  isSelected: selectedFilter == StockFilter.lowStock,
                  onTap: () => onFilterChanged(StockFilter.lowStock),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Out',
                  value: '$out',
                  icon: SolarIconsOutline.bagCross,
                  color: const Color(0xFFDC2626),
                  isSelected: selectedFilter == StockFilter.outOfStock,
                  onTap: () => onFilterChanged(StockFilter.outOfStock),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _InventoryMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s2,
            vertical: AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              width: isSelected ? 1.4 : 1,
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: isSelected ? color : colors.textSecondary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}