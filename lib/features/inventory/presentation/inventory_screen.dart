import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_action_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  bool _isRequestingMore = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const OnInventoryInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<InventoryBloc>().state;

    if (!state.hasMorePages) return;
    if (state.status == InventoryStatus.loading) return;
    if (state.status == InventoryStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (!shouldLoadMore) return;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: RefreshIndicator(
        color: context.appColors.primary,
        onRefresh: _refresh,
        child: NestedScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          headerSliverBuilder: (context, _) => [
            const _InventoryAppBar(),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s2,
              ),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<InventoryBloc, InventoryState>(
                  buildWhen: (prev, curr) =>
                  prev.stockList != curr.stockList ||
                      prev.status != curr.status,
                  builder: (context, state) {
                    return _InventoryHeader(stockList: state.stockList)
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

            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s2,
                AppDims.s4,
                AppDims.s2,
              ),
              sliver: SliverToBoxAdapter(
                child: _InventoryFilterBar(),
              ),
            ),
          ],
          body: BlocBuilder<InventoryBloc, InventoryState>(
            buildWhen: (prev, curr) =>
            prev.status != curr.status ||
                prev.filtered != curr.filtered ||
                prev.filter != curr.filter,
            builder: (context, state) {
              return switch (state.status) {
                InventoryStatus.initial ||
                InventoryStatus.loading => const _LoadingView(),

                InventoryStatus.failure => _ErrorView(
                  message: state.responseError,
                ),

                _ => state.filtered.isEmpty
                    ? _EmptyView(filter: state.filter)
                    : _StockList(
                  items: state.filtered,
                  isLoadingMore:
                  state.status == InventoryStatus.loadingMore,
                ),
              };
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddStockProductSheet(context),
        backgroundColor: context.appColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Stock',
          style: AppTextStyles.bs300(context).copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InventoryAppBar extends StatelessWidget {
  const _InventoryAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: context.appColors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Stock Management',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: context.appColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh stock',
          onPressed: () {
            context.read<InventoryBloc>().add(const OnInventoryInitial());
          },
          icon: Icon(
            Icons.refresh_rounded,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  final List<StockData> stockList;

  const _InventoryHeader({
    required this.stockList,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final total = stockList.length;
    final low = stockList.where((s) => s.isLowStock ?? false).length;
    final out = stockList.where((s) => s.isOutOfStock ?? false).length;
    final healthy = (total - low - out).clamp(0, total);

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
                  Icons.inventory_2_rounded,
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
                      'Inventory Control',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track quantities, low stock alerts, and shop-level stock movements.',
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
                child: _InventoryMiniStat(
                  label: 'Total',
                  value: '$total',
                  icon: Icons.inventory_2_outlined,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Healthy',
                  value: '$healthy',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Low',
                  value: '$low',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _InventoryMiniStat(
                  label: 'Out',
                  value: '$out',
                  icon: Icons.remove_shopping_cart_outlined,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InventoryMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bs300(context).copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: context.appColors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryFilterBar extends StatelessWidget {
  const _InventoryFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      buildWhen: (prev, curr) =>
      prev.stockList != curr.stockList || prev.filter != curr.filter,
      builder: (context, state) {
        final total = state.stockList.length;
        final low = state.stockList.where((s) => s.isLowStock ?? false).length;
        final out =
            state.stockList.where((s) => s.isOutOfStock ?? false).length;

        return Row(
          children: [
            _SummaryChip(
              label: 'All',
              count: total,
              color: context.appColors.primary,
              isSelected: state.filter == StockFilter.all,
              onTap: () {
                context.read<InventoryBloc>().add(
                  const OnInventoryFilterChanged(
                    filter: StockFilter.all,
                  ),
                );
              },
            ),
            const SizedBox(width: AppDims.s2),
            _SummaryChip(
              label: 'Low',
              count: low,
              color: const Color(0xFFEA580C),
              isSelected: state.filter == StockFilter.lowStock,
              onTap: () {
                context.read<InventoryBloc>().add(
                  const OnInventoryFilterChanged(
                    filter: StockFilter.lowStock,
                  ),
                );
              },
            ),
            const SizedBox(width: AppDims.s2),
            _SummaryChip(
              label: 'Out',
              count: out,
              color: const Color(0xFFDC2626),
              isSelected: state.filter == StockFilter.outOfStock,
              onTap: () {
                context.read<InventoryBloc>().add(
                  const OnInventoryFilterChanged(
                    filter: StockFilter.outOfStock,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: AppDims.s2,
            horizontal: AppDims.s2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.10) : colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : colors.border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.bs200(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, __) => const _StockSkeleton(),
    );
  }
}

class _StockSkeleton extends StatelessWidget {
  const _StockSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: [
          const _Shimmer(width: 54, height: 54, radius: AppDims.rMd),
          const SizedBox(width: AppDims.s3),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 150, height: 13, radius: 4),
                SizedBox(height: 7),
                _Shimmer(width: 100, height: 11, radius: 4),
                SizedBox(height: 7),
                _Shimmer(width: 70, height: 18, radius: 999),
              ],
            ),
          ),
          const _Shimmer(width: 50, height: 42, radius: AppDims.rSm),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final StockFilter filter;

  const _EmptyView({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = switch (filter) {
      StockFilter.all => 'No stock entries yet',
      StockFilter.lowStock => 'No low stock items',
      StockFilter.outOfStock => 'No out of stock items',
    };

    final message = switch (filter) {
      StockFilter.all =>
      'Add stock for your products to start tracking inventory.',
      StockFilter.lowStock =>
      'Everything looks good. No products are currently low on stock.',
      StockFilter.outOfStock =>
      'Great. No products are currently out of stock.',
    };

    final icon = switch (filter) {
      StockFilter.all => Icons.inventory_2_outlined,
      StockFilter.lowStock => Icons.check_circle_outline_rounded,
      StockFilter.outOfStock => Icons.check_circle_outline_rounded,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (filter == StockFilter.all) ...[
              const SizedBox(height: AppDims.s4),
              FilledButton.icon(
                onPressed: () => showAddStockProductSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Stock'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;

  const _ErrorView({
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              'Something went wrong',
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDims.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs200(context).copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: () {
                context.read<InventoryBloc>().add(const OnInventoryInitial());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  final List<StockData> items;
  final bool isLoadingMore;

  const _StockList({
    required this.items,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s4,
            AppDims.s4,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
            itemBuilder: (_, i) {
              return _StockCard(item: items[i])
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 40 + (i % 8) * 25),
                duration: 240.ms,
              )
                  .slideY(
                begin: 0.04,
                end: 0,
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(child: _LoadMoreIndicator()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockData item;

  const _StockCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isOut = item.isOutOfStock ?? false;
    final isLow = item.isLowStock ?? false;
    final qty = item.qty;

    final statusColor = isOut
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final statusLabel = isOut
        ? 'Out of stock'
        : isLow
        ? 'Low stock'
        : 'In stock';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          final allStock = context.read<InventoryBloc>().state.stockList;

          showStockActionSheet(
            context,
            stock: item,
            allStock: allStock,
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  isOut
                      ? Icons.remove_shopping_cart_outlined
                      : isLow
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  size: 25,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: colors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.shopName ?? 'Shop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs200(context).copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.productSku?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        'SKU: ${item.productSku!.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs100(context).copyWith(
                          color: colors.textHint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDims.s2),
                    _StatusBadge(
                      label: statusLabel,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatQty(qty),
                    style: AppTextStyles.bs600(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Qty',
                    style: AppTextStyles.bs100(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textHint,
                    ),
                  ),
                  const SizedBox(height: AppDims.s3),
                  Icon(
                    Icons.tune_rounded,
                    color: colors.textHint,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.appColors.primary,
          ),
        ),
      ),
    );
  }
}