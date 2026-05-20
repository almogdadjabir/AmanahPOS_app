import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/expiry_alert_row.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_app_bar.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_empty_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_error_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_header.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/inventory_loading_view.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/stock_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BasicInventoryView extends StatefulWidget {
  const BasicInventoryView({super.key});

  @override
  State<BasicInventoryView> createState() => _BasicInventoryViewState();
}

class _BasicInventoryViewState extends State<BasicInventoryView> {
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

    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent - 260) return;

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
    final isShop =
        context.read<AuthBloc>().state.permissions.isShop;

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
            InventoryAppBar(
              onAddStock: () => showAddStockProductSheet(context),
              onRefresh: _refresh,
            ),

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
                    ).animate().fadeIn(duration: 280.ms);
                  },
                ),
              ),
            ),

            if (isShop)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, 0, AppDims.s4, AppDims.s2),
                sliver: const SliverToBoxAdapter(
                  child: ExpiryAlertRow(),
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
                InventoryStatus.loading =>
                const InventoryLoadingView(),

                InventoryStatus.failure =>
                    InventoryErrorView(message: state.responseError),

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
    );
  }
}