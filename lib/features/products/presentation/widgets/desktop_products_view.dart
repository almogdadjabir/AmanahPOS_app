import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/providers/feature_bloc_providers.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/desktop_product_detail_drawer.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/add_product_sheet.dart';
import 'package:amana_pos/features/products/presentation/widgets/desktop_product_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/desktop_products_sidebar.dart';
import 'package:amana_pos/features/products/presentation/widgets/desktop_products_stats_row.dart';
import 'package:amana_pos/features/products/presentation/widgets/desktop_products_top_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_error_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_list_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_header_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double _kSidebarWidth = 320;
const double _kMaxContentWidth = 1800;

/// Desktop layout for the products / menu catalog screen.
///
/// Trades the mobile single/multi-column list for a control-room
/// composition: a search/add top bar, clickable overview cards that double
/// as quick filters, a category chip row, a responsive product grid with
/// infinite scroll, and a fixed sidebar surfacing categories and
/// low-stock triage — mirrors `DesktopInventoryView`.
class DesktopProductsView extends StatefulWidget {
  const DesktopProductsView({super.key});

  @override
  State<DesktopProductsView> createState() => _DesktopProductsViewState();
}

class _DesktopProductsViewState extends State<DesktopProductsView>
    with SingleTickerProviderStateMixin {
  ProductData? _drawerProduct;
  ProductData? _lastDrawerProduct;
  late AnimationController _drawerCtrl;
  late Animation<double> _drawerAnim;
  OverlayEntry? _overlayEntry;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isRequestingMore = false;
  Timer? _loadMoreDebounce;
  String _query = '';
  ProductQuickFilter _quickFilter = ProductQuickFilter.all;

  @override
  void initState() {
    super.initState();
    _drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerAnim = CurvedAnimation(
      parent: _drawerCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    context.read<ProductBloc>().add(const OnProductInitial());
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _openDrawer(ProductData product) {
    setState(() {
      _drawerProduct = product;
      _lastDrawerProduct = product;
    });
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlayContent);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
    _drawerCtrl.forward();
  }

  void _closeDrawer() {
    setState(() => _drawerProduct = null);
    _overlayEntry?.markNeedsBuild();
    _drawerCtrl.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) setState(() => _lastDrawerProduct = null);
    });
  }

  Widget _buildOverlayContent(BuildContext overlayCtx) {
    final product = _lastDrawerProduct;
    if (product == null) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: BlocProvider.value(
        value: context.read<ProductBloc>(),
        child: AnimatedBuilder(
        animation: _drawerAnim,
        builder: (ctx, child) {
          final isRTL = Directionality.of(ctx) == TextDirection.rtl;
          final dx = (isRTL ? -1.0 : 1.0) *
              kDesktopDrawerWidth *
              (1 - _drawerAnim.value);
          return Stack(
            children: [
              IgnorePointer(
                ignoring: _drawerProduct == null,
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: ColoredBox(
                    color: Colors.black
                        .withValues(alpha: _drawerAnim.value * 0.35),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: kDesktopDrawerWidth,
                child: IgnorePointer(
                  ignoring: _drawerProduct == null,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: FeatureBlocProviders.inventory(
          child: DesktopProductDetailDrawer(
            product: product,
            onClose: _closeDrawer,
          ),
        ),
      ),
      ),
    );
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  void _selectQuickFilter(ProductQuickFilter filter) {
    if (_quickFilter == filter) return;
    setState(() => _quickFilter = filter);

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<ProductBloc>().state;
    if (state.products.isEmpty) return;
    if (!state.hasMorePages) return;
    if (state.productStatus == ProductStatus.loading) return;
    if (state.productStatus == ProductStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent - 320) return;

    _isRequestingMore = true;
    context.read<ProductBloc>().add(const OnLoadMoreProducts());

    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refresh() async {
    context.read<ProductBloc>().add(const OnProductInitial(force: true));
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _drawerCtrl.dispose();
    _loadMoreDebounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRestaurant = context.read<AuthBloc>().state.permissions.isRestaurant;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            DesktopProductsTopBar(
              searchCtrl: _searchCtrl,
              isRestaurant: isRestaurant,
              onRefresh: _refresh,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kMaxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDims.s6),
                    child: BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, state) {
                        return switch (state.productStatus) {
                          ProductStatus.initial ||
                          ProductStatus.loading =>
                            const _DesktopProductsSkeleton(),

                          ProductStatus.failure => ProductErrorView(
                            message: state.responseError,
                          ),

                          _ => _DesktopProductsContent(
                            state: state,
                            query: _query,
                            quickFilter: _quickFilter,
                            onQuickFilterChanged: _selectQuickFilter,
                            scrollCtrl: _scrollCtrl,
                            isRestaurant: isRestaurant,
                            onClearSearch: _searchCtrl.clear,
                            onProductTap: _openDrawer,
                          ),
                        };
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────

class _DesktopProductsContent extends StatelessWidget {
  final ProductState state;
  final String query;
  final ProductQuickFilter quickFilter;
  final ValueChanged<ProductQuickFilter> onQuickFilterChanged;
  final ScrollController scrollCtrl;
  final bool isRestaurant;
  final VoidCallback onClearSearch;
  final void Function(ProductData) onProductTap;

  const _DesktopProductsContent({
    required this.state,
    required this.query,
    required this.quickFilter,
    required this.onQuickFilterChanged,
    required this.scrollCtrl,
    required this.isRestaurant,
    required this.onClearSearch,
    required this.onProductTap,
  });

  List<ProductData> _applyQuickFilter(List<ProductData> products) {
    switch (quickFilter) {
      case ProductQuickFilter.all:
        return products;
      case ProductQuickFilter.active:
        return products.where((p) => p.isActive == true).toList();
      case ProductQuickFilter.outOfStock:
        return products.where((p) => (p.stockLevel ?? 0) <= 0).toList();
    }
  }

  List<ProductData> _applySearch(List<ProductData> products) {
    if (query.isEmpty) return products;
    return products.where((p) {
      final name = (p.name ?? '').toLowerCase();
      final sku = (p.sku ?? '').toLowerCase();
      final barcode = (p.barcode ?? '').toLowerCase();
      final category = (p.categoryName ?? '').toLowerCase();
      return name.contains(query) ||
          sku.contains(query) ||
          barcode.contains(query) ||
          category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showStock = !isRestaurant;
    final quickFiltered = _applyQuickFilter(state.products);
    final visible = _applySearch(quickFiltered);
    final isLoadingMore = state.productStatus == ProductStatus.loadingMore;
    final isEmpty = state.products.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            controller: scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: DesktopProductsStatsRow(
                  products: state.products,
                  categoryCount: state.categories.length,
                  isRestaurant: isRestaurant,
                  selectedFilter: quickFilter,
                  onFilterChanged: onQuickFilterChanged,
                ).animate().fadeIn(duration: 280.ms),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDims.s5),
              ),
              if (isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ProductEmptyView(
                    hasCategories: true,
                    title: context.tr.noProductsYet,
                    message: context.tr.noProductsMessage,
                    primaryActionText: context.tr.addProduct,
                    onPrimaryAction: () => showAddProductSheet(context),
                  ),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoSearchResults(
                    query: query,
                    onClear: onClearSearch,
                  ),
                )
              else if (state.isGrid)
                SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisExtent: 300,
                        crossAxisSpacing: AppDims.s3,
                        mainAxisSpacing: AppDims.s3,
                      ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = visible[index];
                    return DesktopProductCard(
                      product: item,
                      showStock: showStock,
                      onProductTap: onProductTap,
                    )
                        .animate(delay: (index % 12 * 25).ms)
                        .fadeIn(duration: 240.ms)
                        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
                  }, childCount: visible.length),
                )
              else
                SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDims.s3),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return ProductListCard(product: item)
                        .animate(delay: (index % 12 * 25).ms)
                        .fadeIn(duration: 240.ms)
                        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
                  },
                ),
              if (isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDims.s5),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: context.appColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDims.s6)),
            ],
          ),
        ),
        const SizedBox(width: AppDims.s5),
        SizedBox(
          width: _kSidebarWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppDims.s6),
            child: DesktopProductsSidebar(
              products: state.products,
              categories: state.categories,
              selectedCategoryId: state.selectedCategoryId,
              isRestaurant: isRestaurant,
              onProductTap: onProductTap,
            ),
          ),
        ),
      ],
    );
  }
}

// ── No search results ────────────────────────────────────────────────────────

class _NoSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoSearchResults({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              SolarIconsOutline.magnifier,
              size: 28,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            'No results for "$query"',
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different name, SKU or category',
            style: AppTextStyles.sm300(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear search',
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

class _DesktopProductsSkeleton extends StatelessWidget {
  const _DesktopProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i != 0) const SizedBox(width: AppDims.s3),
                    Expanded(
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppDims.rXl),
                          border: Border.all(color: colors.border),
                        ),
                        padding: const EdgeInsets.all(AppDims.s4),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer(width: 38, height: 38, radius: AppDims.rMd),
                            Spacer(),
                            Shimmer(width: 50, height: 22, radius: 6),
                            SizedBox(height: 8),
                            Shimmer(width: 70, height: 11, radius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppDims.s5),
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i != 0) const SizedBox(width: AppDims.s2),
                      Shimmer(width: 80 + (i * 14.0), height: 36, radius: 999),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDims.s5),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisExtent: 300,
                        crossAxisSpacing: AppDims.s3,
                        mainAxisSpacing: AppDims.s3,
                      ),
                  itemCount: 8,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppDims.rXl),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDims.rXl - 1),
                            ),
                            child: const Shimmer(
                              width: double.infinity,
                              height: double.infinity,
                              radius: 0,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(AppDims.s3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Shimmer(width: 120, height: 14, radius: 4),
                                Shimmer(width: 80, height: 11, radius: 4),
                                Shimmer(width: 60, height: 18, radius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDims.s5),
        SizedBox(
          width: _kSidebarWidth,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i != 0) const SizedBox(height: AppDims.s4),
                Container(
                  height: i == 0 ? 130 : 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppDims.rXl),
                    border: Border.all(color: colors.border),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
