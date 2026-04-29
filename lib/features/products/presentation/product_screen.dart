import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/category_filter.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_app_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const OnProductInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ProductBloc>().add(const OnLoadMoreProducts());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, _) => [
          ProductsAppBar(),
          SliverPersistentHeader(
            pinned: true,
            delegate: CategoryFilterDelegate(),
          ),
        ],
        body: BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, curr) =>
          prev.productStatus != curr.productStatus ||
              prev.products != curr.products ||
              prev.isGrid != curr.isGrid,
          builder: (context, state) {
            return switch (state.productStatus) {
              ProductStatus.initial ||
              ProductStatus.loading =>
                  ProductLoadingView(isGrid: state.isGrid),

              ProductStatus.failure =>
                  ProductErrorView(message: state.responseError),

              _ => state.products.isEmpty
                  ? const ProductEmptyView(title: 'No products found', message: 'Add your first product to get started.',)
                  : ProductsBody(
                products: state.products,
                isGrid: state.isGrid,
                isLoadingMore: state.productStatus ==
                    ProductStatus.loadingMore,
                hasMore: state.hasMorePages,
              ),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddProductSheet(context),
        backgroundColor: context.appColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 13,
            fontWeight: FontWeight.w800, color: Colors.white,
          ),
        ),
      ),
    );
  }
}


