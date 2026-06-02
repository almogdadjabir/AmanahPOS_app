import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleEmptyState extends StatelessWidget {
  const SaleEmptyState({
    super.key,
    required this.filter,
    required this.hasSearch,
  });

  final SaleFilter filter;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final IconData icon;
    final String title;
    final String subtitle;

    if (hasSearch) {
      icon = SolarIconsOutline.magnifierZoomOut;
      title = tr.noMatchingSales;
      subtitle = tr.tryDifferentSearchTerm;
    } else {
      icon = switch (filter) {
        SaleFilter.today => SolarIconsOutline.calendarDate,
        SaleFilter.pending => SolarIconsOutline.clockCircle,
        SaleFilter.completed => SolarIconsOutline.checkCircle,
        SaleFilter.refunded => SolarIconsOutline.undoLeft,
        SaleFilter.all => SolarIconsOutline.list,
      };
      title = switch (filter) {
        SaleFilter.today => tr.noSalesToday,
        SaleFilter.pending => tr.noPendingSales,
        SaleFilter.completed => tr.noCompletedSales,
        SaleFilter.refunded => tr.noReturnedSales,
        SaleFilter.all => tr.noSalesYet,
      };
      subtitle = switch (filter) {
        SaleFilter.today => tr.salesMadeTodayWillAppearHere,
        SaleFilter.pending => tr.allOfflineSalesSynced,
        SaleFilter.completed => tr.matchingSalesWillAppearHere,
        SaleFilter.refunded => tr.matchingSalesWillAppearHere,
        SaleFilter.all => tr.salesWillAppearHere,
      };
    }

    return AppEmptyView(
      icon: icon,
      title: title,
      subtitle: subtitle,
    );
  }
}
