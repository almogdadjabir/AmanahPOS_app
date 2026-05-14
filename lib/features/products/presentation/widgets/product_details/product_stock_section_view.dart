import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/no_product_stock_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_stock_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductStockSectionView extends StatelessWidget {
  final ProductData product;

  const ProductStockSectionView({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (prev, curr) {
        return prev.stockList != curr.stockList || prev.status != curr.status;
      },
      builder: (context, state) {
        final isInitialLoading =
            (state.status == InventoryStatus.initial ||
                state.status == InventoryStatus.loading ||
                state.status == InventoryStatus.loadingMore) &&
                state.stockList.isEmpty;

        if (isInitialLoading) {
          return const _ProductStockLoadingCard();
        }

        final productStock = _filterProductStock(state.stockList);

        if (productStock.isEmpty) {
          return NoProductStockCard(
            onAddStock: () {
              showAddStockProductSheet(
                context,
                initialProduct: product,
              );
            },
          );
        }

        return Column(
          children: List.generate(productStock.length, (index) {
            final stock = productStock[index];
            final isLast = index == productStock.length - 1;

            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppDims.s3,
              ),
              child: ProductStockCard(stock: stock)
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 24 + (index % 5) * 18),
                duration: 220.ms,
              )
                  .slideY(
                begin: 0.025,
                end: 0,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
            );
          }),
        );
      },
    );
  }

  List<StockData> _filterProductStock(List<StockData> stockList) {
    final productId = product.id;

    if (productId != null) {
      return stockList.where((stock) => stock.product == productId).toList();
    }

    final productName = product.name?.trim().toLowerCase();

    if (productName == null || productName.isEmpty) {
      return const [];
    }

    return stockList.where((stock) {
      return stock.productName?.trim().toLowerCase() == productName;
    }).toList();
  }
}

class _ProductStockLoadingCard extends StatelessWidget {
  const _ProductStockLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          _SkeletonBox(
            width: 52,
            height: 52,
            radius: AppDims.rMd,
            color: colors.surfaceSoft,
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: double.infinity,
                  height: 15,
                  radius: 999,
                  color: colors.surfaceSoft,
                ),
                const SizedBox(height: AppDims.s2),
                _SkeletonBox(
                  width: 150,
                  height: 13,
                  radius: 999,
                  color: colors.surfaceSoft,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
          _SkeletonBox(
            width: 48,
            height: 36,
            radius: AppDims.rSm,
            color: colors.surfaceSoft,
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    )
        .fade(
      begin: 0.45,
      end: 1,
      duration: 750.ms,
      curve: Curves.easeInOut,
    );
  }
}