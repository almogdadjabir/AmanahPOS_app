import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/desktop_inventory_sidebar.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/desktop_inventory_stats_row.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/desktop_inventory_top_bar.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/desktop_stock_card.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_empty_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_error_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double _kSidebarWidth = 320;
const double _kMaxContentWidth = 1800;

/// Desktop layout for the standard (non-premium) inventory screen.
///
/// Trades the mobile single-column list for a control-room composition:
/// a search/add top bar, four clickable overview cards that double as
/// filters, a responsive stock grid with infinite scroll, and a fixed
/// sidebar surfacing low-stock and expiry triage at a glance.
class DesktopInventoryView extends StatefulWidget {
  const DesktopInventoryView({super.key});

  @override
  State<DesktopInventoryView> createState() => _DesktopInventoryViewState();
}

class _DesktopInventoryViewState extends State<DesktopInventoryView> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isRequestingMore = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const OnInventoryInitial());
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<InventoryBloc>().state;
    if (!state.hasMorePages) return;
    if (state.status == InventoryStatus.loading) return;
    if (state.status == InventoryStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent - 320) return;

    _isRequestingMore = true;
    context.read<InventoryBloc>().add(const OnLoadMoreStock());
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refresh() async {
    context.read<InventoryBloc>().add(const OnInventoryInitial());
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isShop = context.read<AuthBloc>().state.permissions.isShop;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            DesktopInventoryTopBar(
              searchCtrl: _searchCtrl,
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
                    child: BlocBuilder<InventoryBloc, InventoryState>(
                      builder: (context, state) {
                        return switch (state.status) {
                          InventoryStatus.initial ||
                          InventoryStatus.loading => const _DesktopInventorySkeleton(),

                          InventoryStatus.failure => InventoryErrorView(
                            message: state.responseError,
                          ),

                          _ => _DesktopInventoryContent(
                            state: state,
                            query: _query,
                            scrollCtrl: _scrollCtrl,
                            isShop: isShop,
                            onAddStock: () => showAddStockProductSheet(context),
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

// ── Content ────────────────────────────────────────────────────────────────

class _DesktopInventoryContent extends StatelessWidget {
  final InventoryState state;
  final String query;
  final ScrollController scrollCtrl;
  final bool isShop;
  final VoidCallback onAddStock;
  final VoidCallback onClearSearch;

  const _DesktopInventoryContent({
    required this.state,
    required this.query,
    required this.scrollCtrl,
    required this.isShop,
    required this.onAddStock,
    required this.onClearSearch,
  });

  List<StockData> _applySearch(List<StockData> items) {
    if (query.isEmpty) return items;
    return items.where((s) {
      final name = (s.productName ?? '').toLowerCase();
      final sku = (s.productSku ?? '').toLowerCase();
      final shop = (s.shopName ?? '').toLowerCase();
      return name.contains(query) ||
          sku.contains(query) ||
          shop.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = state.filtered;
    final visible = _applySearch(filtered);
    final isLoadingMore = state.status == InventoryStatus.loadingMore;

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
                child: DesktopInventoryStatsRow(
                  stockList: state.stockList,
                  selectedFilter: state.filter,
                  onFilterChanged: (filter) {
                    context.read<InventoryBloc>().add(
                      OnInventoryFilterChanged(filter: filter),
                    );
                    if (scrollCtrl.hasClients) {
                      scrollCtrl.animateTo(
                        0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ).mAnimate().fadeIn(duration: 280.ms),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDims.s5),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: InventoryEmptyView(filter: state.filter),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoSearchResults(
                    query: query,
                    onClear: onClearSearch,
                  ),
                )
              else
                SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisExtent: 240,
                        crossAxisSpacing: AppDims.s3,
                        mainAxisSpacing: AppDims.s3,
                      ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = visible[index];
                    return DesktopStockCard(item: item)
                        .mAnimate(delay: (index % 12 * 25).ms)
                        .fadeIn(duration: 240.ms)
                        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
                  }, childCount: visible.length),
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
            child: DesktopInventorySidebar(
              stockList: state.stockList,
              isShop: isShop,
              onAddStock: onAddStock,
            ),
          ),
        ),
      ],
    );
  }
}

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
            'Try a different product, SKU or shop name',
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

class _DesktopInventorySkeleton extends StatelessWidget {
  const _DesktopInventorySkeleton();

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
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisExtent: 240,
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
                    padding: const EdgeInsets.all(AppDims.s4),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer(width: 44, height: 44, radius: AppDims.rMd),
                        SizedBox(height: AppDims.s3),
                        Shimmer(width: 140, height: 14, radius: 4),
                        SizedBox(height: 8),
                        Shimmer(width: 90, height: 11, radius: 4),
                        Spacer(),
                        Shimmer(width: 60, height: 22, radius: 6),
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
                  height: i == 0 ? 150 : 200,
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
