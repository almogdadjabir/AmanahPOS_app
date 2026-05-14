import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class PosProductCard extends StatefulWidget {
  final ProductData product;
  final int quantityInCart;
  final bool isRestaurant;
  final VoidCallback onTap;

  const PosProductCard({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.isRestaurant,
    required this.onTap,
  });

  @override
  State<PosProductCard> createState() => _PosProductCardState();
}

class _PosProductCardState extends State<PosProductCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final product = widget.product;
    final stock = product.stockLevel ?? 0;
    final trackInventory = !widget.isRestaurant && (product.trackInventory ?? true);

    final isOut = trackInventory && stock <= 0;
    final isLow = trackInventory && stock > 0 && stock <= 5;
    final hasCartQuantity = widget.quantityInCart > 0;

    final borderColor = hasCartQuantity
        ? colors.primary.withValues(alpha: 0.95)
        : colors.border.withValues(alpha: isDark ? 0.76 : 0.92);

    final backgroundColor = colors.surfaceSoft.withValues(
      alpha: isDark ? 0.78 : 0.96,
    );

    return GestureDetector(
      onTap: isOut ? null : widget.onTap,
      onTapDown: isOut ? null : (_) => _setPressed(true),
      onTapCancel: isOut ? null : () => _setPressed(false),
      onTapUp: isOut ? null : (_) => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.975 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isOut ? 0.52 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: borderColor,
                width: hasCartQuantity ? 1.6 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasCartQuantity
                      ? colors.primary.withValues(alpha: isDark ? 0.20 : 0.12)
                      : colors.shadow.withValues(alpha: isDark ? 0.24 : 0.08),
                  blurRadius: hasCartQuantity ? 22 : 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDims.s3,
                            AppDims.s3,
                            AppDims.s3,
                            0,
                          ),
                          child: _ProductVisual(product: product),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDims.s3,
                          AppDims.s3,
                          AppDims.s3,
                          AppDims.s3,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _productName(product),
                              maxLines: 2,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs400(context).copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                                letterSpacing: -0.25,
                              ),
                            ),

                            const SizedBox(height: AppDims.s3),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Text(
                                        _formatPrice(product.price),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: AppTextStyles.bs500(context).copyWith(
                                          color: isOut ? colors.textHint : colors.primary,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                if (!widget.isRestaurant && trackInventory) ...[
                                  const SizedBox(height: 6),
                                  _StockText(
                                    stock: stock,
                                    isOut: isOut,
                                    isLow: isLow,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!widget.isRestaurant && trackInventory)
                    Positioned(
                      top: 18,
                      left: 18,
                      child: _StockBadge(
                        stock: stock,
                        isOut: isOut,
                        isLow: isLow,
                      ),
                    ),

                  if (hasCartQuantity)
                    Positioned(
                      top: 18,
                      right: 18,
                      child: _CartQuantityBadge(
                        quantity: widget.quantityInCart,
                      ),
                    ),

                  if (isOut)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.background.withValues(
                            alpha: isDark ? 0.18 : 0.32,
                          ),
                        ),
                        child: Center(
                          child: _OutOfStockBadge(),
                        ),
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

  String _productName(ProductData product) {
    final name = product.name?.trim();
    if (name == null || name.isEmpty) return 'Product';
    return name;
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00 SDG';

    final parsed = double.tryParse(value.toString());
    if (parsed == null) return '$value SDG';

    final hasDecimals = parsed % 1 != 0;
    final amount = hasDecimals ? parsed.toStringAsFixed(2) : parsed.toStringAsFixed(0);

    final formatted = amount.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );

    return '$formatted SDG';
  }
}

class _ProductVisual extends StatelessWidget {
  final ProductData product;

  const _ProductVisual({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = product.thumbnailUrl ?? product.image;
    final hasImage = imageUrl?.trim().isNotEmpty == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _placeholderColor(product),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              OfflineCachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              )
            else
              Center(
                child: Text(
                  _initials(product.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.15, -0.35),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            if (!hasImage)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colors.onPrimary.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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

    final hash = seed.codeUnits.fold<int>(
      0,
          (previous, element) => previous + element,
    );

    return palette[hash % palette.length];
  }

  String _initials(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return 'POS';

    final parts = text.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.length <= 4
          ? parts.first.toUpperCase()
          : parts.first.substring(0, 4).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _StockBadge extends StatelessWidget {
  final double stock;
  final bool isOut;
  final bool isLow;

  const _StockBadge({
    required this.stock,
    required this.isOut,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isOut
        ? colors.danger
        : isLow
        ? colors.warning
        : colors.success;

    final label = isOut ? 'Out' : _formatStock(stock);

    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.sm100(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatStock(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _StockText extends StatelessWidget {
  final double stock;
  final bool isOut;
  final bool isLow;

  const _StockText({
    required this.stock,
    required this.isOut,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final color = isOut
        ? colors.danger
        : isLow
        ? colors.warning
        : colors.textHint;

    final label = isOut
        ? 'Out'
        : isLow
        ? 'Low stock'
        : 'Stock';

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: AppTextStyles.sm100(context).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _CartQuantityBadge extends StatelessWidget {
  final int quantity;

  const _CartQuantityBadge({
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.onPrimary.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        'x$quantity',
        textAlign: TextAlign.center,
        style: AppTextStyles.sm100(context).copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _OutOfStockBadge extends StatelessWidget {
  const _OutOfStockBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Out of stock',
        style: AppTextStyles.sm200(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}