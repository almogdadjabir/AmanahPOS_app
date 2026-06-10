import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Grid tile for the desktop products view. A taller, hover-aware sibling
/// of [ProductGridCard] — keeps the product image but adds a dedicated
/// "Manage" affordance suited to mouse interaction, mirroring
/// `DesktopStockCard` from the inventory desktop layout.
class DesktopProductCard extends StatefulWidget {
  final ProductData product;
  final bool showStock;
  final void Function(ProductData)? onProductTap;

  const DesktopProductCard({
    super.key,
    required this.product,
    required this.showStock,
    this.onProductTap,
  });

  @override
  State<DesktopProductCard> createState() => _DesktopProductCardState();
}

class _DesktopProductCardState extends State<DesktopProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final product = widget.product;

    final isActive = product.isActive ?? false;
    final productName = product.name?.trim();
    final categoryName = product.categoryName?.trim();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDims.rXl),
          onTap: () {
            if (widget.onProductTap != null) {
              widget.onProductTap!(product);
            } else {
              Navigator.of(context).pushNamed(
                RouteStrings.productDetailScreen,
                arguments: {'product': product},
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(
                color: _hovered
                    ? colors.primary.withValues(alpha: 0.35)
                    : colors.border,
                width: _hovered ? 1.3 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDims.rXl - 1),
                        ),
                        child: ColoredBox(
                          color: colors.surfaceSoft,
                          child: OfflineCachedImage(
                            imageUrl: product.thumbnailUrl ?? product.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (!isActive)
                        PositionedDirectional(
                          top: AppDims.s2,
                          start: AppDims.s2,
                          child: _Pill(
                            label: tr.inactive,
                            background: Colors.black.withValues(alpha: 0.55),
                            color: Colors.white,
                          ),
                        ),
                      if (widget.showStock)
                        PositionedDirectional(
                          top: AppDims.s2,
                          end: AppDims.s2,
                          child: StockChip(level: product.stockLevel ?? 0),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDims.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName?.isNotEmpty == true
                                  ? productName!
                                  : tr.product,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs300(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  SolarIconsOutline.tag,
                                  size: 12,
                                  color: colors.textHint,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    categoryName?.isNotEmpty == true
                                        ? categoryName!
                                        : tr.noCategory,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.sm300(context)
                                        .copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _formatPrice(product.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bs500(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  height: 1,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _hovered
                                    ? colors.primary.withValues(alpha: 0.12)
                                    : colors.surfaceSoft,
                                borderRadius:
                                    BorderRadius.circular(AppDims.rMd),
                                border: Border.all(
                                  color: _hovered
                                      ? colors.primary.withValues(alpha: 0.30)
                                      : colors.border,
                                ),
                              ),
                              child: Icon(
                                SolarIconsOutline.settings,
                                size: 15,
                                color: _hovered
                                    ? colors.primary
                                    : colors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;

  const _Pill({
    required this.label,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s2,
          vertical: 4,
        ),
        child: Text(
          label,
          style: AppTextStyles.sm100(context).copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}
