import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

enum CategoryQuickFilter {
  all,
  active,
  inactive
}

class CategoriesHeader extends StatelessWidget {
  final List<CategoryData> categories;
  final CategoryQuickFilter selectedFilter;
  final ValueChanged<CategoryQuickFilter> onFilterChanged;

  const CategoriesHeader({
    super.key,
    required this.categories,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _CategoryHeaderStats.fromCategories(categories);

    return _CategoriesHeaderContent(
      stats: stats,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
    );
  }
}

class _CategoriesHeaderContent extends StatelessWidget {
  final _CategoryHeaderStats stats;
  final CategoryQuickFilter selectedFilter;
  final ValueChanged<CategoryQuickFilter> onFilterChanged;

  const _CategoriesHeaderContent({
    required this.stats,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Column(
          children: [
            Row(
              children: [
                _HeaderIcon(color: colors.primary),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: _HeaderText(
                    title: tr.productCategoriesTitle,
                    subtitle: tr.productCategoriesSubtitle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDims.s4),

            Row(
              children: [
                Expanded(
                  child: _CategoryMiniStat(
                    label: tr.catStatTotal,
                    value: stats.total.toString(),
                    icon: SolarIconsOutline.layersMinimalistic,
                    color: colors.primary,
                    isSelected: selectedFilter == CategoryQuickFilter.all,
                    onTap: () => onFilterChanged(CategoryQuickFilter.all),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _CategoryMiniStat(
                    label: tr.catStatActive,
                    value: stats.active.toString(),
                    icon: SolarIconsOutline.checkCircle,
                    color: const Color(0xFF16A34A),
                    isSelected: selectedFilter == CategoryQuickFilter.active,
                    onTap: () => onFilterChanged(CategoryQuickFilter.active),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _CategoryMiniStat(
                    label: tr.catStatInactive,
                    value: stats.inactive.toString(),
                    icon: SolarIconsOutline.pauseCircle,
                    color: const Color(0xFF94A3B8),
                    isSelected: selectedFilter == CategoryQuickFilter.inactive,
                    onTap: () => onFilterChanged(CategoryQuickFilter.inactive),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final Color color;

  const _HeaderIcon({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          SolarIconsOutline.layersMinimalistic,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderText({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs700(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs300(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _CategoryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s2,
            vertical: AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              width: isSelected ? 1.4 : 1,
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs100(context).copyWith(
                  color: isSelected ? color : colors.textSecondary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeaderStats {
  final int total;
  final int active;
  final int inactive;
  final int withSubCategories;

  const _CategoryHeaderStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.withSubCategories,
  });

  factory _CategoryHeaderStats.fromCategories(List<CategoryData> categories) {
    var active = 0;
    var withSubCategories = 0;

    for (final category in categories) {
      if (category.isActive == true) {
        active++;
      }

      if ((category.children?.length ?? 0) > 0) {
        withSubCategories++;
      }
    }

    return _CategoryHeaderStats(
      total: categories.length,
      active: active,
      inactive: categories.length - active,
      withSubCategories: withSubCategories,
    );
  }
}