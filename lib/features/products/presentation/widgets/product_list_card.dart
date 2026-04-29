import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';



class ProductListCard extends StatelessWidget {
  final ProductData product;
  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isActive = product.isActive ?? false;

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () {}, // TODO: product detail
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDims.rSm),
                child: SizedBox(
                  width: 60, height: 60,
                  child: product.image != null
                      ? Image.network(product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => PlaceholderImage())
                      : PlaceholderImage(),
                ),
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (product.categoryName != null)
                      Text(
                        product.categoryName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w600,
                          color: context.appColors.textHint,
                        ),
                      ),
                    const SizedBox(height: 3),
                    StockChip(level: product.stockLevel ?? 0),
                  ],
                ),
              ),

              // ── Price + status ────────────────────────────────────────
              const SizedBox(width: AppDims.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.price ?? '0.00'}',
                    style: AppTextStyles.bs400(context).copyWith(
                    fontWeight: FontWeight.w800,
                      color: context.appColors.primary,
                    ),
                  ),
                  if (!isActive)
                    Text(
                      'Inactive',
                      style: AppTextStyles.bs100(context).copyWith(
                      fontWeight: FontWeight.w700,
                        color: context.appColors.textHint,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppDims.s1),
              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
