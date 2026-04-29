import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/widgets/edit_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/delete_category_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CategoryAppBar extends StatelessWidget {
  final CategoryData category;
  final bool isGrid;
  final VoidCallback onToggleLayout;

  const CategoryAppBar({super.key,
    required this.category,
    required this.isGrid,
    required this.onToggleLayout,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: context.appColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded,
            color: context.appColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: onToggleLayout,
          icon: Icon(
            isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: context.appColors.textPrimary,
            size: 22,
          ),
          tooltip: isGrid ? 'List view' : 'Grid view',
        ),
          IconButton(
            onPressed: () => showEditCategorySheet(context, category: category),
            icon: Icon(Icons.edit_outlined,
                size: 20, color: context.appColors.textPrimary),
          ),
          IconButton(
            onPressed: () =>
                showDeleteCategorySheet(context, category: category),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Color(0xFFDC2626)),
            tooltip: 'Delete',
          ),

      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.appColors.surface,
          padding: const EdgeInsets.fromLTRB(
              AppDims.s4, 0, AppDims.s4, AppDims.s3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(Icons.layers_rounded,
                    size: 24, color: context.appColors.primary),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                category.name ?? '—',
                style: AppTextStyles.lg100(context).copyWith(
                fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
              if (category.description != null)
                Text(
                  category.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                  fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}