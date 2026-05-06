import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/widgets/cat_summary_chip.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CategorySummaryCard extends StatelessWidget {
  final CategoryData category;

  const CategorySummaryCard({super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = category.isActive ?? false;
    final childCount = category.children?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
            child: Icon(
              Icons.layers_rounded,
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
                  category.name ?? 'Category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description?.trim().isNotEmpty == true
                      ? category.description!.trim()
                      : 'Products under this category are shown below.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                Row(
                  children: [
                    CatSummaryChip(
                      icon: Icons.circle,
                      iconColor: isActive
                          ? const Color(0xFF22C55E)
                          : colors.textHint,
                      label: isActive ? 'Active' : 'Inactive',
                    ),
                    if (childCount > 0) ...[
                      const SizedBox(width: AppDims.s2),
                      CatSummaryChip(
                        icon: Icons.account_tree_outlined,
                        label: '$childCount sub categories',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
