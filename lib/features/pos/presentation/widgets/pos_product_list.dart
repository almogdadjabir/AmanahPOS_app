import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

/// Inset grouped product list for the mobile Sell screen.
class PosProductList extends StatelessWidget {
  final List<ProductData> products;

  const PosProductList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final isRestaurant = context
        .read<AuthBloc>()
        .state
        .permissions
        .isRestaurant;
    final currency = context.select<DashboardSummaryBloc, String>(
      (bloc) => bloc.state.summary?.currency ?? 'SDG',
    );

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        0,
        AppDims.s4,
        AppDims.s6,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) {
        final row = _RowShell(
          isFirst: index == 0,
          isLast: index == products.length - 1,
          child: _PosProductRow(
            product: products[index],
            isRestaurant: isRestaurant,
            currency: currency,
            showSeparator: index > 0,
          ),
        );

        return row;
      },
    );
  }
}

class _RowShell extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget child;

  const _RowShell({
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = BorderSide(color: colors.border);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(AppDims.rLg) : Radius.zero,
          bottom: isLast ? const Radius.circular(AppDims.rLg) : Radius.zero,
        ),
        border: isDark
            ? Border(
                left: hairline,
                right: hairline,
                top: isFirst ? hairline : BorderSide.none,
                bottom: isLast ? hairline : BorderSide.none,
              )
            : null,
      ),
      child: child,
    );
  }
}

class _PosProductRow extends StatelessWidget {
  static const double _thumb = 40;

  final ProductData product;
  final bool isRestaurant;
  final String currency;
  final bool showSeparator;

  const _PosProductRow({
    required this.product,
    required this.isRestaurant,
    required this.currency,
    required this.showSeparator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;

    final stock = product.stockLevel ?? 0;
    final trackInventory = !isRestaurant && (product.trackInventory ?? true);
    final isOut = trackInventory && stock <= 0;
    final isLow = trackInventory && stock > 0 && stock <= 5;

    final stockLabel = !trackInventory
        ? null
        : isOut
        ? tr.posRowOutOfStock
        : isLow
        ? tr.posRowLowStock(_formatStock(stock))
        : tr.posRowInStock(_formatStock(stock));

    return Opacity(
      opacity: isOut ? 0.5 : 1,
      child: Stack(
        children: [
          if (showSeparator)
            PositionedDirectional(
              top: 0,
              start: AppDims.s3 + _thumb + AppDims.s3,
              end: 0,
              child: Divider(height: 0.5, thickness: 0.5, color: colors.border),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3,
                vertical: AppDims.s2 + 2,
              ),
              child: Row(
                children: [
                  _Thumb(product: product, size: _thumb),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _productName(product),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge!.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (stockLabel != null)
                          Text(
                            stockLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(
                              color: isLow ? colors.warning : colors.textHint,
                              fontWeight: isLow
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDims.s2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatPrice(product.price),
                        maxLines: 1,
                        style: text.bodyLarge!
                            .copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            )
                            .tabular,
                      ),
                      Text(
                        currency,
                        style: text.labelSmall!.copyWith(
                          color: colors.textHint,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppDims.s3),
                  _RowControl(
                    product: product,
                    isRestaurant: isRestaurant,
                    isOut: isOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _productName(ProductData product) {
    final name = product.name?.trim();
    if (name == null || name.isEmpty) return 'Product';
    return name;
  }

  String _formatStock(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatPrice(String? value) {
    if (value == null) return '0';
    final parsed = double.tryParse(value);
    if (parsed == null) return value;

    final amount = parsed % 1 != 0
        ? parsed.toStringAsFixed(2)
        : parsed.toStringAsFixed(0);

    return amount.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _Thumb extends StatelessWidget {
  final ProductData product;
  final double size;

  const _Thumb({required this.product, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = product.thumbnailUrl ?? product.image;
    final hasImage = imageUrl?.trim().isNotEmpty == true;
    final name = product.name?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: colors.surfaceSoft,
          child: hasImage
              ? OfflineCachedImage(imageUrl: imageUrl, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    name.isEmpty ? '·' : name.characters.first,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RowControl extends StatelessWidget {
  final ProductData product;
  final bool isRestaurant;
  final bool isOut;

  const _RowControl({
    required this.product,
    required this.isRestaurant,
    required this.isOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final productId = product.id;

    final quantity = context.select<PosBloc, int>(
      (bloc) => bloc.state.quantityOf(productId),
    );

    if (isOut || productId == null) {
      return SizedBox(
        width: 32,
        child: Text(
          '—',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: colors.textHint),
        ),
      );
    }

    void add() {
      context.read<PosBloc>().add(
        PosAddProduct(product, ignoreStockLimit: isRestaurant),
      );
    }

    if (quantity == 0) {
      return Pressable(
        onTap: add,
        haptic: true,
        semanticLabel: product.name,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              PhosphorIconsRegular.plus,
              size: 20,
              color: colors.primary,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppDims.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: PhosphorIconsRegular.minus,
            onTap: () =>
                context.read<PosBloc>().add(PosDecrementItem(productId)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 16),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: colors.primary, fontWeight: FontWeight.w600)
                  .tabular,
            ),
          ),
          _StepButton(
            icon: PhosphorIconsRegular.plus,
            onTap: () => context.read<PosBloc>().add(
              PosIncrementItem(productId, ignoreStockLimit: isRestaurant),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: true,
      scale: 0.92,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 18, color: context.appColors.primary),
      ),
    );
  }
}
