import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class CategoryStats extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoryStats({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final active = categories.where((category) {
      return category.isActive == true;
    }).length;

    final inactive = categories.length - active;

    final subCategories = categories.fold<int>(
      0,
          (total, category) => total + (category.children?.length ?? 0),
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.layersMinimalistic,
            label: 'Total',
            value: '${categories.length}',
            color: colors.primary,
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.checkCircle,
            label: 'Active',
            value: '$active',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.pauseCircle,
            label: 'Inactive',
            value: '$inactive',
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.widget,
            label: 'Sub',
            value: '$subCategories',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
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
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}