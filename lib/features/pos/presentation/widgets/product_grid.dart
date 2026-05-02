import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/widgets/pos_product_card.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductData> products;

  const ProductGrid({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s4,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDims.s3,
        crossAxisSpacing: AppDims.s3,
        childAspectRatio: 0.80,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) {
        return _ProductGridItem(
          key: ValueKey(products[index].id ?? index),
          product: products[index],
        );
      },
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final ProductData product;

  const _ProductGridItem({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final quantityInCart = context.select<PosBloc, int>(
          (bloc) => bloc.state.quantityOf(product.id),
    );

    return RepaintBoundary(
      child: PosProductCard(
        product: product,
        quantityInCart: quantityInCart,
        onTap: () {
          context.read<PosBloc>().add(PosAddProduct(product));
        },
      ),
    );
  }
}