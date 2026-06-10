import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:flutter/widgets.dart';

enum SaleFilter {
  all,
  today,
  completed,
  refunded,
  pending,
}

extension SaleFilterX on SaleFilter {
  String label(BuildContext context) {
    return switch (this) {
      SaleFilter.all => context.tr.all,
      SaleFilter.today => context.tr.today,
      SaleFilter.completed => context.tr.completed,
      SaleFilter.refunded => context.tr.returned,
      SaleFilter.pending => context.tr.pending,
    };
  }

  String statsLabel(BuildContext context) {
    return switch (this) {
      SaleFilter.all => context.tr.allLoaded,
      SaleFilter.today => context.tr.todaysSales,
      SaleFilter.completed => context.tr.completed,
      SaleFilter.refunded => context.tr.returned,
      SaleFilter.pending => context.tr.pending,
    };
  }

  String salesCountLabel(BuildContext context) {
    return switch (this) {
      SaleFilter.all => context.tr.allLoadedSales,
      SaleFilter.today => context.tr.todaysSalesCount,
      SaleFilter.completed => context.tr.completedSalesCount,
      SaleFilter.refunded => context.tr.returnedSalesCount,
      SaleFilter.pending => context.tr.pendingSalesCount,
    };
  }

  String revenueLabel(BuildContext context) {
    return switch (this) {
      SaleFilter.all => context.tr.allLoadedRevenue,
      SaleFilter.today => context.tr.todaysRevenue,
      SaleFilter.completed => context.tr.completedRevenue,
      SaleFilter.refunded => context.tr.returnedRevenue,
      SaleFilter.pending => context.tr.pendingRevenue,
    };
  }
}

sealed class ListEntry {
  const ListEntry();
}

final class DateHeader extends ListEntry {
  const DateHeader(this.label);

  final String label;
}

final class SaleEntry extends ListEntry {
  const SaleEntry(this.item);

  final SaleHistoryItem item;
}