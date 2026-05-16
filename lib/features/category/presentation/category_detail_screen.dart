import 'dart:async';

import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_app_bar.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_category_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryData category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  bool _isGrid = true;
  bool _isRequestingMore = false;
  Timer? _loadMoreTimer;

  @override
  void initState() {
    super.initState();

    _loadCategoryProducts();
    _scrollCtrl.addListener(_onScroll);
  }

  void _loadCategoryProducts() {
    final categoryId = widget.category.id;

    if (categoryId == null || categoryId.trim().isEmpty) return;

    context.read<CategoryBloc>().add(
      OnLoadCategoryProducts(categoryId: categoryId),
    );
  }

  void _openAddProductSheet(CategoryData category) {
    showAddProductSheet(
      context,
      initialCategory: category,
    );
  }

  void _onScroll() {
    final categoryId = widget.category.id;

    if (categoryId == null || categoryId.trim().isEmpty) return;
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<CategoryBloc>().state;

    if (state.products.isEmpty) return;
    if (!state.hasMorePages) return;
    if (state.productsStatus == CategoryProductsStatus.loading) return;
    if (state.productsStatus == CategoryProductsStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (!shouldLoadMore) return;

    _isRequestingMore = true;

    context.read<CategoryBloc>().add(
      OnLoadMoreCategoryProducts(categoryId: categoryId),
    );

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = context.select<CategoryBloc, CategoryData?>(
          (bloc) {
        final matches = bloc.state.categoryList.where(
              (item) => item.id == widget.category.id,
        );

        return matches.isEmpty ? null : matches.first;
      },
    ) ??
        widget.category;

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          _loadCategoryProducts();
        }
      },
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          headerSliverBuilder: (context, _) {
            return [
              BlocBuilder<CategoryBloc, CategoryState>(
                buildWhen: (prev, curr) =>
                prev.products.length != curr.products.length ||
                    prev.productsStatus != curr.productsStatus ||
                    prev.productsFromCache != curr.productsFromCache,
                builder: (context, state) {
                  return CategoryAppBar(
                    category: category,
                    productCount: state.products.length,
                    isFromCache: state.productsFromCache,
                    isGrid: _isGrid,
                    onToggleLayout: () {
                      setState(() => _isGrid = !_isGrid);
                    },
                    onAddProduct: () => _openAddProductSheet(category),
                  );
                },
              ),
            ];
          },
          body: BlocBuilder<CategoryBloc, CategoryState>(
            buildWhen: (prev, curr) {
              return prev.productsStatus != curr.productsStatus ||
                  prev.products != curr.products ||
                  prev.hasMorePages != curr.hasMorePages;
            },
            builder: (context, state) {
              return switch (state.productsStatus) {
                CategoryProductsStatus.initial ||
                CategoryProductsStatus.loading =>
                    ProductLoadingView(isGrid: _isGrid),

                CategoryProductsStatus.failure => ProductsCategoryErrorView(
                  message: state.productsError,
                  categoryId: widget.category.id!,
                ),

                _ => state.products.isEmpty
                    ? ProductEmptyView(
                  title: 'No products yet',
                  message:
                  'This category is ready. Add the first product here so it appears directly under this category.',
                  primaryActionText: 'Add Product',
                  onPrimaryAction: () => _openAddProductSheet(category),
                )
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
      ),
    );
  }
}