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
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: isGrid
          ? _GridBody(
        key: const ValueKey('products_grid'),
        products: products,
        isLoadingMore: isLoadingMore,
        hasMore: hasMore,
      )
          : _ListBody(
        key: const ValueKey('products_list'),
        products: products,
        isLoadingMore: isLoadingMore,
        hasMore: hasMore,
      ),
    );
  }
}

class _GridBody extends StatelessWidget {
  final List<ProductData> products;
  final bool isLoadingMore;
  final bool hasMore;

  const _GridBody({
    super.key,
    required this.products,
    required this.isLoadingMore,
    required this.hasMore,
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
                  (context, index) {
                final product = products[index];

                return ProductGridCard(product: product)
                    .animate()
                    .fadeIn(
                  delay: Duration(milliseconds: 18 + (index % 6) * 16),
                  duration: 210.ms,
                )
                    .slideY(
                  begin: 0.025,
                  end: 0,
                  duration: 210.ms,
                  curve: Curves.easeOutCubic,
                );
              },
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDims.s3,
              mainAxisSpacing: AppDims.s3,
              childAspectRatio: 0.74,
            ),
          ),
        ),

        if (isLoadingMore && hasMore)
          const SliverToBoxAdapter(
            child: LoadMoreIndicator(),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 130),
        ),
      ],
    );
  }
}

class _ListBody extends StatelessWidget {
  final List<ProductData> products;
  final bool isLoadingMore;
  final bool hasMore;

  const _ListBody({
    super.key,
    required this.products,
    required this.isLoadingMore,
    required this.hasMore,
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
            itemBuilder: (context, index) {
              final product = products[index];

              return ProductListCard(product: product)
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 18 + (index % 6) * 16),
                duration: 210.ms,
              )
                  .slideY(
                begin: 0.025,
                end: 0,
                duration: 210.ms,
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),

        if (isLoadingMore && hasMore)
          const SliverToBoxAdapter(
            child: LoadMoreIndicator(),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 130),
        ),
      ],
    );
  }
}