import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class NoProductStockCard extends StatelessWidget {
  final VoidCallback onAddStock;

  const NoProductStockCard({super.key,
    required this.onAddStock,
  });

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
            'No stock added yet',
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            'Add stock for this product to start tracking availability by shop.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          FilledButton.icon(
            onPressed: onAddStock,
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
      ),
    );
  }
}