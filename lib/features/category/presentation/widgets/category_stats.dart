import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CategoryStats extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoryStats({super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final active = categories.where((c) => c.isActive == true).length;
    final inactive = categories.length - active;
    final subCategories = categories.fold<int>(
      0,
          (total, c) => total + (c.children?.length ?? 0),
    );

    return Row(
      children: [
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.layers_outlined,
            label: 'Total',
            value: '${categories.length}',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.check_circle_outline_rounded,
            label: 'Active',
            value: '$active',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.pause_circle_outline_rounded,
            label: 'Inactive',
            value: '$inactive',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: statCard(
            context: context,
            icon: Icons.account_tree_outlined,
            label: 'Sub',
            value: '$subCategories',
          ),
        ),
      ],
    );
  }

  Widget statCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }){
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: colors.primary,
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            value,
            style: AppTextStyles.bs400(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
