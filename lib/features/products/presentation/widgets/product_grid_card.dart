// ════════════════════════════════════════════════════════════════════════════
// lib/features/products/presentation/widgets/product_grid_card.dart
// ════════════════════════════════════════════════════════════════════════════

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductGridCard extends StatelessWidget {
  final ProductData product;

  const ProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colors      = context.appColors;
    final isActive    = product.isActive ?? false;
    final showStock   = !context.read<AuthBloc>().state.permissions.isRestaurant;

    return Material(
      color:        colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          RouteStrings.productDetailScreen,
          arguments: {'product': product},
        ),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OfflineCachedImage(
                        imageUrl: product.thumbnailUrl ?? product.image,
                        fit:      BoxFit.cover,
                      ),
                    ),
                    if (!isActive)
                      const Positioned(
                        top:  AppDims.s2,
                        left: AppDims.s2,
                        child: _InactivePill(),
                      ),
                  ],
                ),
              ),

              // ── Info ───────────────────────────────────────────────────
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
                        color:      colors.textPrimary,
                        height:     1.15,
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
                        color:      colors.textHint,
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
                              color:      colors.primary,
                            ),
                          ),
                        ),
                        if (showStock)
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
  const _InactivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical:   4,
      ),
      decoration: BoxDecoration(
        color:        Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color:      Colors.white,
        ),
      ),
    );
  }
}