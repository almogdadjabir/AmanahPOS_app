import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/widgets/app_filter_chip.dart';
import 'package:flutter/material.dart';

String salesDateLabel(BuildContext context, SalesDatePreset p) {
  final tr = context.tr;
  return switch (p) {
    SalesDatePreset.any => tr.shDateAny,
    SalesDatePreset.today => tr.shDateToday,
    SalesDatePreset.yesterday => tr.shDateYesterday,
    SalesDatePreset.last7 => tr.shDateLast7,
    SalesDatePreset.month => tr.shDateMonth,
    SalesDatePreset.custom => tr.shDateCustom,
  };
}

String salesPaymentLabel(BuildContext context, String? p) {
  final tr = context.tr;
  return switch (p) {
    'cash' => tr.shPayCash,
    'bankak' => tr.shPayBankak,
    'card' => tr.shPayCard,
    _ => tr.shPayAll,
  };
}

String salesStatusLabel(BuildContext context, String? s) {
  final tr = context.tr;
  return switch (s) {
    'completed' => tr.shStatusCompleted,
    'partial_refund' => tr.shStatusPartial,
    'refunded' => tr.shStatusReturned,
    'cancelled' => tr.shStatusCancelled,
    _ => tr.shStatusAll,
  };
}

/// One horizontal row: Date, Payment, Status menus and the Not synced toggle.
class SalesFilterBar extends StatelessWidget {
  final SalesHistoryFilters filters;
  final int unsyncedCount;
  final bool showUnsynced;
  final VoidCallback onDate;
  final VoidCallback onPayment;
  final VoidCallback onStatus;
  final VoidCallback onUnsynced;

  const SalesFilterBar({
    super.key,
    required this.filters,
    required this.unsyncedCount,
    required this.showUnsynced,
    required this.onDate,
    required this.onPayment,
    required this.onStatus,
    required this.onUnsynced,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: 10,
        ),
        children: [
          AppFilterChip(
            label: filters.date == SalesDatePreset.any
                ? tr.shChipDate
                : salesDateLabel(context, filters.date),
            selected: filters.date != SalesDatePreset.any,
            showCaret: true,
            onTap: onDate,
          ),
          const SizedBox(width: AppDims.s2),
          AppFilterChip(
            label: filters.payment == null
                ? tr.shChipPayment
                : salesPaymentLabel(context, filters.payment),
            selected: filters.payment != null,
            showCaret: true,
            onTap: onPayment,
          ),
          const SizedBox(width: AppDims.s2),
          AppFilterChip(
            label: filters.status == null
                ? tr.shChipStatus
                : salesStatusLabel(context, filters.status),
            selected: filters.status != null,
            showCaret: true,
            onTap: onStatus,
          ),
          if (showUnsynced) ...[
            const SizedBox(width: AppDims.s2),
            AppFilterChip(
              label: tr.shChipUnsynced,
              selected: filters.onlyUnsynced,
              count: unsyncedCount > 0 ? unsyncedCount : null,
              onTap: onUnsynced,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pinned header holding the chips row, on the page background.
class SalesFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;

  const SalesFilterHeaderDelegate({
    required this.child,
    required this.background,
  });

  @override
  double get minExtent => 54;

  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: background, child: child);

  @override
  bool shouldRebuild(covariant SalesFilterHeaderDelegate old) =>
      old.child != child || old.background != background;
}
