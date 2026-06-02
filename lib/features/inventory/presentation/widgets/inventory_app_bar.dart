import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/feature_sliver_app_bar.dart';
import 'package:flutter/material.dart';

class InventoryAppBar extends StatelessWidget {
  final VoidCallback onAddStock;
  final Future<void> Function() onRefresh;

  const InventoryAppBar({
    super.key,
    required this.onAddStock,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return FeatureSliverAppBar(
      title: tr.stock,
      actionLabel: tr.addStock,
      onAction: onAddStock,
    );
  }
}
