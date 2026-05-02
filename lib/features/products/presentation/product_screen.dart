import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/category_filter.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_app_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_body.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const OnProductInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<ProductBloc>().state;

    if (!state.hasMorePages) return;
    if (state.productStatus == ProductStatus.loadingMore) return;
    if (state.productStatus == ProductStatus.loading) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (!shouldLoadMore) return;

    _isRequestingMore = true;

    context.read<ProductBloc>().add(const OnLoadMoreProducts());

    Future<void>.delayed(const Duration(milliseconds: 500), () {
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
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: RefreshIndicator(
        color: context.appColors.primary,
        onRefresh: () async {
          context.read<ProductBloc>().add(const OnProductInitial());
        },
        child: NestedScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          headerSliverBuilder: (context, _) => [
            const ProductsAppBar(),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s2,
              ),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<ProductBloc, ProductState>(
                  buildWhen: (prev, curr) =>
                  prev.products != curr.products ||
                      prev.categories != curr.categories ||
                      prev.productStatus != curr.productStatus,
                  builder: (context, state) {
                    return _ProductsHeader(
                      products: state.products,
                      categoryCount: state.categories.length,
                    )
                        .animate()
                        .fadeIn(duration: 320.ms)
                        .slideY(
                      begin: 0.06,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: CategoryFilterDelegate(),
            ),
          ],
          body: BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (prev, curr) =>
            prev.productStatus != curr.productStatus ||
                prev.products != curr.products ||
                prev.isGrid != curr.isGrid ||
                prev.hasMorePages != curr.hasMorePages,
            builder: (context, state) {
              return switch (state.productStatus) {
                ProductStatus.initial ||
                ProductStatus.loading => ProductLoadingView(
                  isGrid: state.isGrid,
                ),

                ProductStatus.failure => ProductErrorView(
                  message: state.responseError,
                ),

                _ => state.products.isEmpty
                    ? const ProductEmptyView(
                  title: 'No products yet',
                  message:
                  'Add your first product to start building your catalog.',
                )
                    : ProductsBody(
                  products: state.products,
                  isGrid: state.isGrid,
                  isLoadingMore:
                  state.productStatus == ProductStatus.loadingMore,
                  hasMore: state.hasMorePages,
                ),
              };
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  final List<ProductData> products;
  final int categoryCount;

  const _ProductsHeader({
    required this.products,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final activeCount = products.where((p) => p.isActive == true).length;
    final outOfStockCount =
        products.where((p) => (p.stockLevel ?? 0) <= 0).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
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
                      'Product Catalog',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage items, prices, categories and stock availability.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          Row(
            children: [
              Expanded(
                child: _ProductMiniStat(
                  label: 'Products',
                  value: '${products.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ProductMiniStat(
                  label: 'Active',
                  value: '$activeCount',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ProductMiniStat(
                  label: 'Out',
                  value: '$outOfStockCount',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _ProductMiniStat(
                  label: 'Cats',
                  value: '$categoryCount',
                  icon: Icons.layers_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProductMiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}