import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductListCard extends StatelessWidget {
  final ProductData product;

  const ProductListCard({
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
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _ProductImage(
                product: product,
                size: 66,
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.categoryName?.trim().isNotEmpty == true
                          ? product.categoryName!.trim()
                          : 'No category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDims.s2),
                    Row(
                      children: [
                        StockChip(level: product.stockLevel ?? 0),
                        if (!isActive) ...[
                          const SizedBox(width: AppDims.s2),
                          _InactiveBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s2),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(product.price),
                    style: AppTextStyles.bs500(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDims.s3),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textHint,
                    size: 20,
                  ),
                ],
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

class _ProductImage extends StatelessWidget {
  final ProductData? product;
  final double size;

  const _ProductImage({
    required this.product,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: Container(
        width: size,
        height: size,
        color: colors.surfaceSoft,
        child: Builder(
          builder: (_) {
            final imageUrl = product?.listImageUrl;

            if (imageUrl == null) {
              return const PlaceholderImage();
            }

            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const PlaceholderImage(),
            );
          },
        ),
      ),
    );
  }
}

class _InactiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: context.appColors.textHint,
        ),
      ),
    );
  }
}