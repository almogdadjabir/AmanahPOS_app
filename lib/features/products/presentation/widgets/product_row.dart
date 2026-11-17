import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/features/sync/presentation/widgets/catalog_sync_pill.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

void openProductDetail(BuildContext context, ProductData product) {
  Navigator.of(context).pushNamed(
    RouteStrings.productDetailScreen,
    arguments: {'product': product},
  );
}

/// Square thumbnail with the first letter as the fallback.
class ProductThumb extends StatelessWidget {
  final ProductData product;
  final double size;
  final double radius;

  const ProductThumb({
    super.key,
    required this.product,
    this.size = 44,
    this.radius = 11,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = product.listImageUrl;
    final id = product.id;
    final name = product.name?.trim() ?? '';
    final letter = Center(
      child: Text(
        name.isEmpty ? '·' : name.characters.first,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: colors.surfaceSoft,
          // A staged (not yet uploaded) image shows first (Task 6).
          child: url != null || (id != null && id.isNotEmpty)
              ? OfflineCachedImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  entityType: 'product',
                  entityId: id,
                  errorWidget: url == null ? letter : null,
                )
              : letter,
        ),
      ),
    );
  }
}

/// One grouped-list row: thumbnail, name, subtitle, price, chevron.
class ProductRow extends StatelessWidget {
  final ProductData product;
  final bool isRestaurant;
  final bool showCategory;
  final VoidCallback? onTap;

  /// "Not synced" / "Sync failed" pill after the name.
  final CatalogSyncMark syncMark;

  const ProductRow({
    super.key,
    required this.product,
    required this.isRestaurant,
    this.showCategory = true,
    this.onTap,
    this.syncMark = CatalogSyncMark.synced,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    final isActive = product.isActive != false;
    final level = productStockLevel(product, isRestaurant: isRestaurant);
    final stockText = isActive
        ? productStockText(context, product, level)
        : null;
    final category = product.categoryName?.trim();
    final name = productDisplayName(context, product);

    final parts = <String>[
      if (showCategory && category != null && category.isNotEmpty) category,
      ?stockText,
    ];
    final subtitle = parts.join(' · ');
    final subtitleColor = productStockColor(context, level);
    final stockHighlight =
        isActive &&
        (level == ProductStockLevel.low || level == ProductStockLevel.out);

    return Pressable(
      onTap: onTap ?? () => openProductDetail(context, product),
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            child: Row(
              children: [
                ProductThumb(product: product),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: name.contentDirection,
                              style: text.bodyLarge!.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  tr.inactive,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (syncMark != CatalogSyncMark.synced) ...[
                            const SizedBox(width: 6),
                            CatalogSyncPill(mark: syncMark),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(
                              fontSize: 13,
                              fontWeight: stockHighlight
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: stockHighlight
                                  ? subtitleColor
                                  : colors.textHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Text(
                  formatPrice(product.price),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                  style: text.bodyLarge!
                      .copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      )
                      .tabular,
                ),
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inset grouped card of [ProductRow]s with hairlines inset past the
/// thumbnail. Optional swipe actions per row.
class ProductListGroup extends StatelessWidget {
  final List<ProductData> products;
  final bool isRestaurant;
  final bool showCategory;
  final List<AppSwipeAction> Function(ProductData product)? swipeActions;
  final CatalogSyncMarks syncMarks;

  const ProductListGroup({
    super.key,
    required this.products,
    required this.isRestaurant,
    this.showCategory = true,
    this.swipeActions,
    this.syncMarks = CatalogSyncMarks.none,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < products.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 44 + AppDims.s3,
                  color: colors.border,
                ),
              _wrap(
                products[i],
                ProductRow(
                  key: ValueKey(products[i].id ?? i),
                  product: products[i],
                  isRestaurant: isRestaurant,
                  showCategory: showCategory,
                  syncMark: syncMarks.markOf(products[i].id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _wrap(ProductData product, Widget row) {
    final actions = swipeActions?.call(product);
    if (actions == null || actions.isEmpty) return row;
    return AppSwipeActions(actions: actions, child: row);
  }
}

/// Grid tile for the grid layout.
class ProductGridTile extends StatelessWidget {
  final ProductData product;
  final bool isRestaurant;

  /// "Not synced" / "Sync failed" pill over the image.
  final CatalogSyncMark syncMark;

  const ProductGridTile({
    super.key,
    required this.product,
    required this.isRestaurant,
    this.syncMark = CatalogSyncMark.synced,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isActive = product.isActive != false;
    final level = productStockLevel(product, isRestaurant: isRestaurant);
    final stockText = isActive
        ? productStockText(context, product, level)
        : tr.inactive;
    final highlight =
        isActive &&
        (level == ProductStockLevel.low || level == ProductStockLevel.out);
    final name = productDisplayName(context, product);

    return Pressable(
      onTap: () => openProductDetail(context, product),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: isDark ? Border.all(color: colors.border) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: isActive ? 1 : 0.55,
                        child: LayoutBuilder(
                          builder: (context, c) => ProductThumb(
                            product: product,
                            size: c.maxWidth,
                            radius: 12,
                          ),
                        ),
                      ),
                    ),
                    if (syncMark != CatalogSyncMark.synced)
                      PositionedDirectional(
                        top: 6,
                        start: 6,
                        child: CatalogSyncPill(mark: syncMark),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: name.contentDirection,
                style: text.bodyMedium!.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              if (stockText != null)
                Text(
                  stockText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall!.copyWith(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.w500 : FontWeight.w400,
                    color: highlight
                        ? productStockColor(context, level)
                        : colors.textHint,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                formatPrice(product.price),
                textDirection: TextDirection.ltr,
                style: text.bodyLarge!
                    .copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    )
                    .tabular,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
