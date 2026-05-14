import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/widgets/delete_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/edit_category_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class CategoryAppBar extends StatelessWidget {
  final CategoryData category;
  final bool isGrid;
  final VoidCallback onToggleLayout;

  const CategoryAppBar({
    super.key,
    required this.category,
    required this.isGrid,
    required this.onToggleLayout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final name = category.name?.trim().isNotEmpty == true
        ? category.name!.trim()
        : 'Category';

    final description = category.description?.trim().isNotEmpty == true
        ? category.description!.trim()
        : 'Products assigned to this category';

    final isActive = category.isActive ?? false;

    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            _AppBarIconButton(
              icon: SolarIconsOutline.altArrowLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _AppBarIconButton(
              icon: isGrid
                  ? SolarIconsOutline.list
                  : SolarIconsOutline.widget,
              onTap: onToggleLayout,
            ),
            const SizedBox(width: AppDims.s2),
            _AppBarIconButton(
              icon: SolarIconsOutline.penNewSquare,
              onTap: () {
                showEditCategorySheet(context, category: category);
              },
            ),
            const SizedBox(width: AppDims.s2),
            _AppBarIconButton(
              icon: SolarIconsOutline.trashBinTrash,
              color: const Color(0xFFDC2626),
              backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.08),
              borderColor: const Color(0xFFDC2626).withValues(alpha: 0.18),
              onTap: () {
                showDeleteCategorySheet(context, category: category);
              },
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: colors.background,
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            0,
            AppDims.s4,
            AppDims.s4,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppDims.rLg),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        SolarIconsOutline.layersMinimalistic,
                        size: 30,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDims.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusPill(isActive: isActive),
                          const SizedBox(height: AppDims.s2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.lg100(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                              height: 1.05,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs300(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: backgroundColor ?? colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: borderColor ?? colors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isActive ? const Color(0xFF16A34A) : colors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.22 : 0.14),
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        maxLines: 1,
        style: AppTextStyles.bs100(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          height: 1,
        ),
      ),
    );
  }
}