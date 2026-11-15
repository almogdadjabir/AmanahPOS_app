import 'package:amana_pos/theme/app_colors.dart';
import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/returns/presentation/return_items_screen.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/sale_detail_screen.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_filter_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_filter_sheets.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_row.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_states.dart';
import 'package:amana_pos/features/sales_history/services/sale_receipt_pdf_service.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_search_field.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesHistoryScreen extends StatefulWidget {
  /// Returns entry: same list, but tapping a returnable sale opens the
  /// return flow and the screen closes once a return was recorded.
  final bool pickMode;

  const SalesHistoryScreen({super.key, this.pickMode = false});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SalesHistoryBloc>().add(const SalesHistoryStarted());
      if (widget.pickMode) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    if (position.pixels < position.maxScrollExtent * 0.82) return;
    final state = context.read<SalesHistoryBloc>().state;
    if (!state.hasMore || state.isLoading || state.items.isEmpty) return;
    context.read<SalesHistoryBloc>().add(const SalesHistoryLoadMore());
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    final bloc = context.read<SalesHistoryBloc>()
      ..add(const SalesHistoryRefreshed());
    await bloc.stream
        .firstWhere((s) => !s.isLoading)
        .timeout(const Duration(seconds: 6), onTimeout: () => bloc.state);
  }

  void _setFilters(SalesHistoryFilters f) =>
      context.read<SalesHistoryBloc>().add(SalesHistoryFiltersChanged(f));

  Future<void> _pickDate() async {
    final bloc = context.read<SalesHistoryBloc>();
    final next = await pickSalesDate(context, bloc.state.filters);
    if (next != null) bloc.add(SalesHistoryFiltersChanged(next));
  }

  Future<void> _pickPayment() async {
    final bloc = context.read<SalesHistoryBloc>();
    final next = await pickSalesPayment(context, bloc.state.filters);
    if (next != null) bloc.add(SalesHistoryFiltersChanged(next));
  }

  Future<void> _pickStatus() async {
    final bloc = context.read<SalesHistoryBloc>();
    final next = await pickSalesStatus(context, bloc.state.filters);
    if (next != null) bloc.add(SalesHistoryFiltersChanged(next));
  }

  void _clearFilters() {
    _searchCtrl.clear();
    final bloc = context.read<SalesHistoryBloc>();
    if (bloc.state.searchQuery.isNotEmpty) {
      bloc.add(const SalesHistorySearchChanged(''));
    }
    if (bloc.state.filters.isActive) {
      bloc.add(const SalesHistoryFiltersChanged(SalesHistoryFilters()));
    }
  }

  // ---- row actions -------------------------------------------------------

  Future<void> _open(SaleHistoryItem sale) async {
    if (widget.pickMode) {
      await _startReturn(sale);
      return;
    }
    final bloc = context.read<SalesHistoryBloc>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: SaleDetailScreen(item: sale),
        ),
      ),
    );
  }

  Future<void> _startReturn(SaleHistoryItem sale) async {
    final bloc = context.read<SalesHistoryBloc>();
    final updated = await ReturnItemsScreen.open(context, sale);
    if (updated == null) return;
    bloc.add(SalesHistoryItemReplaced(updated));
    if (mounted && widget.pickMode) Navigator.of(context).pop();
  }

  Future<void> _shareReceipt(SaleHistoryItem sale) async {
    final tr = context.tr;
    try {
      await SaleReceiptPdfService.sharePdf(
        sale,
        strings: SaleReceiptPdfStrings.fromContext(context),
      );
    } catch (_) {
      GlobalSnackBar.showError(message: tr.shReceiptFailed);
    }
  }

  List<AppSwipeAction> _swipeActions(SaleHistoryItem sale) {
    final colors = context.appColors;
    final tr = context.tr;
    return [
      if (sale.canBeReturned)
        AppSwipeAction(
          label: tr.shSwipeReturn,
          icon: PhosphorIconsRegular.arrowUUpLeft,
          color: colors.primary,
          onTap: () => _startReturn(sale),
        ),
      AppSwipeAction(
        label: tr.shSwipeReceipt,
        icon: PhosphorIconsRegular.receipt,
        // Fixed slate so the white glyph stays readable in light and dark.
        color: AppColors.swipeSlate,
        onTap: () => _shareReceipt(sale),
      ),
    ];
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOwner = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canAccessReports,
    );
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(
              pickMode: widget.pickMode,
              showReports: isOwner && !widget.pickMode,
            ),
            Expanded(
              child: BlocBuilder<SalesHistoryBloc, SalesHistoryState>(
                builder: (context, state) => _body(context, state, bottomInset),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SalesHistoryState state, double bottom) {
    final tr = context.tr;
    final colors = context.appColors;

    final loading =
        state.items.isEmpty &&
        (state.status == SalesHistoryBlocStatus.initial ||
            state.status == SalesHistoryBlocStatus.loading);
    final failed = state.isFailure && state.items.isEmpty;
    final empty = !loading && !failed && state.items.isEmpty;

    final unsynced = state.items.where((s) => s.isOfflinePending).length;

    final Widget content;
    if (loading) {
      content = const SalesSkeleton();
    } else if (failed) {
      content = Padding(
        padding: const EdgeInsets.only(top: AppDims.s3),
        child: SalesStateCard(
          icon: PhosphorIconsRegular.wifiSlash,
          tone: SalesStateTone.danger,
          title: tr.shErrorTitle,
          body: tr.shErrorBody,
          actionLabel: tr.shTryAgain,
          onAction: () => context.read<SalesHistoryBloc>().add(
            const SalesHistoryRefreshed(),
          ),
        ),
      );
    } else if (empty) {
      content = Padding(
        padding: const EdgeInsets.only(top: AppDims.s3),
        child: SalesStateCard(
          icon: PhosphorIconsRegular.receipt,
          title: tr.shEmptyTitle,
          body: tr.shEmptyBody,
          actionLabel: tr.shClearFilters,
          onAction: _clearFilters,
        ),
      );
    } else {
      final groups = _group(context, state.items);
      content = Column(
        children: [
          for (var i = 0; i < groups.length; i++)
            SalesDayGroup(
              label: groups[i].label,
              sales: groups[i].sales,
              first: i == 0,
              pickMode: widget.pickMode,
              onTap: _open,
              swipeActions: widget.pickMode ? null : _swipeActions,
            ),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDims.s5),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      );
    }

    final showCount = !loading && !failed;
    final count = state.totalCount ?? state.items.length;

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
            child: AppLargeTitle(
              title: widget.pickMode ? tr.rtPickTitle : tr.shTitle,
              subtitle: widget.pickMode ? tr.rtPickSubtitle : null,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          sliver: SliverToBoxAdapter(
            child: AppSearchField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              hint: tr.shSearchHint,
              onChanged: (q) => context.read<SalesHistoryBloc>().add(
                SalesHistorySearchChanged(q),
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: SalesFilterHeaderDelegate(
            background: colors.background,
            child: SalesFilterBar(
              filters: state.filters,
              unsyncedCount: unsynced,
              showUnsynced: !widget.pickMode,
              onDate: _pickDate,
              onPayment: _pickPayment,
              onStatus: _pickStatus,
              onUnsynced: () => _setFilters(
                state.filters.copyWith(
                  onlyUnsynced: !state.filters.onlyUnsynced,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(AppDims.s4, 2, AppDims.s4, bottom),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCount && !widget.pickMode)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 10),
                    child: Text(
                      tr.shCount(empty ? 0 : count),
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                content,
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_DayGroup> _group(BuildContext context, List<SaleHistoryItem> items) {
    final groups = <_DayGroup>[];
    for (final item in items) {
      final label = saleDayLabel(context, item.createdAt);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_DayGroup(label));
      }
      groups.last.sales.add(item);
    }
    return groups;
  }
}

class _DayGroup {
  final String label;
  final List<SaleHistoryItem> sales = [];
  _DayGroup(this.label);
}

class _NavBar extends StatelessWidget {
  final bool pickMode;
  final bool showReports;

  const _NavBar({required this.pickMode, required this.showReports});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (pickMode)
              Pressable(
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        context.tr.cancel,
                        style: TextStyle(fontSize: 17, color: colors.primary),
                      ),
                    ),
                  ),
                ),
              )
            else if (Navigator.of(context).canPop())
              Pressable(
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        DirectionalIcon(
                          icon: PhosphorIconsRegular.caretLeft,
                          size: 22,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          context.tr.navHome,
                          style: TextStyle(fontSize: 17, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (showReports)
              Pressable(
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteStrings.reportsScreen),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    PhosphorIconsRegular.chartBar,
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
