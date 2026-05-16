import 'package:amana_pos/features/inventory/presentation/bloc/expiry_report_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showExpiryReportSheet(BuildContext context) {
  context.read<ExpiryReportBloc>().add(const OnExpiryReportStarted());
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ExpiryReportBloc>(),
      child: const _ExpiryReportSheet(),
    ),
  );
}

class _ExpiryReportSheet extends StatelessWidget {
  const _ExpiryReportSheet();

  Color _chipColor(int days, bool isExpired) {
    if (isExpired || days <= 0) return const Color(0xFFFCA5A5);
    if (days <= 5) return const Color(0xFFFCA5A5);
    if (days <= 14) return const Color(0xFFFCD34D);
    return const Color(0xFF5EEAD4);
  }

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                child: Row(
                  children: [
                    Text(
                      'Expiry Report',
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
              // Filter chips
              _FilterRow(),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<ExpiryReportBloc, ExpiryReportState>(
                  builder: (context, state) {
                    if (state.status == ExpiryReportStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == ExpiryReportStatus.failure) {
                      return Center(
                        child: Text(
                          state.responseError ?? 'Failed to load',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    }
                    if (state.items.isEmpty) {
                      return Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppDims.s4),
                      itemCount: state.items.length,
                      separatorBuilder: (_, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = state.items[i];
                        final chipColor =
                            _chipColor(item.daysRemaining, item.isExpired);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDims.s2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bs300(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (item.batchNumber != null)
                                      Text(
                                        'Batch: ${item.batchNumber}',
                                        style: AppTextStyles.bs200(context)
                                            .copyWith(
                                                color: colors.textSecondary),
                                      ),
                                    Text(
                                      'Qty: ${item.quantity} · ${item.expiryDate}',
                                      style: AppTextStyles.bs200(context)
                                          .copyWith(
                                              color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: chipColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color:
                                          chipColor.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  item.isExpired
                                      ? 'Expired'
                                      : '${item.daysRemaining}d left',
                                  style: TextStyle(
                                    color: chipColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
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

class _FilterRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpiryReportBloc, ExpiryReportState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4, vertical: 8),
          child: Row(
            children: ExpiryReportFilter.values.map((f) {
              final label = switch (f) {
                ExpiryReportFilter.expiringSoon => 'Expiring Soon',
                ExpiryReportFilter.expired => 'Expired',
                ExpiryReportFilter.all => 'All',
              };
              final isSelected = state.filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => context
                      .read<ExpiryReportBloc>()
                      .add(OnExpiryReportFilterChanged(f)),
                  selectedColor: const Color(0xFFFCA5A5).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFFFCA5A5),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFCA5A5)
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
