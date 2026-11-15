import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_filter_chip.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// Values the chips row needs. Counts are over the loaded products.
class ProductsFilterState {
  final String? categoryName;
  final bool lowOn;
  final bool outOn;
  final bool inactiveOn;
  final int lowCount;
  final int outCount;
  final bool countsPartial;
  final bool showStockChips;

  const ProductsFilterState({
    required this.categoryName,
    required this.lowOn,
    required this.outOn,
    required this.inactiveOn,
    required this.lowCount,
    required this.outCount,
    required this.countsPartial,
    required this.showStockChips,
  });
}

/// One horizontal row: Category menu, Low stock, Out of stock, Inactive.
class ProductsFilterBar extends StatelessWidget {
  final ProductsFilterState filters;
  final VoidCallback onCategory;
  final VoidCallback onLow;
  final VoidCallback onOut;
  final VoidCallback onInactive;

  const ProductsFilterBar({
    super.key,
    required this.filters,
    required this.onCategory,
    required this.onLow,
    required this.onOut,
    required this.onInactive,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final plus = filters.countsPartial ? '+' : '';

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
            label: filters.categoryName ?? tr.pcChipCategory,
            selected: filters.categoryName != null,
            showCaret: true,
            onTap: onCategory,
          ),
          if (filters.showStockChips) ...[
            const SizedBox(width: AppDims.s2),
            AppFilterChip(
              label: tr.pcChipLow,
              selected: filters.lowOn,
              tone: AppChipTone.warning,
              countText: filters.lowCount == 0 && plus.isEmpty
                  ? null
                  : '${filters.lowCount}$plus',
              onTap: onLow,
            ),
            const SizedBox(width: AppDims.s2),
            AppFilterChip(
              label: tr.pcChipOut,
              selected: filters.outOn,
              tone: AppChipTone.danger,
              countText: filters.outCount == 0 && plus.isEmpty
                  ? null
                  : '${filters.outCount}$plus',
              onTap: onOut,
            ),
          ],
          const SizedBox(width: AppDims.s2),
          AppFilterChip(
            label: tr.inactive,
            selected: filters.inactiveOn,
            onTap: onInactive,
          ),
        ],
      ),
    );
  }
}

/// Pinned header holding the chips row, on the page background.
class ProductsFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;

  const ProductsFilterHeaderDelegate({
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
  ) {
    return ColoredBox(color: background, child: child);
  }

  @override
  bool shouldRebuild(covariant ProductsFilterHeaderDelegate old) =>
      old.child != child || old.background != background;
}

/// Category menu: All categories plus one row per category, checkmark on the
/// current one. Resolves with the picked category id, `''` for All, or null
/// when dismissed.
Future<String?> showProductCategorySheet(
  BuildContext context, {
  required List<CategoryData> categories,
  required String? selectedId,
}) {
  return showAdaptivePanel<String>(
    context,
    showDragHandle: false,
    builder: (sheetContext) => AppSheet(
      title: sheetContext.tr.pcChipCategory,
      maxHeightFactor: 0.8,
      child: _CategoryList(categories: categories, selectedId: selectedId),
    ),
  );
}

class _CategoryList extends StatelessWidget {
  final List<CategoryData> categories;
  final String? selectedId;

  const _CategoryList({required this.categories, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    Widget option(String label, String id, bool selected) {
      return Pressable(
        scale: 1,
        onTap: () => Navigator.of(context).pop(id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, color: colors.textPrimary),
                  ),
                ),
                if (selected)
                  Icon(
                    PhosphorIconsRegular.check,
                    size: 22,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[
      option(tr.pcAllCategories, '', selectedId == null),
      for (final c in categories)
        if (c.id != null)
          option(
            (c.name?.trim().isNotEmpty ?? false) ? c.name!.trim() : tr.category,
            c.id!,
            selectedId == c.id,
          ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4,
                  color: colors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
