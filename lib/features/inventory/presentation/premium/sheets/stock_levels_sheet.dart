import 'package:amana_pos/features/inventory/presentation/bloc/stock_levels_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showStockLevelsSheet(BuildContext context) {
  context.read<StockLevelsBloc>().add(const OnStockLevelsStarted());
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<StockLevelsBloc>(),
      child: const _StockLevelsSheet(),
    ),
  );
}

class _StockLevelsSheet extends StatelessWidget {
  const _StockLevelsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                child: Row(
                  children: [
                    Text(
                      'Stock Levels',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(SolarIconsOutline.closeCircle,
                          color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, 0, AppDims.s4, AppDims.s2),
                child: _SearchField(),
              ),
              // Filter chips
              const _FilterRow(),
              const Divider(height: 1),
              // List
              Expanded(
                child: BlocBuilder<StockLevelsBloc, StockLevelsState>(
                  builder: (context, state) {
                    if (state.status == StockLevelsStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == StockLevelsStatus.failure) {
                      return Center(
                        child: Text(
                          state.responseError ?? 'Failed to load stock',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    }
                    final items = state.filtered;
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No stock items found',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDims.s4, vertical: AppDims.s2),
                      itemCount: items.length +
                          (state.status == StockLevelsStatus.loadingMore
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }
                        final item = items[i];
                        final isOut = item.isOutOfStock ?? false;
                        final isLow = item.isLowStock ?? false;
                        final statusColor = isOut
                            ? const Color(0xFFFCA5A5)
                            : isLow
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFF5EEAD4);
                        final statusLabel =
                            isOut ? 'Out' : isLow ? 'Low' : 'OK';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.productName ?? '',
                            style: AppTextStyles.bs300(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item.productSku ?? '',
                            style: AppTextStyles.bs200(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color:
                                          statusColor.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.quantity ?? '0',
                                style: AppTextStyles.bs300(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: Icon(SolarIconsOutline.magnifier,
            color: colors.textSecondary, size: 20),
        filled: true,
        fillColor: colors.textSecondary.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onChanged: (q) =>
          context.read<StockLevelsBloc>().add(OnStockLevelsSearchChanged(q)),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockLevelsBloc, StockLevelsState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: AppDims.s4, vertical: 8),
          child: Row(
            children: StockLevelsFilter.values.map((f) {
              final label = switch (f) {
                StockLevelsFilter.all => 'All',
                StockLevelsFilter.lowStock => 'Low Stock',
                StockLevelsFilter.outOfStock => 'Out of Stock',
              };
              final isSelected = state.filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => context
                      .read<StockLevelsBloc>()
                      .add(OnStockLevelsFilterChanged(f)),
                  selectedColor: goldDeep.withValues(alpha: 0.15),
                  checkmarkColor: goldDeep,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? goldDeep
                        : context.appColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
