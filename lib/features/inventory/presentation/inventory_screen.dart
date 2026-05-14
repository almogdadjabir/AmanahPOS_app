import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_app_bar.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_empty_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_error_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_filter_bar.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_header.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_loading_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

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
      body: RefreshIndicator(
        color: context.appColors.primary,
        onRefresh: _refresh,
        child: NestedScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          headerSliverBuilder: (context, _) => [
            const InventoryAppBar(),

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
                    return InventoryHeader(stockList: state.stockList)
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

            // Expiry alerts entry — shop only, never shown for restaurant.
            if (context.read<AuthBloc>().state.permissions.isShop)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4, 0, AppDims.s4, AppDims.s2),
                sliver: SliverToBoxAdapter(
                  child: _ExpiryAlertsBanner(),
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
                child: InventoryFilterBar(),
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
                InventoryStatus.loading => const InventoryLoadingView(),

                InventoryStatus.failure => InventoryErrorView(
                  message: state.responseError,
                ),

                _ => state.filtered.isEmpty
                    ? InventoryEmptyView(filter: state.filter)
                    : StockList(
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

class _ExpiryAlertsBanner extends StatelessWidget {
  const _ExpiryAlertsBanner();

  static const Color _alertColor = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(RouteStrings.expiryAlertsScreen);
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: _alertColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: _alertColor.withValues(alpha: 0.22),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _alertColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                  border: Border.all(
                    color: _alertColor.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  SolarIconsOutline.dangerTriangle,
                  color: _alertColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expiry Alerts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review expired and soon-to-expire stock items.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s3),

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _alertColor.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  SolarIconsOutline.altArrowRight,
                  color: _alertColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}