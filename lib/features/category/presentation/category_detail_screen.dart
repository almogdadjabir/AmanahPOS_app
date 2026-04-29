import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_app_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_category_error_view.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryData category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(
        OnLoadCategoryProducts(categoryId: widget.category.id!));

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<CategoryBloc>().add(
          OnLoadMoreCategoryProducts(categoryId: widget.category.id!));
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = context
        .watch<CategoryBloc>()
        .state
        .categoryList
        .where((c) => c.id == widget.category.id)
        .firstOrNull ??
        widget.category;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, _) => [
          CategoryAppBar(
            category: category,
            isGrid: _isGrid,
            onToggleLayout: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
        body: BlocBuilder<CategoryBloc, CategoryState>(
          buildWhen: (prev, curr) =>
          prev.productsStatus != curr.productsStatus ||
              prev.products != curr.products,
          builder: (context, state) {
            return switch (state.productsStatus) {
              CategoryProductsStatus.initial ||
              CategoryProductsStatus.loading =>
                  ProductLoadingView(isGrid: _isGrid),

              CategoryProductsStatus.failure =>
                  ProductsCategoryErrorView(
                    message: state.productsError,
                    categoryId: widget.category.id!,
                  ),

              _ => state.products.isEmpty
                  ? const ProductEmptyView(title: 'No products found', message: 'Add your first product to get started.',)
                  : ProductsBody(
                products: state.products,
                isGrid: _isGrid,
                isLoadingMore: state.productsStatus ==
                    CategoryProductsStatus.loadingMore,
                hasMore: state.hasMorePages,
              ),
            };
          },
        ),
      ),
    );
  }
}