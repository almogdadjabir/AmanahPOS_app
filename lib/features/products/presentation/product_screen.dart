import 'dart:async';

import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/category_filter.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_app_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_header_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  bool _isRequestingMore = false;
  Timer? _loadMoreDebounce;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const OnProductInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<ProductBloc>().state;

    if (state.products.isEmpty) return;
    if (!state.hasMorePages) return;
    if (state.productStatus == ProductStatus.loading) return;
    if (state.productStatus == ProductStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (!shouldLoadMore) return;

    _isRequestingMore = true;
    context.read<ProductBloc>().add(const OnLoadMoreProducts());

    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refreshProducts() async {
    context.read<ProductBloc>().add(const OnProductInitial());
  }

  bool _isLoading(ProductState state) {
    return state.productStatus == ProductStatus.initial ||
        state.productStatus == ProductStatus.loading;
  }

  bool _hasProducts(ProductState state) {
    return state.products.isNotEmpty;
  }

  void _openEmptyAction(ProductState state) {
    if (state.categories.isEmpty) {
      showAddCategorySheet(context);
      return;
    }

    showAddProductSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) =>
      prev.productStatus != curr.productStatus ||
          prev.products != curr.products ||
          prev.categories != curr.categories ||
          prev.isGrid != curr.isGrid ||
          prev.hasMorePages != curr.hasMorePages,
      builder: (context, state) {
        final isLoading = _isLoading(state);
        final hasProducts = _hasProducts(state);

        return Scaffold(
          body: RefreshIndicator(
            color: context.appColors.primary,
            onRefresh: _refreshProducts,
            child: switch (state.productStatus) {
              ProductStatus.initial || ProductStatus.loading =>
                  ProductLoadingView(
                    isGrid: state.isGrid,
                  ),

              ProductStatus.failure => ProductErrorView(
                message: state.responseError,
              ),

              _ => hasProducts
                  ? _ProductsContent(
                scrollController: _scrollCtrl,
                state: state,
              )
                  : _ProductsEmptyContent(
                state: state,
                onActionPressed: () => _openEmptyAction(state),
              ),
            },
          ),
          floatingActionButton: hasProducts && !isLoading
              ? FloatingActionButton.extended(
            onPressed: () => showAddProductSheet(context),
            backgroundColor: context.appColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Add Product',
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          )
              : null,
        );
      },
    );
  }
}

class _ProductsContent extends StatelessWidget {
  final ScrollController scrollController;
  final ProductState state;

  const _ProductsContent({
    required this.scrollController,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      headerSliverBuilder: (context, _) {
        return [
          const ProductsAppBar(),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              AppDims.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: ProductsHeaderView(
                products: state.products,
                categoryCount: state.categories.length,
              )
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .slideY(
                begin: 0.06,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: CategoryFilterDelegate(),
          ),
        ];
      },
      body: ProductsBody(
        products: state.products,
        isGrid: state.isGrid,
        isLoadingMore: state.productStatus == ProductStatus.loadingMore,
        hasMore: state.hasMorePages,
      ),
    );
  }
}

class _ProductsEmptyContent extends StatelessWidget {
  final ProductState state;
  final VoidCallback onActionPressed;

  const _ProductsEmptyContent({
    required this.state,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasCategories = state.categories.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s6,
              ),
              child: ProductEmptyView(
                hasCategories: hasCategories,
                title: hasCategories
                    ? 'No products yet'
                    : 'Create a category first',
                message: hasCategories
                    ? 'Add your first product to start building your catalog and begin selling.'
                    : 'Before adding products, create at least one category. This keeps your catalog organized and makes checkout faster.',
                primaryActionText: hasCategories
                    ? 'Add Product'
                    : 'Add Category',
                onPrimaryAction: onActionPressed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}