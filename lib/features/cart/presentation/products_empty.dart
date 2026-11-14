import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class ProductsEmpty extends StatelessWidget {
  const ProductsEmpty({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();

    return AppEmptyView(
      icon: PhosphorIconsRegular.magnifyingGlass,
      title: context.tr.noProductsFound,
      subtitle: trimmed.isEmpty
          ? context.tr.tryAnotherCategoryOrAddProducts
          : context.tr.nothingMatchesQuery(trimmed),
    );
  }
}
