import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/no_product_stock_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_details/product_stock_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductStockSectionView extends StatelessWidget {
  final ProductData product;

  const ProductStockSectionView({super.key,
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
          return Container(
            height: 88,
            decoration: BoxDecoration(
              color: context.appColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
          );
        }

        if (productStock.isEmpty) {
          return NoProductStockCard(
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
              child: ProductStockCard(stock: productStock[index]),
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
