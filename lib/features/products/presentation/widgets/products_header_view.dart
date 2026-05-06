import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductsHeaderView extends StatelessWidget {
  final List<ProductData> products;
  final int categoryCount;

  const ProductsHeaderView({super.key,
    required this.products,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final activeCount = products.where((p) => p.isActive == true).length;
    final outOfStockCount =
        products.where((p) => (p.stockLevel ?? 0) <= 0).length;

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
                  Icons.local_offer_rounded,
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
                      'Product Catalog',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage items, prices, categories and stock availability.',
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
                child: productMiniStat(
                  context: context,
                  label: 'Products',
                  value: '${products.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: productMiniStat(
                  context: context,
                  label: 'Active',
                  value: '$activeCount',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: productMiniStat(
                  context: context,
                  label: 'Out',
                  value: '$outOfStockCount',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: productMiniStat(
                  context: context,
                  label: 'Cats',
                  value: '$categoryCount',
                  icon: Icons.layers_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget productMiniStat({
    required BuildContext context,
    required String label,
    required String  value,
    required IconData icon}){
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: context.appColors.primary),
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