import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_top_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_stats_row.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_table.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_tab_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail_sheet.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_view_tab_switch.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kScrollLoadThreshold = 200.0;

class DesktopSalesHistoryView extends StatefulWidget {
  const DesktopSalesHistoryView({super.key});

  @override
  State<DesktopSalesHistoryView> createState() =>
      _DesktopSalesHistoryViewState();
}

class _DesktopSalesHistoryViewState extends State<DesktopSalesHistoryView> {
  final _searchCtrl = TextEditingController();
  SalesView _activeView = SalesView.transactions;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<SalesHistoryBloc>().add(
          SalesHistorySearchChanged(_searchCtrl.text),
        );
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final bloc = context.read<SalesHistoryBloc>();
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - _kScrollLoadThreshold &&
        bloc.state.isLoaded &&
        bloc.state.hasMore) {
      bloc.add(const SalesHistoryLoadMore());
    }
  }

  void _refresh() {
    context.read<SalesHistoryBloc>().add(const SalesHistoryRefreshed());
  }

  List<SaleHistoryItem> _applyFilter(List<SaleHistoryItem> items) => items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDims.s4),
      child: Column(
        children: [
          DesktopSalesHistoryTopBar(
            activeView: _activeView,
            onViewChanged: (v) => setState(() => _activeView = v),
            searchController: _searchCtrl,
            onRefresh: _refresh,
          ),
          const SizedBox(height: AppDims.s3),
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: _buildSlivers(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context) {
    if (_activeView == SalesView.reports) {
      return const [ReportsTabView()];
    }

    return [
      SliverToBoxAdapter(
        child: DesktopSalesStatsRow(
          activeFilter: SaleFilter.all,
          applyFilter: _applyFilter,
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(top: AppDims.s3)),
      BlocBuilder<SalesHistoryBloc, SalesHistoryState>(
        builder: (context, state) {
          if (state.status == SalesHistoryBlocStatus.loading &&
              state.items.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.isFailure && state.items.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(state.errorMessage ?? context.tr.failedToLoadSales),
              ),
            );
          }

          if (state.items.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(context.tr.noSalesYet)),
            );
          }

          return DesktopSalesTable(
            items: state.items,
            onTap: (item) => _openDetail(context, item),
          );
        },
      ),
    ];
  }

  void _openDetail(BuildContext context, SaleHistoryItem item) {
    SaleDetailSheet.show(
      context,
      item: item,
      onReturnTap: item.canBeReturned
          ? () => Navigator.of(context).pushNamed('returnsScreen', arguments: item)
          : null,
    );
  }
}
