import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductGridCard extends StatelessWidget {
  final ProductData product;

  const ProductGridCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = product.isActive ?? false;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            RouteStrings.productDetailScreen,
            arguments: {'product': product},
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: product.image?.trim().isNotEmpty == true
                          ? Image.network(
                        product.image!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const PlaceholderImage(),
                      )
                          : const PlaceholderImage(),
                    ),

                    if (!isActive)
                      Positioned(
                        top: AppDims.s2,
                        left: AppDims.s2,
                        child: _InactivePill(),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppDims.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppDims.s1),
                    Text(
                      product.categoryName?.trim().isNotEmpty == true
                          ? product.categoryName!.trim()
                          : 'No category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textHint,
                      ),
                    ),
                    const SizedBox(height: AppDims.s2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs300(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        StockChip(level: product.stockLevel ?? 0),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00';
    return '$value';
  }
}

class _InactivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}