import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

enum CategoryQuickFilter {
  all,
  active,
  inactive,
  withSubCategories,
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
    final colors = context.appColors;

    final active = categories.where((category) {
      return category.isActive == true;
    }).length;

    final inactive = categories.length - active;

    final withSubCategories = categories.where((category) {
      return (category.children?.length ?? 0) > 0;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  SolarIconsOutline.layersMinimalistic,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Categories',
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
                      'Group products into simple sections for faster checkout and cleaner inventory.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s4),
          Row(
            children: [
              Expanded(
                child: _CategoryMiniStat(
                  label: 'Total',
                  value: '${categories.length}',
                  icon: SolarIconsOutline.layersMinimalistic,
                  color: colors.primary,
                  isSelected: selectedFilter == CategoryQuickFilter.all,
                  onTap: () => onFilterChanged(CategoryQuickFilter.all),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CategoryMiniStat(
                  label: 'Active',
                  value: '$active',
                  icon: SolarIconsOutline.checkCircle,
                  color: const Color(0xFF16A34A),
                  isSelected: selectedFilter == CategoryQuickFilter.active,
                  onTap: () => onFilterChanged(CategoryQuickFilter.active),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CategoryMiniStat(
                  label: 'Inactive',
                  value: '$inactive',
                  icon: SolarIconsOutline.pauseCircle,
                  color: const Color(0xFF94A3B8),
                  isSelected: selectedFilter == CategoryQuickFilter.inactive,
                  onTap: () => onFilterChanged(CategoryQuickFilter.inactive),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CategoryMiniStat(
                  label: 'Sub',
                  value: '$withSubCategories',
                  icon: SolarIconsOutline.widget,
                  color: const Color(0xFF8B5CF6),
                  isSelected:
                  selectedFilter == CategoryQuickFilter.withSubCategories,
                  onTap: () {
                    onFilterChanged(CategoryQuickFilter.withSubCategories);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
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