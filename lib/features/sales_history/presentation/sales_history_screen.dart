import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_extensions.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/desktop_sales_history_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_app_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail_sheet.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_empty_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_error_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_footer.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_history_tile.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_shimmer.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sticky_header.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  SaleFilter _activeFilter = SaleFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SalesHistoryBloc>().add(const SalesHistoryStarted());
    });
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_activeFilter != SaleFilter.all) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent * 0.82;

    if (!shouldLoadMore) return;

    final state = context.read<SalesHistoryBloc>().state;
    if (!state.hasMore || state.isLoadingMore) return;

    context.read<SalesHistoryBloc>().add(const SalesHistoryLoadMore());
  }

  void _onRefresh() {
    context.read<SalesHistoryBloc>().add(const SalesHistoryRefreshed());
  }

  void _onSearch(String query) {
    context.read<SalesHistoryBloc>().add(
      SalesHistorySearchChanged(query),
    );
  }

  void _onFilterSelect(SaleFilter filter) {
    if (_activeFilter == filter) return;

    setState(() => _activeFilter = filter);

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openDetail(SaleHistoryItem item) {
    SaleDetailSheet.show(
      context,
      item: item,
      onReturnTap: item.canBeReturned ? () => _openReturns(item) : null,
    );
  }

  void _openReturns(SaleHistoryItem item) {
    Navigator.of(context).pushNamed(
      'returnsScreen',
      arguments: item,
    );
  }

  List<SaleHistoryItem> _applyFilter(List<SaleHistoryItem> items) {
    if (_activeFilter == SaleFilter.all) return items;

    final filtered = <SaleHistoryItem>[];

    for (final item in items) {
      final matches = switch (_activeFilter) {
        SaleFilter.all => true,
        SaleFilter.today => item.isToday,
        SaleFilter.completed => item.status == SaleHistoryStatus.completed,
        SaleFilter.refunded =>
        item.status == SaleHistoryStatus.refunded ||
            item.status == SaleHistoryStatus.partialRefund,
        SaleFilter.pending =>
        item.isOfflinePending || item.status == SaleHistoryStatus.pending,
      };

      if (matches) filtered.add(item);
    }

    return filtered;
  }

  List<ListEntry> _buildEntries(
      BuildContext context,
      List<SaleHistoryItem> filtered,
      ) {
    final entries = <ListEntry>[];
    String? lastLabel;

    for (final item in filtered) {
      final label = _localizedDateGroupLabel(context, item.createdAt);

      if (label != lastLabel) {
        entries.add(DateHeader(label));
        lastLabel = label;
      }

      entries.add(SaleEntry(item));
    }

    return entries;
  }

  String _localizedDateGroupLabel(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    final now = DateTime.now();
    final localDate = dateTime.toLocal();

    final today = DateTime(now.year, now.month, now.day);
    final saleDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final diffDays = today.difference(saleDay).inDays;

    if (diffDays == 0) {
      return context.tr.today;
    }

    if (diffDays == 1) {
      return context.tr.yesterday;
    }

    if (diffDays > 1 && diffDays < 7) {
      return DateFormat.EEEE(locale).format(localDate);
    }

    return DateFormat.yMMMd(locale).format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const DesktopSalesHistoryView();

    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const SaleAppBar(),
      body: Column(
        children: [
          StickyHeader(
            activeFilter: _activeFilter,
            searchCtrl: _searchCtrl,
            applyFilter: _applyFilter,
            onFilterSelect: _onFilterSelect,
            onSearch: _onSearch,
          ),
          Expanded(
            child: BlocSelector<SalesHistoryBloc, SalesHistoryState,
                _SalesHistoryViewData>(
              selector: (state) {
                final filtered = _applyFilter(state.items);
                return _SalesHistoryViewData(
                  status: state.status,
                  isFailure: state.isFailure,
                  isLoadingMore: state.isLoadingMore,
                  hasMore: state.hasMore,
                  errorMessage: state.errorMessage,
                  searchQuery: state.searchQuery,
                  items: state.items,
                  filtered: filtered,
                  entries: _buildEntries(context, filtered),
                );
              },
              builder: (context, view) {
                if (view.status == SalesHistoryBlocStatus.loading &&
                    view.items.isEmpty) {
                  return const SaleShimmer();
                }

                if (view.isFailure && view.items.isEmpty) {
                  return SaleErrorView(
                    message: view.errorMessage ?? context.tr.failedToLoadSales,
                    onRetry: _onRefresh,
                  );
                }

                if (view.filtered.isEmpty) {
                  return SaleEmptyState(
                    filter: _activeFilter,
                    hasSearch: view.searchQuery.trim().isNotEmpty,
                  );
                }

                return RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () async => _onRefresh(),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    cacheExtent: MediaQuery.sizeOf(context).height * 2,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppDims.s4,
                      AppDims.s3,
                      AppDims.s4,
                      AppDims.s8,
                    ),
                    itemCount: view.entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == view.entries.length) {
                        return SaleFooter(
                          isLoadingMore: view.isLoadingMore,
                          hasMore:
                          view.hasMore && _activeFilter == SaleFilter.all,
                        );
                      }

                      final entry = view.entries[index];

                      if (entry is DateHeader) {
                        return Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: index == 0 ? 0 : AppDims.s4,
                            bottom: AppDims.s2,
                          ),
                          child: WorkspaceSectionHeader(title: entry.label),
                        );
                      }

                      final item = (entry as SaleEntry).item;

                      return Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppDims.s2,
                        ),
                        child: RepaintBoundary(
                          child: SaleHistoryTile(
                            item: item,
                            onTap: () => _openDetail(item),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesHistoryViewData {
  const _SalesHistoryViewData({
    required this.status,
    required this.isFailure,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
    required this.searchQuery,
    required this.items,
    required this.filtered,
    required this.entries,
  });

  final SalesHistoryBlocStatus status;
  final bool isFailure;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String searchQuery;
  final List<SaleHistoryItem> items;
  final List<SaleHistoryItem> filtered;
  final List<ListEntry> entries;

  @override
  bool operator ==(Object other) {
    return other is _SalesHistoryViewData &&
        other.status == status &&
        other.isFailure == isFailure &&
        other.isLoadingMore == isLoadingMore &&
        other.hasMore == hasMore &&
        other.errorMessage == errorMessage &&
        other.searchQuery == searchQuery &&
        other.items == items &&
        other.filtered == filtered;
  }

  @override
  int get hashCode => Object.hash(
    status,
    isFailure,
    isLoadingMore,
    hasMore,
    errorMessage,
    searchQuery,
    items,
    filtered,
  );
}