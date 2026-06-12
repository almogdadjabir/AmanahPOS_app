import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/widgets/directional_icon.dart'; // update path if needed
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductListCard extends StatelessWidget {
  final ProductData product;

  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final showStock = context.select<AuthBloc, bool>(
      (bloc) => !bloc.state.permissions.isRestaurant,
    );

    return _ProductListCardContent(product: product, showStock: showStock);
  }
}

class _ProductListCardContent extends StatelessWidget {
  final ProductData product;
  final bool showStock;

  const _ProductListCardContent({
    required this.product,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final isActive = product.isActive ?? false;
    final productName = product.name?.trim();
    final displayName = productName?.isNotEmpty == true
        ? productName!
        : tr.product;
    final categoryName = product.categoryName?.trim();

    return RepaintBoundary(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              RouteStrings.productDetailScreen,
              arguments: {'product': product},
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDims.s3),
              child: Row(
                children: [
                  _ProductImage(product: product, size: 66),

                  const SizedBox(width: AppDims.s3),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full width so a single-line RTL name aligns to the
                        // right instead of shrink-wrapping at the left edge.
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: displayName.contentDirection,
                            style: AppTextStyles.bs500(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          categoryName?.isNotEmpty == true
                              ? categoryName!
                              : tr.noCategory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs200(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),

                        if (showStock || !isActive) ...[
                          const SizedBox(height: AppDims.s2),
                          Wrap(
                            spacing: AppDims.s2,
                            runSpacing: AppDims.s1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (showStock)
                                StockChip(level: product.stockLevel ?? 0),
                              if (!isActive) const _InactiveBadge(),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDims.s2),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatPrice(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs500(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),

                      const SizedBox(height: AppDims.s3),

                      DirectionalIcon(
                        icon: SolarIconsOutline.altArrowRight,
                        color: colors.textHint,
                        size: 20,
                      ),
                    ],
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

    if (value is num) {
      return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    }

    return value.toString();
  }
}

class _ProductImage extends StatelessWidget {
  final ProductData product;
  final double size;

  const _ProductImage({required this.product, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: ColoredBox(
        color: colors.surfaceSoft,
        child: SizedBox(
          width: size,
          height: size,
          child: OfflineCachedImage(
            imageUrl: product.thumbnailUrl ?? product.image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s2,
          vertical: 4,
        ),
        child: Text(
          context.tr.inactive,
          style: AppTextStyles.bs100(
            context,
          ).copyWith(fontWeight: FontWeight.w900, color: colors.textHint),
        ),
      ),
    );
  }
}
