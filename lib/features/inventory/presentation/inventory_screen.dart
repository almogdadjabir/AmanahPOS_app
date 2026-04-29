import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const OnInventoryInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<InventoryBloc>().add(const OnLoadMoreStock());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, _) => [
          _InventoryAppBar(),
          // ── Sticky summary + filter bar ──────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(),
          ),
        ],
        body: BlocBuilder<InventoryBloc, InventoryState>(
          buildWhen: (prev, curr) =>
          prev.status != curr.status ||
              prev.filtered != curr.filtered,
          builder: (context, state) {
            return switch (state.status) {
              InventoryStatus.initial ||
              InventoryStatus.loading => const _LoadingView(),
              InventoryStatus.failure  => _ErrorView(
                  message: state.responseError),
              _ => state.filtered.isEmpty
                  ? const _EmptyView()
                  : _StockList(
                items:         state.filtered,
                isLoadingMore: state.status ==
                    InventoryStatus.loadingMore,
              ),
            };
          },
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _InventoryAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      backgroundColor: context.appColors.surface,
      title: Text(
        'Stock Control',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w800,
          color: context.appColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context
              .read<InventoryBloc>()
              .add(const OnInventoryInitial()),
          icon: Icon(Icons.refresh_rounded,
              color: context.appColors.textPrimary),
        ),
      ],
    );
  }
}

// ─── Sticky filter bar ────────────────────────────────────────────────────────

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  @override double get minExtent => 112;
  @override double get maxExtent => 112;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.appColors.background,
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s3, AppDims.s4, 0),
      child: BlocBuilder<InventoryBloc, InventoryState>(
        buildWhen: (prev, curr) =>
        prev.stockList != curr.stockList ||
            prev.filter != curr.filter,
        builder: (context, state) {
          final total    = state.stockList.length;
          final lowStock = state.stockList
              .where((s) => s.isLowStock ?? false).length;
          final outOf    = state.stockList
              .where((s) => s.isOutOfStock ?? false).length;

          return Column(
            children: [
              // ── Summary chips ────────────────────────────────────────
              Row(
                children: [
                  _SummaryChip(
                    label: 'Total',
                    count: total,
                    color: context.appColors.primary,
                    bgColor: context.appColors.primaryContainer,
                    isSelected: state.filter == StockFilter.all,
                    onTap: () => context.read<InventoryBloc>().add(
                        const OnInventoryFilterChanged(
                            filter: StockFilter.all)),
                  ),
                  const SizedBox(width: AppDims.s2),
                  _SummaryChip(
                    label: 'Low Stock',
                    count: lowStock,
                    color: const Color(0xFFEA580C),
                    bgColor: const Color(0xFFEA580C).withOpacity(0.10),
                    isSelected: state.filter == StockFilter.lowStock,
                    onTap: () => context.read<InventoryBloc>().add(
                        const OnInventoryFilterChanged(
                            filter: StockFilter.lowStock)),
                  ),
                  const SizedBox(width: AppDims.s2),
                  _SummaryChip(
                    label: 'Out of Stock',
                    count: outOf,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFDC2626).withOpacity(0.10),
                    isSelected: state.filter == StockFilter.outOfStock,
                    onTap: () => context.read<InventoryBloc>().add(
                        const OnInventoryFilterChanged(
                            filter: StockFilter.outOfStock)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate _) => false;
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
              vertical: AppDims.s2, horizontal: AppDims.s2),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : context.appColors.surface,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: isSelected ? color : context.appColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : context.appColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : context.appColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, __) => _StockSkeleton(),
    );
  }
}

class _StockSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: [
          _Shimmer(width: 44, height: 44, radius: AppDims.rSm),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 150, height: 13, radius: 4),
                const SizedBox(height: 7),
                _Shimmer(width: 90, height: 11, radius: 4),
              ],
            ),
          ),
          _Shimmer(width: 50, height: 32, radius: AppDims.rSm),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: context.appColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ─── Empty ────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: context.appColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 36, color: context.appColors.primary),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            'No stock entries',
            style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            'Add products and assign stock to see them here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bs300(context).copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String? message;
  const _ErrorView({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: context.appColors.textHint),
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
            Text(message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs200(context).copyWith(
                    color: context.appColors.textSecondary)),
          ],
          const SizedBox(height: AppDims.s4),
          OutlinedButton.icon(
            onPressed: () => context
                .read<InventoryBloc>()
                .add(const OnInventoryInitial()),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Stock list ───────────────────────────────────────────────────────────────

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
              AppDims.s4, AppDims.s4, AppDims.s4, 0),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppDims.s3),
            itemBuilder: (_, i) => _StockCard(item: items[i]),
          ),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(child: _LoadMoreIndicator()),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockData item;
  const _StockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isOut  = item.isOutOfStock ?? false;
    final isLow  = item.isLowStock   ?? false;
    final qty    = item.qty;

    final statusColor = isOut
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final statusBg = isOut
        ? const Color(0xFFDC2626).withOpacity(0.10)
        : isLow
        ? const Color(0xFFEA580C).withOpacity(0.10)
        : const Color(0xFF22C55E).withOpacity(0.10);

    final statusLabel = isOut ? 'Out' : isLow ? 'Low' : 'OK';

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () {}, // TODO: stock detail / adjust
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              // ── Icon ────────────────────────────────────────────────
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(
                  isOut
                      ? Icons.remove_shopping_cart_outlined
                      : Icons.inventory_2_outlined,
                  size: 20, color: statusColor,
                ),
              ),
              const SizedBox(width: AppDims.s3),

              // ── Info ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 11,
                            color: context.appColors.textHint),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            item.shopName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs200(context).copyWith(
                              color: context.appColors.textHint,
                            ),
                          ),
                        ),
                        if (item.productSku != null &&
                            item.productSku!.isNotEmpty) ...[
                          const SizedBox(width: AppDims.s2),
                          Text(
                            'SKU: ${item.productSku}',
                            style: AppTextStyles.bs200(context).copyWith(
                              color: context.appColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Qty + status ──────────────────────────────────────────
              const SizedBox(width: AppDims.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    qty % 1 == 0
                        ? qty.toInt().toString()
                        : qty.toStringAsFixed(2),
                    style: AppTextStyles.bs500(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          width: 22, height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.appColors.primary,
          ),
        ),
      ),
    );
  }
}