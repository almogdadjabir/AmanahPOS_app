import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_form_screen.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_states.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/products/presentation/product_form_screen.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_row.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _MenuAction { edit, delete }

class CategoryDetailScreen extends StatefulWidget {
  final CategoryData category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  bool _isGrid = false;
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

  Future<void> _refresh() async {
    final bloc = context.read<CategoryBloc>()
      ..add(const OnCategoriesSyncRequested());
    _loadCategoryProducts();
    try {
      // A local re-read (SQLite); an unchanged list emits nothing.
      await bloc.stream
          .firstWhere(
            (s) =>
                s.productsStatus == CategoryProductsStatus.failure ||
                s.productsStatus == CategoryProductsStatus.success,
          )
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // Timed out: cached products stay on screen.
    }
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
    if (position.pixels < position.maxScrollExtent - 260) return;

    _isRequestingMore = true;

    context.read<CategoryBloc>().add(
      OnLoadMoreCategoryProducts(categoryId: categoryId),
    );

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  void _addProduct(CategoryData category) {
    openProductForm(context, initialCategory: category);
  }

  void _onMenu(_MenuAction action, CategoryData category) {
    switch (action) {
      case _MenuAction.edit:
        openCategoryForm(context, category: category, fromDetail: true);
      case _MenuAction.delete:
        confirmDeleteCategory(context, category).then((deleted) {
          if (deleted && mounted) Navigator.of(context).maybePop();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final isRestaurant = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.isRestaurant,
    );
    final canEdit = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canEditCatalog,
    );

    final category =
        context.select<CategoryBloc, CategoryData?>((bloc) {
          for (final item in bloc.state.categoryList) {
            if (item.id == widget.category.id) return item;
          }
          return null;
        }) ??
        widget.category;

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == ProductSubmitStatus.success) {
          _loadCategoryProducts();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _NavBar(
                backLabel: tr.fbCategoriesTitle,
                isGrid: _isGrid,
                onToggleLayout: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isGrid = !_isGrid);
                },
                // Catalog writes are owner/manager only.
                onAdd: canEdit ? () => _addProduct(category) : null,
                onMenu: canEdit ? (a) => _onMenu(a, category) : null,
              ),
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  buildWhen: (prev, curr) =>
                      prev.productsStatus != curr.productsStatus ||
                      prev.products != curr.products ||
                      prev.hasMorePages != curr.hasMorePages ||
                      prev.productSyncMarks != curr.productSyncMarks ||
                      prev.productsFromCache != curr.productsFromCache,
                  builder: (context, state) => CustomScrollView(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      CupertinoSliverRefreshControl(onRefresh: _refresh),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppDims.s4,
                          0,
                          AppDims.s4,
                          MediaQuery.viewPaddingOf(context).bottom + 24,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _content(
                            context,
                            state,
                            category,
                            isRestaurant,
                            canEdit,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    CategoryState state,
    CategoryData category,
    bool isRestaurant,
    bool canEdit,
  ) {
    final tr = context.tr;
    final colors = context.appColors;

    final name = category.name?.trim();
    final description = category.description?.trim();
    final loaded = state.products.length;
    final count =
        category.productCount ??
        (state.productsStatus == CategoryProductsStatus.success &&
                !state.hasMorePages
            ? loaded
            : null);

    final subtitleParts = <String>[
      if (description?.isNotEmpty == true) description!,
      if (count != null) tr.pcCount('$count'),
    ];

    final title = AppLargeTitle(
      title: name?.isNotEmpty == true ? name! : tr.category,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
    );

    final loading =
        state.productsStatus == CategoryProductsStatus.initial ||
        state.productsStatus == CategoryProductsStatus.loading;

    final Widget body;
    if (loading) {
      body = const CategorySkeleton(rows: 5);
    } else if (state.productsStatus == CategoryProductsStatus.failure &&
        state.products.isEmpty) {
      body = CategoryStateCard(
        icon: PhosphorIconsRegular.wifiSlash,
        tone: CategoryStateTone.danger,
        title: tr.pcErrorTitle,
        body: state.productsError ?? tr.pcErrorBody,
        actionLabel: tr.retry,
        secondaryAction: true,
        onAction: _loadCategoryProducts,
      );
    } else if (state.products.isEmpty) {
      body = CategoryStateCard(
        icon: PhosphorIconsRegular.package,
        title: tr.ctNoProducts,
        body: tr.ctNoProductsBody,
        actionLabel: canEdit ? tr.pcAddProduct : null,
        onAction: canEdit ? () => _addProduct(category) : null,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.productsFromCache)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.wifiSlash,
                    size: 16,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr.pcShowingSaved,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.warning,
                    ),
                  ),
                ],
              ),
            ),
          if (_isGrid)
            _Grid(
              products: state.products,
              isRestaurant: isRestaurant,
              syncMarks: state.productSyncMarks,
            )
          else
            ProductListGroup(
              products: state.products,
              isRestaurant: isRestaurant,
              showCategory: false,
              syncMarks: state.productSyncMarks,
            ),
          if (state.productsStatus == CategoryProductsStatus.loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDims.s5),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [title, body],
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
      itemBuilder: (context, i) => ProductGridTile(
        product: products[i],
        isRestaurant: isRestaurant,
        syncMark: syncMarks.markOf(products[i].id),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final String backLabel;
  final bool isGrid;
  final VoidCallback onToggleLayout;

  /// Null hides the add-product button and the edit/delete menu (cashier).
  final VoidCallback? onAdd;
  final ValueChanged<_MenuAction>? onMenu;

  const _NavBar({
    required this.backLabel,
    required this.isGrid,
    required this.onToggleLayout,
    required this.onAdd,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    Widget iconButton(IconData icon, VoidCallback onTap, {double size = 22}) {
      return Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: size, color: colors.primary),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      backLabel,
                      style: TextStyle(fontSize: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            iconButton(
              isGrid
                  ? PhosphorIconsRegular.list
                  : PhosphorIconsRegular.squaresFour,
              onToggleLayout,
            ),
            if (onAdd != null)
              iconButton(PhosphorIconsRegular.plus, onAdd!, size: 26),
            if (onMenu != null)
              PopupMenuButton<_MenuAction>(
                tooltip: tr.moreActions,
                position: PopupMenuPosition.under,
                color: colors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 8,
                shadowColor: colors.shadow,
                constraints: const BoxConstraints(minWidth: 246),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.border),
                ),
                onOpened: () => HapticFeedback.selectionClick(),
                onSelected: onMenu!,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MenuAction.edit,
                    height: 46,
                    child: _MenuRow(
                      label: tr.pfEditCategory,
                      icon: PhosphorIconsRegular.pencilSimple,
                      color: colors.textPrimary,
                    ),
                  ),
                  const PopupMenuDivider(height: 0.5),
                  PopupMenuItem(
                    value: _MenuAction.delete,
                    height: 46,
                    child: _MenuRow(
                      label: tr.ctDelete,
                      icon: PhosphorIconsRegular.trash,
                      color: colors.danger,
                    ),
                  ),
                ],
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    PhosphorIconsRegular.dotsThree,
                    size: 24,
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

class _MenuRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MenuRow({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 17, color: color)),
        ),
        Icon(icon, size: 20, color: color),
      ],
    );
  }
}
