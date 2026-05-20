// lib/features/products/presentation/widgets/product_details/no_product_stock_card.dart

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class NoProductStockCard extends StatelessWidget {
  // onAddStock is kept in the signature so the single caller
  // (ProductStockSectionView) doesn't need changing.
  final VoidCallback onAddStock;

  const NoProductStockCard({super.key, required this.onAddStock});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: colors.textHint,
            size: 38,
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            'No stock recorded',
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            'Go to the Inventory screen to add and manage stock for this product.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}