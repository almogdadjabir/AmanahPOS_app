import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_products_card.dart';
import 'package:flutter/material.dart';

class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({super.key, required this.categories});

  final List<SalesTopCategory> categories;

  @override
  Widget build(BuildContext context) {
    return RankedListCard(
      title: context.tr.topCategoriesTitle,
      items: categories
          .map((c) => (name: c.name, amount: c.grossAmount, subtitle: null as String?))
          .toList(),
      emptyMessage: context.tr.reportsNoSalesInRange,
    );
  }
}
