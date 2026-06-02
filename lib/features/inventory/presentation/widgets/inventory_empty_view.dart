import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/add_stock_product_sheet.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class InventoryEmptyView extends StatelessWidget {
  final StockFilter filter;

  const InventoryEmptyView({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final title = switch (filter) {
      StockFilter.all => tr.noStockEntriesYet,
      StockFilter.healthy => tr.noHealthyStockItems,
      StockFilter.lowStock => tr.noLowStockItems,
      StockFilter.outOfStock => tr.noOutOfStockItems,
    };

    final subtitle = switch (filter) {
      StockFilter.all => tr.addStockToStartTracking,
      StockFilter.healthy => tr.noProductsInHealthyStockState,
      StockFilter.lowStock => tr.noProductsLowOnStock,
      StockFilter.outOfStock => tr.noProductsOutOfStock,
    };

    final icon = switch (filter) {
      StockFilter.all => SolarIconsOutline.box,
      StockFilter.healthy => SolarIconsOutline.checkCircle,
      StockFilter.lowStock => SolarIconsOutline.dangerTriangle,
      StockFilter.outOfStock => SolarIconsOutline.bagCross,
    };

    return AppEmptyView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      ctaLabel: filter == StockFilter.all ? tr.addStock : null,
      ctaIcon: filter == StockFilter.all ? SolarIconsOutline.addCircle : null,
      onCta: filter == StockFilter.all
          ? () => showAddStockProductSheet(context)
          : null,
    );
  }
}
