import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/features/inventory/presentation/update_stock_screen.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/product_form_screen.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_delete.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_format.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_row.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_filter_bar.dart';
import 'package:amana_pos/features/products/presentation/widgets/products_states.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_search_field.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsScreen extends StatefulWidget {
  final bool isWithAppbar;
  const ProductsScreen({super.key, this.isWithAppbar = false});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  Timer? _loadMoreDebounce;
  bool _initialized = false;
  bool _isRequestingMore = false;

  bool _lowOn = false;
  bool _outOn = false;
  bool _inactiveOn = false;

  bool get _queryActive => _searchCtrl.text.trim().isNotEmpty || _inactiveOn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    context.read<ProductBloc>().add(const OnProductInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadMoreDebounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---- loading -----------------------------------------------------------

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_queryActive) return;

    final state = context.read<ProductBloc>().state;
    if (state.products.isEmpty || !state.hasMorePages) return;
    if (state.productStatus == ProductStatus.loading ||
        state.productStatus == ProductStatus.loadingMore ||
        state.loadingAll) {
      return;
    }
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    if (position.pixels < position.maxScrollExtent - 260) return;

    _isRequestingMore = true;
    context.read<ProductBloc>().add(const OnLoadMoreProducts());

    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    final bloc = context.read<ProductBloc>()
      ..add(const OnProductInitial(force: true))
      ..add(const OnProductsSyncRequested());
    _dispatchQuery();
    // A local re-read (SQLite); an unchanged list emits nothing, so wait
    // briefly at most.
    await bloc.stream
        .firstWhere((s) => s.productStatus != ProductStatus.loading)
        .timeout(const Duration(seconds: 1), onTimeout: () => bloc.state);
  }

  // ---- query + filters ---------------------------------------------------

  void _dispatchQuery() {
    context.read<ProductBloc>().add(
      OnProductQuery(search: _searchCtrl.text, inactiveOnly: _inactiveOn),
    );
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _dispatchQuery);
  }

  void _toggleLow() {
    setState(() => _lowOn = !_lowOn);
    if (_lowOn) context.read<ProductBloc>().add(const OnProductsLoadAll());
  }

  void _toggleOut() {
    setState(() => _outOn = !_outOn);
    if (_outOn) context.read<ProductBloc>().add(const OnProductsLoadAll());
  }

  void _toggleInactive() {
    setState(() => _inactiveOn = !_inactiveOn);
    _dispatchQuery();
  }

  Future<void> _pickCategory() async {
    final bloc = context.read<ProductBloc>();
    final picked = await showProductCategorySheet(
      context,
      categories: bloc.state.categories,
      selectedId: bloc.state.selectedCategoryId,
    );
    if (picked == null || !mounted) return;
    bloc.add(
      OnProductCategorySelected(categoryId: picked.isEmpty ? null : picked),
    );
  }

  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).pushNamed<String>(RouteStrings.barcodeScannerScreen);
    if (!mounted || code == null || code.trim().isEmpty) return;
    _searchCtrl.text = code.trim();
    _searchCtrl.selection = TextSelection.collapsed(
      offset: _searchCtrl.text.length,
    );
    setState(() {});
    _searchDebounce?.cancel();
    _dispatchQuery();
  }

  // ---- derived -----------------------------------------------------------

  List<ProductData> _visible(ProductState state, {required bool isRestaurant}) {
    final base = _queryActive ? state.queryResults : state.products;
    if (isRestaurant || (!_lowOn && !_outOn)) return base;

    return base
        .where((p) {
          final level = productStockLevel(p, isRestaurant: false);
          return (_lowOn && level == ProductStockLevel.low) ||
              (_outOn && level == ProductStockLevel.out);
        })
        .toList(growable: false);
  }

  ProductsFilterState _filters(
    ProductState state, {
    required bool isRestaurant,
  }) {
    var low = 0;
    var out = 0;
    if (!isRestaurant) {
      for (final p in state.products) {
        final level = productStockLevel(p, isRestaurant: false);
        if (level == ProductStockLevel.low) low++;
        if (level == ProductStockLevel.out) out++;
      }
    }

    String? categoryName;
    final selected = state.selectedCategoryId;
    if (selected != null) {
      for (final c in state.categories) {
        if (c.id == selected) {
          final n = c.name?.trim();
          categoryName = (n != null && n.isNotEmpty) ? n : context.tr.category;
          break;
        }
      }
      categoryName ??= context.tr.category;
    }

    return ProductsFilterState(
      categoryName: categoryName,
      lowOn: _lowOn,
      outOn: _outOn,
      inactiveOn: _inactiveOn,
      lowCount: low,
      outCount: out,
      countsPartial: state.hasMorePages,
      showStockChips: !isRestaurant,
    );
  }

  List<AppSwipeAction> _swipeActions(
    ProductData product, {
    required bool isRestaurant,
    required bool canEditCatalog,
  }) {
    final colors = context.appColors;
    final tr = context.tr;
    return [
      if (!isRestaurant && product.trackInventory != false)
        AppSwipeAction(
          label: tr.pcSwipeStock,
          icon: PhosphorIconsRegular.package,
          color: colors.primary,
          onTap: () => openUpdateStock(context, product: product),
        ),
      // Catalog writes are owner/manager only (BE `forbidden` otherwise).
      if (canEditCatalog)
        AppSwipeAction(
        label: tr.delete,
        icon: PhosphorIconsRegular.trash,
        color: colors.danger,
        onTap: () async {
          final deleted = await confirmDeleteProduct(context, product);
          if (deleted && mounted && _queryActive) _dispatchQuery();
        },
      ),
    ];
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isRestaurant = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.isRestaurant,
    );
    final canEditCatalog = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canEditCatalog,
    );
    final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bottomInset = widget.isWithAppbar
        ? viewBottom + 24
        : NavShell.contentHeight + viewBottom + 20;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(
              showBack: widget.isWithAppbar,
              onAdd: canEditCatalog ? () => openProductForm(context) : null,
            ),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (prev, curr) =>
                    prev.productStatus != curr.productStatus ||
                    prev.products != curr.products ||
                    prev.categories != curr.categories ||
                    prev.selectedCategoryId != curr.selectedCategoryId ||
                    prev.isGrid != curr.isGrid ||
                    prev.hasMorePages != curr.hasMorePages ||
                    prev.queryStatus != curr.queryStatus ||
                    prev.queryResults != curr.queryResults ||
                    prev.loadingAll != curr.loadingAll ||
                    prev.syncMarks != curr.syncMarks,
                builder: (context, state) => _body(
                  context,
                  state,
                  isRestaurant,
                  bottomInset,
                  canEditCatalog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ProductState state,
    bool isRestaurant,
    double bottomInset,
    bool canEditCatalog,
  ) {
    final tr = context.tr;
    final colors = context.appColors;
    final filtersActive =
        _lowOn || _outOn || _inactiveOn || state.selectedCategoryId != null;

    final queryLoading =
        _queryActive && state.queryStatus == ProductQueryStatus.loading;
    final initialLoading =
        !_queryActive &&
        state.products.isEmpty &&
        (state.productStatus == ProductStatus.initial ||
            state.productStatus == ProductStatus.loading);
    final failed =
        !_queryActive &&
        state.products.isEmpty &&
        state.productStatus == ProductStatus.failure;
    final catalogEmpty =
        !_queryActive &&
        state.products.isEmpty &&
        state.productStatus == ProductStatus.success &&
        !filtersActive;

    final visible = _visible(state, isRestaurant: isRestaurant);
    final loadingMore =
        state.productStatus == ProductStatus.loadingMore || state.loadingAll;

    final Widget content;
    if (initialLoading || queryLoading) {
      content = ProductsSkeleton(grid: state.isGrid);
    } else if (failed) {
      content = ProductsStateCard(
        icon: PhosphorIconsRegular.wifiSlash,
        tone: ProductsStateTone.danger,
        title: tr.pcErrorTitle,
        body: state.responseError ?? tr.pcErrorBody,
        actionLabel: tr.retry,
        onAction: () => context.read<ProductBloc>().add(
          const OnProductInitial(force: true),
        ),
      );
    } else if (catalogEmpty) {
      content = ProductsStateCard(
        icon: PhosphorIconsRegular.package,
        title: tr.noProductsYet,
        body: tr.pcEmptyBody,
        actionLabel: canEditCatalog ? tr.pcAddProduct : null,
        onAction: canEditCatalog ? () => openProductForm(context) : null,
      );
    } else if (visible.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Text(
              tr.pcNoMatches,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              tr.pcNoMatchesBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    } else if (state.isGrid) {
      content = _Grid(
        products: visible,
        isRestaurant: isRestaurant,
        syncMarks: state.syncMarks,
      );
    } else {
      content = ProductListGroup(
        products: visible,
        isRestaurant: isRestaurant,
        syncMarks: state.syncMarks,
        swipeActions: (p) => _swipeActions(
          p,
          isRestaurant: isRestaurant,
          canEditCatalog: canEditCatalog,
        ),
      );
    }

    final showControls = !catalogEmpty && !failed;
    final subtitle = (state.products.isEmpty || catalogEmpty)
        ? null
        : tr.pcCount(
            state.hasMorePages
                ? '${state.products.length}+'
                : '${state.products.length}',
          );

    return CustomScrollView(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          sliver: SliverToBoxAdapter(
            child: AppLargeTitle(title: tr.navProducts, subtitle: subtitle),
          ),
        ),
        if (showControls) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            sliver: SliverToBoxAdapter(
              child: AppSearchField(
                controller: _searchCtrl,
                hint: tr.pcSearchHint,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  _searchDebounce?.cancel();
                  _dispatchQuery();
                },
                actionIcon: PhosphorIconsRegular.scan,
                onAction: _scan,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: ProductsFilterHeaderDelegate(
              background: colors.background,
              child: ProductsFilterBar(
                filters: _filters(state, isRestaurant: isRestaurant),
                onCategory: _pickCategory,
                onLow: _toggleLow,
                onOut: _toggleOut,
                onInactive: _toggleInactive,
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppDims.s4,
            showControls ? 2 : AppDims.s2,
            AppDims.s4,
            bottomInset,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                content,
                if (loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDims.s5),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool showBack;

  /// Null hides the add button (cashier).
  final VoidCallback? onAdd;

  const _NavBar({required this.showBack, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (showBack)
              Pressable(
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: DirectionalIcon(
                    icon: PhosphorIconsRegular.caretLeft,
                    size: 24,
                    color: colors.primary,
                  ),
                ),
              ),
            const Spacer(),
            BlocSelector<ProductBloc, ProductState, bool>(
              selector: (s) => s.isGrid,
              builder: (context, isGrid) => Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<ProductBloc>().add(
                    const OnToggleProductLayout(),
                  );
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    isGrid
                        ? PhosphorIconsRegular.list
                        : PhosphorIconsRegular.squaresFour,
                    size: 22,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
            if (onAdd != null)
              Pressable(
                key: const ValueKey('products-add'),
                onTap: onAdd,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    PhosphorIconsRegular.plus,
                    size: 26,
                    color: colors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<ProductData> products;
  final bool isRestaurant;
  final CatalogSyncMarks syncMarks;

  const _Grid({
    required this.products,
    required this.isRestaurant,
    required this.syncMarks,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - AppDims.s4 * 2;
    final tile = (width - AppDims.s3) / 2;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final extent = (tile - 20) / 1.25 + 116 * scale;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDims.s3,
        mainAxisSpacing: AppDims.s3,
        mainAxisExtent: extent,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductGridTile(
        key: ValueKey(products[i].id ?? i),
        product: products[i],
        isRestaurant: isRestaurant,
        syncMark: syncMarks.markOf(products[i].id),
      ),
    );
  }
}
