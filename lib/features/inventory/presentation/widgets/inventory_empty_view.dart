import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class InventoryEmptyView extends StatelessWidget {
  final StockFilter filter;

  const InventoryEmptyView({super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = switch (filter) {
      StockFilter.all => 'No stock entries yet',
      StockFilter.lowStock => 'No low stock items',
      StockFilter.outOfStock => 'No out of stock items',
    };

    final message = switch (filter) {
      StockFilter.all =>
      'Add stock for your products to start tracking inventory.',
      StockFilter.lowStock =>
      'Everything looks good. No products are currently low on stock.',
      StockFilter.outOfStock =>
      'Great. No products are currently out of stock.',
    };

    final icon = switch (filter) {
      StockFilter.all => Icons.inventory_2_outlined,
      StockFilter.lowStock => Icons.check_circle_outline_rounded,
      StockFilter.outOfStock => Icons.check_circle_outline_rounded,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (filter == StockFilter.all) ...[
              const SizedBox(height: AppDims.s4),
              FilledButton.icon(
                onPressed: () => showAddStockProductSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Stock'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
