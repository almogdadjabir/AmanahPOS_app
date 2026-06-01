import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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

  String? get _categoryId {
    final id = widget.category.id?.trim();
    return id?.isEmpty == true ? null : id;
  }

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadCategoryProducts() {
    final categoryId = _categoryId;
    if (categoryId == null) return;

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

  void _toggleLayout() {
    setState(() => _isGrid = !_isGrid);
  }

  void _onScroll() {
    final categoryId = _categoryId;
    if (categoryId == null) return;
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
  Widget build(BuildContext context) {
    final category = context.select<CategoryBloc, CategoryData?>(
          (bloc) {
        for (final item in bloc.state.categoryList) {
          if (item.id == widget.category.id) return item;
        }
        return null;
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
              BlocSelector<CategoryBloc, CategoryState, _CategoryAppBarData>(
                selector: (state) {
                  return _CategoryAppBarData(
                    productCount: state.products.length,
                    productsStatus: state.productsStatus,
                    isFromCache: state.productsFromCache,
                  );
                },
                builder: (context, data) {
                  return CategoryAppBar(
                    category: category,
                    productCount: data.productCount,
                    isFromCache: data.isFromCache,
                    isGrid: _isGrid,
                    onToggleLayout: _toggleLayout,
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
                  categoryId: _categoryId ?? '',
                ),

                _ => state.products.isEmpty
                    ? ProductEmptyView(
                  title: context.tr.noProductsYet,
                  message: context.tr.categoryNoProductsMessage,
                  primaryActionText: context.tr.addProduct,
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

class _CategoryAppBarData {
  final int productCount;
  final CategoryProductsStatus productsStatus;
  final bool isFromCache;

  const _CategoryAppBarData({
    required this.productCount,
    required this.productsStatus,
    required this.isFromCache,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CategoryAppBarData &&
            other.productCount == productCount &&
            other.productsStatus == productsStatus &&
            other.isFromCache == isFromCache;
  }

  @override
  int get hashCode => Object.hash(
    productCount,
    productsStatus,
    isFromCache,
  );
}