import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class PosProductCard extends StatelessWidget {
  final ProductData product;
  final int quantityInCart;
  final VoidCallback onTap;

  const PosProductCard({super.key,
    required this.product,
    required this.quantityInCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final stock = product.stockLevel ?? 0;
    final trackInventory = product.trackInventory ?? true;
    final isOut = trackInventory && stock <= 0;
    final isLow = trackInventory && stock > 0 && stock <= 5;

    return RepaintBoundary(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: InkWell(
          onTap: isOut ? null : onTap,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isOut ? 0.55 : 1,
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

                        Positioned(
                          top: AppDims.s2,
                          right: AppDims.s2,
                          child: stockPill(
                            context: context,
                            stock: stock,
                            isOut: isOut,
                            isLow: isLow,
                            trackInventory: trackInventory,
                          ),
                        ),

                        if (quantityInCart > 0)
                          Positioned(
                            top: AppDims.s2,
                            left: AppDims.s2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDims.s2,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '×$quantityInCart',
                                style: AppTextStyles.bs100(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
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
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.categoryName?.trim().isNotEmpty == true
                              ? product.categoryName!.trim()
                              : product.sku?.trim().isNotEmpty == true
                              ? product.sku!.trim()
                              : 'No category',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs100(context).copyWith(
                            color: colors.textHint,
                            fontWeight: FontWeight.w700,
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
                                style: AppTextStyles.bs400(context).copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isOut
                                    ? colors.surfaceSoft
                                    : colors.primaryContainer,
                                borderRadius: BorderRadius.circular(AppDims.rSm),
                              ),
                              child: Icon(
                                isOut ? Icons.block_rounded : Icons.add_rounded,
                                size: 18,
                                color: isOut ? colors.textHint : colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00';
    return value.toString();
  }

  Widget stockPill({
    required BuildContext context,
    required double stock,
    required bool isOut,
    required bool isLow,
    required bool trackInventory,}){
    if (!trackInventory) return const SizedBox.shrink();

    final Color color = isOut
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final String label = isOut
        ? 'Out'
        : isLow
        ? '${_format(stock)} left'
        : 'Stock ${_format(stock)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  String _format(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

