import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductGridCard extends StatelessWidget {
  final ProductData product;
  const ProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isActive = product.isActive ?? false;

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () {}, // TODO: product detail
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDims.rMd)),
                child: SizedBox(
                  width: double.infinity,
                  child: product.image != null
                      ? Image.network(product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          PlaceholderImage())
                      : PlaceholderImage(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppDims.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDims.s1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${product.price ?? '0.00'}',
                          style: AppTextStyles.bs300(context).copyWith(
                          fontWeight: FontWeight.w800,
                            color: context.appColors.primary,
                          ),
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.appColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Off',
                            style: AppTextStyles.bs300(context).copyWith(
                            fontWeight: FontWeight.w800,
                              color: context.appColors.textHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  StockChip(level: product.stockLevel ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
