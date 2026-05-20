import 'package:amana_pos/features/sales_history/data/models/sale_history_extensions.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_app_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_detail_sheet.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_empty_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_error_view.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_footer.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_history_tile.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_shimmer.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sticky_header.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  SaleFilter _activeFilter = SaleFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SalesHistoryBloc>().add(const SalesHistoryStarted());
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }


  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      context.read<SalesHistoryBloc>().add(const SalesHistoryLoadMore());
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
    Navigator.of(context).pushNamed('returnsScreen', arguments: item);
  }

  List<SaleHistoryItem> _applyFilter(List<SaleHistoryItem> items) {
    if (_activeFilter == SaleFilter.all) return items;
    return items.where((i) => switch (_activeFilter) {
      SaleFilter.all => true,
      SaleFilter.today => i.isToday,
      SaleFilter.completed => i.status == SaleHistoryStatus.completed,
      SaleFilter.refunded  => i.status == SaleHistoryStatus.refunded ||
          i.status == SaleHistoryStatus.partialRefund,
      SaleFilter.pending   =>
      i.isOfflinePending || i.status == SaleHistoryStatus.pending,
    }).toList();
  }

  List<ListEntry> _buildEntries(List<SaleHistoryItem> filtered) {
    final entries = <ListEntry>[];
    String? lastLabel;
    for (final item in filtered) {
      final label = item.dateGroupLabel;
      if (label != lastLabel) {
        entries.add(DateHeader(label));
        lastLabel = label;
      }
      entries.add(SaleEntry(item));
    }
    return entries;
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SaleAppBar(),
      body: Column(
        children: [

          StickyHeader(
            activeFilter: _activeFilter,
            searchCtrl: _searchCtrl,
            applyFilter: _applyFilter,
            onFilterSelect: (f) => setState(() => _activeFilter = f),
            onSearch: (q) => context
                .read<SalesHistoryBloc>()
                .add(SalesHistorySearchChanged(q)),
          ),


          Expanded(
            child: BlocBuilder<SalesHistoryBloc, SalesHistoryState>(
              builder: (context, state) {
                if (state.status == SalesHistoryBlocStatus.loading &&
                    state.items.isEmpty) {
                  return const SaleShimmer();
                }

                if (state.isFailure && state.items.isEmpty) {
                  return SaleErrorView(
                    message: state.errorMessage ?? 'Failed to load',
                    onRetry: () => context
                        .read<SalesHistoryBloc>()
                        .add(const SalesHistoryRefreshed()),
                  );
                }

                final filtered = _applyFilter(state.items);

                if (filtered.isEmpty) {
                  return SaleEmptyState(
                    filter: _activeFilter,
                    hasSearch: state.searchQuery.isNotEmpty,
                  );
                }

                final entries = _buildEntries(filtered);

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => context
                      .read<SalesHistoryBloc>()
                      .add(const SalesHistoryRefreshed()),
                  child: ListView.builder(
                    controller:  _scrollCtrl,
                    cacheExtent: MediaQuery.sizeOf(context).height * 2,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s8),
                    itemCount: entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == entries.length) {
                        return SaleFooter(
                          isLoadingMore: state.isLoadingMore,
                          hasMore: state.hasMore &&
                              _activeFilter == SaleFilter.all,
                        );
                      }

                      final entry = entries[index];

                      if (entry is DateHeader) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 0 : AppDims.s4,
                            bottom: AppDims.s2,
                          ),
                          child: WorkspaceSectionHeader(title: entry.label),
                        );
                      }

                      final item = (entry as SaleEntry).item;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDims.s2),
                        child: RepaintBoundary(
                          child: SaleHistoryTile(
                            item:  item,
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