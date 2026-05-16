import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_app_bar.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_empty_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_error_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_header.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_loading_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inbound_receiving_sheet.dart';
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
                    return InventoryHeader(
                      stockList: state.stockList,
                      selectedFilter: state.filter,
                      onFilterChanged: (filter) {
                        context.read<InventoryBloc>().add(
                          OnInventoryFilterChanged(filter: filter),
                        );

                        if (_scrollCtrl.hasClients) {
                          _scrollCtrl.animateTo(
                            0,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
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

            if (context.select<AuthBloc, bool>((bloc) => bloc.state.permissions.canSeeInboundPremiumCard))
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4, 0, AppDims.s4, AppDims.s2),
                sliver: SliverToBoxAdapter(
                  child: _InboundPremiumLockedBanner(),
                ),
              ),

            if (context.select<AuthBloc, bool>((bloc) => bloc.state.permissions.canUseInventoryInboundReceiving))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4, 0, AppDims.s4, AppDims.s2),
                sliver: SliverToBoxAdapter(
                  child: _InboundReceivingBanner(
                    onTap: () => showInboundReceivingSheet(context),
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
      floatingActionButton: _InventoryFab(
        onAddStock: () => showAddStockProductSheet(context),
        onInbound: () => showInboundReceivingSheet(context),
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

class _InventoryFab extends StatelessWidget {
  final VoidCallback onAddStock;
  final VoidCallback onInbound;

  const _InventoryFab({
    required this.onAddStock,
    required this.onInbound,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canUseInbound = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.permissions.canUseInventoryInboundReceiving,
    );

    if (!canUseInbound) {
      return FloatingActionButton.extended(
        onPressed: onAddStock,
        backgroundColor: colors.primary,
        icon: const Icon(SolarIconsOutline.addCircle, color: Colors.white),
        label: Text(
          'Add Stock',
          style: AppTextStyles.bs300(context).copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'inbound_fab',
          onPressed: onInbound,
          backgroundColor: colors.primary,
          icon: const Icon(SolarIconsOutline.box, color: Colors.white),
          label: Text(
            'Inbound',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppDims.s2),
        FloatingActionButton.extended(
          heroTag: 'add_stock_fab',
          onPressed: onAddStock,
          backgroundColor: colors.surface,
          foregroundColor: colors.primary,
          icon: Icon(SolarIconsOutline.addCircle, color: colors.primary),
          label: Text(
            'Add Stock',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InboundReceivingBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _InboundReceivingBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(SolarIconsOutline.box, color: colors.primary, size: 24),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbound Receiving',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Receive supplier stock using one shared reference.',
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
              Icon(SolarIconsOutline.altArrowRight, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboundPremiumLockedBanner extends StatelessWidget {
  const _InboundPremiumLockedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const premium = Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: premium.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: premium.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: premium.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: const Icon(SolarIconsOutline.lock, color: premium, size: 24),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inbound Receiving is premium',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable it for businesses that need advanced stock receiving.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
