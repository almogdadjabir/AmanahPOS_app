import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class InventoryHeader extends StatelessWidget {
  final List<StockData> stockList;

  const InventoryHeader({super.key,
    required this.stockList,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final total = stockList.length;
    final low = stockList.where((s) => s.isLowStock ?? false).length;
    final out = stockList.where((s) => s.isOutOfStock ?? false).length;
    final healthy = (total - low - out).clamp(0, total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track quantities, low stock alerts, and shop-level stock movements.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
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
                child: inventoryMiniStat(
                  context: context,
                  label: 'Total',
                  value: '$total',
                  icon: Icons.inventory_2_outlined,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: inventoryMiniStat(
                  context: context,
                  label: 'Healthy',
                  value: '$healthy',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: inventoryMiniStat(
                  context: context,
                  label: 'Low',
                  value: '$low',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: inventoryMiniStat(
                  context: context,
                  label: 'Out',
                  value: '$out',
                  icon: Icons.remove_shopping_cart_outlined,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget inventoryMiniStat({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }){
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bs300(context).copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: context.appColors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

  }
}
