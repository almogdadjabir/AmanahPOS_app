import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_action_sheet.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/features/products/presentation/widgets/delete_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/edit_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/placeholder_image.dart';
import 'package:amana_pos/features/products/presentation/widgets/stock_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductData product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductBloc, ProductState, ProductData?>(
      selector: (state) {
        return state.products.where((p) => p.id == product.id).firstOrNull;
      },
      builder: (context, latestProduct) {
        final currentProduct = latestProduct ?? product;

        return Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ProductDetailAppBar(product: currentProduct),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProductSummaryCard(product: currentProduct)
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProductActions(product: currentProduct)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s5,
                  AppDims.s4,
                  AppDims.s2,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Stock by Shop',
                    style: AppTextStyles.bs600(context).copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  AppDims.s6,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProductStockSection(product: currentProduct),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductDetailAppBar extends StatelessWidget {
  final ProductData product;

  const _ProductDetailAppBar({
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
            // product.image?.trim().isNotEmpty == true
            //     ? Image.network(
            //   product.image!.trim(),
            //   fit: BoxFit.cover,
            //   errorBuilder: (_, __, ___) => const PlaceholderImage(),
            // )
            //     : const PlaceholderImage(),
            imageUrl == null
                ? const PlaceholderImage()
                : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const PlaceholderImage(),
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
                    const _ImageStatusPill(label: 'Inactive'),
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

class _ImageStatusPill extends StatelessWidget {
  final String label;

  const _ImageStatusPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  final ProductData product;

  const _ProductSummaryCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stock = product.stockLevel ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.payments_outlined,
                  label: 'Price',
                  value: _formatPrice(product.price),
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InfoTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock',
                  value: _formatQty(stock),
                  color: _stockColor(stock),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s2),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.layers_outlined,
                  label: 'Category',
                  value: product.categoryName?.trim().isNotEmpty == true
                      ? product.categoryName!.trim()
                      : 'No category',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InfoTile(
                  icon: product.isActive == false
                      ? Icons.pause_circle_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  label: 'Status',
                  value: product.isActive == false ? 'Inactive' : 'Active',
                  color: product.isActive == false
                      ? context.appColors.textHint
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: StockChip(level: stock),
          ),
        ],
      ),
    );
  }

  Color _stockColor(double value) {
    if (value <= 0) return const Color(0xFFDC2626);
    if (value <= 5) return const Color(0xFFEA580C);
    return const Color(0xFF16A34A);
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00';
    return '$value';
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductActions extends StatelessWidget {
  final ProductData product;

  const _ProductActions({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: context.appColors.primary,
            onTap: () {
              showEditProductSheet(context, product: product);
            },
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _ActionButton(
            icon: Icons.inventory_2_outlined,
            label: 'Add Stock',
            color: const Color(0xFF16A34A),
            onTap: () {
              showAddStockProductSheet(
                context,
                initialProduct: product,
              );
            },
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _ActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFDC2626),
            onTap: () {
              showDeleteProductSheet(context, product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(AppDims.s2),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStockSection extends StatelessWidget {
  final ProductData product;

  const _ProductStockSection({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (prev, curr) =>
      prev.stockList != curr.stockList || prev.status != curr.status,
      builder: (context, state) {
        final productStock = _filterProductStock(state.stockList);

        if (state.status == InventoryStatus.loading &&
            state.stockList.isEmpty) {
          return const _StockLoadingCard();
        }

        if (productStock.isEmpty) {
          return _NoProductStockCard(
            onAddStock: () => showAddStockProductSheet(
              context,
              initialProduct: product,
            ),
          );
        }

        return Column(
          children: List.generate(productStock.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == productStock.length - 1 ? 0 : AppDims.s3,
              ),
              child: _ProductStockCard(stock: productStock[index]),
            );
          }),
        );
      },
    );
  }

  List<StockData> _filterProductStock(List<StockData> stockList) {
    final productId = product.id;

    if (productId != null) {
      return stockList.where((s) => s.product == productId).toList();
    }

    final name = product.name?.trim().toLowerCase();

    if (name == null || name.isEmpty) return const [];

    return stockList
        .where((s) => s.productName?.trim().toLowerCase() == name)
        .toList();
  }
}

class _ProductStockCard extends StatelessWidget {
  final StockData stock;

  const _ProductStockCard({
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isOut = stock.isOutOfStock ?? false;
    final isLow = stock.isLowStock ?? false;

    final color = isOut
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final label = isOut
        ? 'Out of stock'
        : isLow
        ? 'Low stock'
        : 'In stock';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          final allStock = context.read<InventoryBloc>().state.stockList;

          showStockActionSheet(
            context,
            stock: stock,
            allStock: allStock,
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.shopName ?? 'Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatQty(stock.qty),
                style: AppTextStyles.bs600(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(
                Icons.tune_rounded,
                color: colors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _NoProductStockCard extends StatelessWidget {
  final VoidCallback onAddStock;

  const _NoProductStockCard({
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: colors.textHint,
            size: 38,
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            'No stock added yet',
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            'Add stock for this product to start tracking availability by shop.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          FilledButton.icon(
            onPressed: onAddStock,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Stock'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockLoadingCard extends StatelessWidget {
  const _StockLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
    );
  }
}