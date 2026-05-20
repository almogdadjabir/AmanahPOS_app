import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';

enum SaleFilter { all, today, completed, refunded, pending }

extension SaleFilterX on SaleFilter {
  String get label => switch (this) {
    SaleFilter.all => 'All',
    SaleFilter.today => 'Today',
    SaleFilter.completed => 'Completed',
    SaleFilter.refunded => 'Returned',
    SaleFilter.pending => 'Pending',
  };

  String get statsLabel => switch (this) {
    SaleFilter.all => 'All loaded',
    SaleFilter.today => "Today's",
    SaleFilter.completed => 'Completed',
    SaleFilter.refunded => 'Returned',
    SaleFilter.pending => 'Pending',
  };
}

sealed class ListEntry {}

final class DateHeader extends ListEntry {
  final String label;
  DateHeader(this.label);
}

final class SaleEntry extends ListEntry {
  final SaleHistoryItem item;
  SaleEntry(this.item);
}