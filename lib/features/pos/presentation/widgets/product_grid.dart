
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_product_card.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductData> products;

  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    // Resolved once per build — never changes within a session.
    final isRestaurant =
        context.read<AuthBloc>().state.permissions.isRestaurant;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s4,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:  2,
        mainAxisSpacing: AppDims.s3,
        crossAxisSpacing: AppDims.s3,
        childAspectRatio: 0.80,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) {
        return _ProductGridItem(
          key:          ValueKey(products[index].id ?? index),
          product:      products[index],
          isRestaurant: isRestaurant,
        );
      },
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final ProductData product;
  final bool        isRestaurant;

  const _ProductGridItem({
    super.key,
    required this.product,
    required this.isRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    final quantityInCart = context.select<PosBloc, int>(
          (bloc) => bloc.state.quantityOf(product.id),
    );

    return RepaintBoundary(
      child: PosProductCard(
        product:       product,
        quantityInCart: quantityInCart,
        isRestaurant:  isRestaurant,
        onTap: () => context.read<PosBloc>().add(PosAddProduct(product)),
      ),
    );
  }
}