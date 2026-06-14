import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/categories_header.dart';
import 'package:amana_pos/features/category/presentation/widgets/desktop_categories_top_bar.dart';
import 'package:amana_pos/features/category/presentation/widgets/desktop_category_card.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double _kMaxContentWidth = 1800;

/// Desktop layout for the categories screen. Trades the mobile scrollable
/// list for a search top-bar, three clickable stat cards that drive the
/// active filter, and a responsive grid of DesktopCategoryCard tiles —
/// mirrors DesktopProductsView so Categories reads as the same control
/// surface as Products.
class DesktopCategoriesView extends StatefulWidget {
  const DesktopCategoriesView({super.key});

  @override
  State<DesktopCategoriesView> createState() => _DesktopCategoriesViewState();
}

class _DesktopCategoriesViewState extends State<DesktopCategoriesView> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  CategoryQuickFilter _filter = CategoryQuickFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const OnCategoryInitial());
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  void _onFilterChanged(CategoryQuickFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _refresh() async {
    context.read<CategoryBloc>().add(const OnCategoryInitial(force: true));
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            DesktopCategoriesTopBar(
              searchCtrl: _searchCtrl,
              onRefresh: _refresh,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDims.s6),
                    child: BlocBuilder<CategoryBloc, CategoryState>(
                      buildWhen: (prev, curr) =>
                          prev.categoryStatus != curr.categoryStatus ||
                          prev.categoryList != curr.categoryList,
                      builder: (context, state) {
                        return switch (state.categoryStatus) {
                          CategoryStatus.initial ||
                          CategoryStatus.loading =>
                            const _DesktopCategoriesSkeleton(),

                          CategoryStatus.failure =>
                            ProductLoadingView(isGrid: false),

                          CategoryStatus.success => state.categoryList.isEmpty
                              ? ProductEmptyView(
                                  hasCategories: false,
                                  title: context.tr.noCategoriesYet,
                                  message:
                                      'Create your first category to organize products and speed up selling.',
                                  primaryActionText: context.tr.newCategory,
                                  onPrimaryAction: () =>
                                      showAddCategorySheet(context),
                                )
                              : _DesktopCategoriesContent(
                                  categories: state.categoryList,
                                  query: _query,
                                  filter: _filter,
                                  onFilterChanged: _onFilterChanged,
                                  scrollCtrl: _scrollCtrl,
                                  onClearSearch: _searchCtrl.clear,
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

// ── Content ───────────────────────────────────────────────────────────────────

class _DesktopCategoriesContent extends StatelessWidget {
  final List<CategoryData> categories;
  final String query;
  final CategoryQuickFilter filter;
  final ValueChanged<CategoryQuickFilter> onFilterChanged;
  final ScrollController scrollCtrl;
  final VoidCallback onClearSearch;

  const _DesktopCategoriesContent({
    required this.categories,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.scrollCtrl,
    required this.onClearSearch,
  });

  List<CategoryData> get _filtered {
    final byFilter = switch (filter) {
      CategoryQuickFilter.all => categories,
      CategoryQuickFilter.active =>
        categories.where((c) => c.isActive == true).toList(),
      CategoryQuickFilter.inactive =>
        categories.where((c) => c.isActive != true).toList(),
    };

    if (query.isEmpty) return byFilter;

    return byFilter.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final desc = (c.description ?? '').toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;
    final isEmpty = categories.isEmpty;

    return CustomScrollView(
      controller: scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _DesktopCategoriesStatsRow(
            categories: categories,
            selectedFilter: filter,
            onFilterChanged: onFilterChanged,
          ).mAnimate().fadeIn(duration: 280.ms),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppDims.s5)),

        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ProductEmptyView(
              hasCategories: false,
              title: context.tr.noCategoriesYet,
              message:
                  'Create your first category to organize products and speed up selling.',
              primaryActionText: context.tr.newCategory,
              onPrimaryAction: () => showAddCategorySheet(context),
            ),
          )
        else if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResults(query: query, onClear: onClearSearch),
          )
        else
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 440,
              mainAxisExtent: 128,
              crossAxisSpacing: AppDims.s3,
              mainAxisSpacing: AppDims.s3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return RepaintBoundary(
                  child: DesktopCategoryCard(category: visible[index])
                      .mAnimate(delay: (index % 12 * 22).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                );
              },
              childCount: visible.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppDims.s6)),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _DesktopCategoriesStatsRow extends StatelessWidget {
  final List<CategoryData> categories;
  final CategoryQuickFilter selectedFilter;
  final ValueChanged<CategoryQuickFilter> onFilterChanged;

  const _DesktopCategoriesStatsRow({
    required this.categories,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final total = categories.length;
    final active = categories.where((c) => c.isActive == true).length;
    final inactive = total - active;

    final cards = [
      _StatsCardData(
        filter: CategoryQuickFilter.all,
        label: tr.catStatTotal,
        value: total,
        total: total,
        icon: SolarIconsOutline.layersMinimalistic,
        color: colors.primary,
      ),
      _StatsCardData(
        filter: CategoryQuickFilter.active,
        label: tr.catStatActive,
        value: active,
        total: total,
        icon: SolarIconsOutline.checkCircle,
        color: const Color(0xFF16A34A),
      ),
      _StatsCardData(
        filter: CategoryQuickFilter.inactive,
        label: tr.catStatInactive,
        value: inactive,
        total: total,
        icon: SolarIconsOutline.pauseCircle,
        color: const Color(0xFF94A3B8),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i != 0) const SizedBox(width: AppDims.s3),
          Expanded(
            child: _StatsCard(
              data: cards[i],
              isSelected: selectedFilter == cards[i].filter,
              onTap: () => onFilterChanged(cards[i].filter),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsCardData {
  final CategoryQuickFilter filter;
  final String label;
  final int value;
  final int total;
  final IconData icon;
  final Color color;

  const _StatsCardData({
    required this.filter,
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
    required this.color,
  });
}

class _StatsCard extends StatefulWidget {
  final _StatsCardData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatsCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final data = widget.data;
    final selected = widget.isSelected;
    final ratio = data.total == 0 ? 0.0 : data.value / data.total;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: selected ? data.color.withValues(alpha: 0.08) : colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rXl),
            border: Border.all(
              color: selected
                  ? data.color.withValues(alpha: 0.45)
                  : _hovered
                      ? data.color.withValues(alpha: 0.30)
                      : colors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: _hovered || selected
                ? [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                    child: Icon(data.icon, color: data.color, size: 18),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: selected ? 0 : -0.125,
                    child: Icon(
                      SolarIconsBold.altArrowRight,
                      size: 16,
                      color: selected
                          ? data.color
                          : colors.textHint.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDims.s4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${data.value}',
                  style: AppTextStyles.lg100(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: AppTextStyles.sm300(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDims.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: colors.border.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(data.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── No search results ─────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoResults({required this.query, required this.onClear});

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
            'Try a different category name or description',
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

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _DesktopCategoriesSkeleton extends StatelessWidget {
  const _DesktopCategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats row skeleton
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
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
        // Grid skeleton
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 440,
              mainAxisExtent: 128,
              crossAxisSpacing: AppDims.s3,
              mainAxisSpacing: AppDims.s3,
            ),
            itemCount: 9,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDims.rXl),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(AppDims.s4),
              child: Row(
                children: [
                  const Shimmer(width: 56, height: 56, radius: AppDims.rLg),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Shimmer(width: 120, height: 14, radius: 4),
                        SizedBox(height: 8),
                        Shimmer(width: double.infinity, height: 11, radius: 4),
                        SizedBox(height: 5),
                        Shimmer(width: 160, height: 11, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
