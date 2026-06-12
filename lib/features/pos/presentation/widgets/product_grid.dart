import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/desktop_pos_product_card.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_product_card.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductData> products;
  final int? crossAxisCount;

  /// Renders the compact desktop tile instead of the mobile card.
  final bool desktop;

  const ProductGrid({
    super.key,
    required this.products,
    this.crossAxisCount,
    this.desktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRestaurant = context
        .read<AuthBloc>()
        .state
        .permissions
        .isRestaurant;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: desktop
          ? const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s3,
              AppDims.s4,
              AppDims.s6,
            )
          : const EdgeInsets.fromLTRB(AppDims.s4, AppDims.s3, AppDims.s4, 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount ?? 2,
        mainAxisSpacing: desktop ? AppDims.s3 : AppDims.s4,
        crossAxisSpacing: AppDims.s3,
        childAspectRatio: desktop ? 0.82 : 0.74,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) {
        return _ProductGridItem(
          key: ValueKey(products[index].id ?? index),
          product: products[index],
          isRestaurant: isRestaurant,
          desktop: desktop,
        );
      },
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final ProductData product;
  final bool isRestaurant;
  final bool desktop;

  const _ProductGridItem({
    super.key,
    required this.product,
    required this.isRestaurant,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final quantityInCart = context.select<PosBloc, int>(
      (bloc) => bloc.state.quantityOf(product.id),
    );

    void addToCart() {
      context.read<PosBloc>().add(
        PosAddProduct(product, ignoreStockLimit: isRestaurant),
      );
    }

    return RepaintBoundary(
      child: desktop
          ? DesktopPosProductCard(
              product: product,
              quantityInCart: quantityInCart,
              isRestaurant: isRestaurant,
              onTap: addToCart,
            )
          : PosProductCard(
              product: product,
              quantityInCart: quantityInCart,
              isRestaurant: isRestaurant,
              onTap: addToCart,
            ),
    );
  }
}
