import 'package:amana_pos/features/dashboard/data/models/product.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';

/// Tappable product tile shown in the catalog grid.
class ProductCard extends StatelessWidget {
  final Product product;
  final int qtyInCart;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.qtyInCart,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.rMd),
        side: BorderSide(color: context.appColors.border),
      ),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(product: product, qtyInCart: qtyInCart),
              const SizedBox(height: AppDims.s2),
              Text(
                product.name,
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary, height: 1.25,
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product.sku,
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 10, fontWeight: FontWeight.w600,
                  color: context.appColors.textHint,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'NunitoSans'),
                        children: [
                          TextSpan(
                            text: AppFormat.money(product.price),
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: context.appColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: '  ${AppFormat.currency}',
                            style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w700, color: context.appColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: context.appColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppDims.rXs),
                    ),
                    child: Icon(Icons.add_rounded, size: 16, color: context.appColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Product product;
  final int qtyInCart;
  const _Thumbnail({required this.product, required this.qtyInCart});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDims.rSm),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [context.appColors.surfaceSoft, context.appColors.border],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // initials chip in the middle
            Center(
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppFormat.initials(product.name),
                  style: TextStyle(
                    fontFamily: 'NunitoSans', fontSize: 12, fontWeight: FontWeight.w800,
                    color: context.appColors.textHint,
                  ),
                ),
              ),
            ),
            // cart-qty bubble (top-left)
            if (qtyInCart > 0)
              Positioned(
                left: 6, top: 6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: context.appColors.primary.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '×$qtyInCart',
                    style: const TextStyle(
                      fontFamily: 'NunitoSans', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            // low-stock pill (top-right)
            if (product.isLowStock)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.appColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${product.stock} left',
                    style: const TextStyle(
                      fontFamily: 'NunitoSans', fontSize: 9.5, fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
