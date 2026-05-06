import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductDetailAppBarView extends StatelessWidget {
  final ProductData product;

  const ProductDetailAppBarView({super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = product.detailImageUrl;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: colors.textPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl == null
                ? const PlaceholderImage()
                : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const PlaceholderImage(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppDims.s4,
              right: AppDims.s4,
              bottom: AppDims.s4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isActive == false)
                    Container(
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
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppDims.s2),
                  Text(
                    product.name ?? 'Product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.lg100(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categoryName?.trim().isNotEmpty == true
                        ? product.categoryName!.trim()
                        : 'No category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs300(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete product coming soon')),
    );
  }
}