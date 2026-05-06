import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_app_bar.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_summary_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_category_error_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  void initState() {
    super.initState();

    final id = widget.category.id;
    if (id != null) {
      context.read<CategoryBloc>().add(
        OnLoadCategoryProducts(categoryId: id),
      );
    }

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final id = widget.category.id;
    if (id == null) return;
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<CategoryBloc>().state;
    if (!state.hasMorePages) return;
    if (state.productsStatus == CategoryProductsStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 240;

    if (!shouldLoadMore) return;

    _isRequestingMore = true;

    context.read<CategoryBloc>().add(
      OnLoadMoreCategoryProducts(categoryId: id),
    );

    Future<void>.delayed(const Duration(milliseconds: 450), () {
      _isRequestingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = context.select<CategoryBloc, CategoryData?>(
          (bloc) => bloc.state.categoryList
          .where((c) => c.id == widget.category.id)
          .firstOrNull,
    ) ??
        widget.category;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, _) => [
          CategoryAppBar(
            category: category,
            isGrid: _isGrid,
            onToggleLayout: () => setState(() => _isGrid = !_isGrid),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              AppDims.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: CategorySummaryCard(category: category)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(
                begin: 0.06,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ],
        body: BlocBuilder<CategoryBloc, CategoryState>(
          buildWhen: (prev, curr) =>
          prev.productsStatus != curr.productsStatus ||
              prev.products != curr.products ||
              prev.hasMorePages != curr.hasMorePages,
          builder: (context, state) {
            return switch (state.productsStatus) {
              CategoryProductsStatus.initial ||
              CategoryProductsStatus.loading => ProductLoadingView(
                isGrid: _isGrid,
              ),

              CategoryProductsStatus.failure => ProductsCategoryErrorView(
                message: state.productsError,
                categoryId: widget.category.id!,
              ),

              _ => state.products.isEmpty
                  ? const ProductEmptyView(
                title: 'No products in this category',
                message:
                'Products assigned to this category will appear here.',
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
    );
  }
}