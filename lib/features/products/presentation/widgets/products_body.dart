import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/load_more_indicator.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_grid_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_list_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProductsBody extends StatelessWidget {
  final List<ProductData> products;
  final bool isGrid;
  final bool isLoadingMore;
  final bool hasMore;

  const ProductsBody({
    super.key,
    required this.products,
    required this.isGrid,
    required this.isLoadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: isGrid
          ? _GridBody(
        key: const ValueKey('grid'),
        products: products,
        isLoadingMore: isLoadingMore,
      )
          : _ListBody(
        key: const ValueKey('list'),
        products: products,
        isLoadingMore: isLoadingMore,
      ),
    );
  }
}

class _GridBody extends StatelessWidget {
  final List<ProductData> products;
  final bool isLoadingMore;

  const _GridBody({
    super.key,
    required this.products,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s4,
            AppDims.s4,
            0,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductGridCard(product: products[i])
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 20 + (i % 8) * 25),
                duration: 240.ms,
              )
                  .slideY(
                begin: 0.03,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDims.s3,
              mainAxisSpacing: AppDims.s3,
              childAspectRatio: 0.76,
            ),
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(child: LoadMoreIndicator()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _ListBody extends StatelessWidget {
  final List<ProductData> products;
  final bool isLoadingMore;

  const _ListBody({
    super.key,
    required this.products,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s4,
            AppDims.s4,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
            itemBuilder: (_, i) => ProductListCard(product: products[i])
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 20 + (i % 8) * 25),
              duration: 240.ms,
            )
                .slideY(
              begin: 0.03,
              end: 0,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(child: LoadMoreIndicator()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}