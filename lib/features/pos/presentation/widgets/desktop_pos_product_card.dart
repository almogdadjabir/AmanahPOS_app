import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Compact product tile for the desktop POS grid.
///
/// Follows the desktop card recipe used across the app (surface fill, soft
/// 1px border, rounded corners) with a full-bleed image, a tight info footer
/// and hover feedback. The cart-quantity badge scales its label down instead
/// of growing, so large quantities (x111, x9999) never overflow the tile.
class DesktopPosProductCard extends StatefulWidget {
  final ProductData product;
  final int quantityInCart;
  final bool isRestaurant;
  final VoidCallback onTap;

  const DesktopPosProductCard({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.isRestaurant,
    required this.onTap,
  });

  @override
  State<DesktopPosProductCard> createState() => _DesktopPosProductCardState();
}

class _DesktopPosProductCardState extends State<DesktopPosProductCard> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final product = widget.product;
    final stock = product.stockLevel ?? 0;
    final trackInventory =
        !widget.isRestaurant && (product.trackInventory ?? true);

    final isOut = trackInventory && stock <= 0;
    final isLow = trackInventory && stock > 0 && stock <= 5;
    final inCart = widget.quantityInCart > 0;

    final borderColor = inCart
        ? colors.primary.withValues(alpha: 0.85)
        : _hovered && !isOut
        ? colors.primary.withValues(alpha: 0.45)
        : colors.border.withValues(alpha: 0.75);

    return MouseRegion(
      cursor: isOut ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: isOut ? null : widget.onTap,
        onTapDown: isOut ? null : (_) => _setPressed(true),
        onTapCancel: isOut ? null : () => _setPressed(false),
        onTapUp: isOut ? null : (_) => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(color: borderColor, width: inCart ? 1.4 : 1),
              boxShadow: (_hovered || inCart) && !isOut
                  ? [
                      BoxShadow(
                        color: inCart
                            ? colors.primary.withValues(alpha: 0.10)
                            : colors.shadow.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProductImage(product: product, dimmed: isOut),
                      if (trackInventory && !isOut)
                        PositionedDirectional(
                          top: AppDims.s2,
                          start: AppDims.s2,
                          child: _StockChip(stock: stock, isLow: isLow),
                        ),
                      if (inCart)
                        PositionedDirectional(
                          top: AppDims.s2,
                          end: AppDims.s2,
                          child: _QtyBadge(quantity: widget.quantityInCart),
                        )
                      else if (_hovered && !isOut)
                        PositionedDirectional(
                          top: AppDims.s2,
                          end: AppDims.s2,
                          child: _AddHint(),
                        ),
                      if (isOut) Center(child: _OutChip()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDims.s3,
                    AppDims.s2 + 2,
                    AppDims.s3,
                    AppDims.s3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _productName(product),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs100(context).copyWith(
                          color: isOut ? colors.textHint : colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _formatPrice(product.price),
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.bs200(context).copyWith(
                              color: isOut ? colors.textHint : colors.primary,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _productName(ProductData product) {
    final name = product.name?.trim();
    if (name == null || name.isEmpty) return 'Product';
    return name;
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00';

    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final hasDecimals = parsed % 1 != 0;
    final amount = hasDecimals
        ? parsed.toStringAsFixed(2)
        : parsed.toStringAsFixed(0);

    return amount.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

// ── Image / placeholder ───────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final ProductData product;
  final bool dimmed;

  const _ProductImage({required this.product, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.thumbnailUrl ?? product.image;
    final hasImage = imageUrl?.trim().isNotEmpty == true;

    Widget visual;
    if (hasImage) {
      visual = OfflineCachedImage(imageUrl: imageUrl, fit: BoxFit.cover);
    } else {
      visual = DecoratedBox(
        decoration: BoxDecoration(color: _placeholderColor(product)),
        child: Center(
          child: Text(
            _initials(product.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs500(context).copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: dimmed ? 0.4 : 1,
      child: visual,
    );
  }

  Color _placeholderColor(ProductData product) {
    final seed = product.id ?? product.name ?? product.sku ?? 'product';

    final palette = <Color>[
      const Color(0xFF9F1239),
      const Color(0xFF1E3A8A),
      const Color(0xFF365314),
      const Color(0xFF7C2D12),
      const Color(0xFF581C87),
      const Color(0xFF155E75),
      const Color(0xFF854D0E),
      const Color(0xFF164E63),
    ];

    final hash = seed.codeUnits.fold<int>(0, (prev, e) => prev + e);
    return palette[hash % palette.length];
  }

  String _initials(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return 'POS';

    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.length <= 3
          ? parts.first.toUpperCase()
          : parts.first.substring(0, 3).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Overlays ──────────────────────────────────────────────────────────────────

class _StockChip extends StatelessWidget {
  final double stock;
  final bool isLow;

  const _StockChip({required this.stock, required this.isLow});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isLow ? colors.warning : colors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            _formatStock(stock),
            style: AppTextStyles.sm200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStock(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _QtyBadge extends StatelessWidget {
  final int quantity;

  const _QtyBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 28, maxWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // FittedBox shrinks the label for large quantities instead of letting
      // the pill overflow the tile
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'x$quantity',
          maxLines: 1,
          softWrap: false,
          style: AppTextStyles.sm200(context).copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AddHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.add_rounded, color: colors.onPrimary, size: 15),
    );
  }
}

class _OutChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Out of stock',
        style: AppTextStyles.sm200(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1),
      ),
    );
  }
}
