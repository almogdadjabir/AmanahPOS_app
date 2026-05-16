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
  final int productCount;
  final bool isFromCache;
  final bool isGrid;
  final VoidCallback onToggleLayout;
  final VoidCallback onAddProduct;

  const CategoryAppBar({
    super.key,
    required this.category,
    required this.productCount,
    required this.isFromCache,
    required this.isGrid,
    required this.onToggleLayout,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final name = category.name?.trim().isNotEmpty == true
        ? category.name!.trim()
        : 'Category';

    final description = category.description?.trim().isNotEmpty == true
        ? category.description!.trim()
        : 'Organize products under this category for faster POS usage.';

    final isActive = category.isActive ?? true;
    final subCategoryCount = category.children?.length ?? 0;

    return SliverAppBar(
      expandedHeight: 330,
      collapsedHeight: kToolbarHeight,
      toolbarHeight: kToolbarHeight,
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
              icon: isGrid ? SolarIconsOutline.list : SolarIconsOutline.widget,
              onTap: onToggleLayout,
            ),
            const SizedBox(width: AppDims.s2),
            _AppBarIconButton(
              icon: SolarIconsOutline.addCircle,
              color: colors.primary,
              backgroundColor: colors.primary.withValues(alpha: 0.08),
              borderColor: colors.primary.withValues(alpha: 0.18),
              onTap: onAddProduct,
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
            kToolbarHeight + AppDims.s5,
            AppDims.s4,
            AppDims.s4,
          ),
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
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
                  mainAxisSize: MainAxisSize.min,
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
                            size: 30,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppDims.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppDims.s2,
                                runSpacing: AppDims.s1,
                                children: [
                                  _StatusPill(isActive: isActive),
                                  if (isFromCache) const _CachePill(),
                                ],
                              ),
                              const SizedBox(height: AppDims.s2),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bs700(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bs300(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                  height: 1.3,
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
                          child: _CategoryMiniInfo(
                            label: 'Products',
                            value: '$productCount',
                            icon: SolarIconsOutline.bag5,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppDims.s2),
                        Expanded(
                          child: _CategoryMiniInfo(
                            label: 'Sub',
                            value: '$subCategoryCount',
                            icon: SolarIconsOutline.widget,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: AppDims.s2),
                        Expanded(
                          child: _CategoryMiniInfo(
                            label: 'Status',
                            value: isActive ? 'Live' : 'Off',
                            icon: isActive
                                ? SolarIconsOutline.checkCircle
                                : SolarIconsOutline.pauseCircle,
                            color: isActive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

class _CategoryMiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CategoryMiniInfo({
    required this.label,
    required this.value,
    required this.icon,
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
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
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

class _CachePill extends StatelessWidget {
  const _CachePill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        'OFFLINE',
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