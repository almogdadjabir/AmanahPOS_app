import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_app_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_category_error_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
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
      backgroundColor: context.appColors.background,
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
              child: _CategorySummaryCard(category: category)
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

class _CategorySummaryCard extends StatelessWidget {
  final CategoryData category;

  const _CategorySummaryCard({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = category.isActive ?? false;
    final childCount = category.children?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
            child: Icon(
              Icons.layers_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name ?? 'Category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description?.trim().isNotEmpty == true
                      ? category.description!.trim()
                      : 'Products under this category are shown below.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                Row(
                  children: [
                    _SummaryChip(
                      icon: Icons.circle,
                      iconColor: isActive
                          ? const Color(0xFF22C55E)
                          : colors.textHint,
                      label: isActive ? 'Active' : 'Inactive',
                    ),
                    if (childCount > 0) ...[
                      const SizedBox(width: AppDims.s2),
                      _SummaryChip(
                        icon: Icons.account_tree_outlined,
                        label: '$childCount sub categories',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _SummaryChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: icon == Icons.circle ? 8 : 13,
            color: iconColor ?? colors.textHint,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}