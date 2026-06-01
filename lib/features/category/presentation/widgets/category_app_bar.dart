import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/widgets/delete_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/edit_category_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
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
    final tr = context.tr;

    final rawName = category.name?.trim();
    final name = rawName?.isNotEmpty == true ? rawName! : tr.category;

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      toolbarHeight: 72,
      collapsedHeight: 72,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s3,
          AppDims.s1,
          AppDims.s3,
          AppDims.s1,
        ),
        child: Row(
          children: [
            _ToolbarIconButton(
              icon: SolarIconsOutline.altArrowLeft,
              tooltip: tr.back,
              flipInRtl: true,
              onTap: () => Navigator.of(context).pop(),
            ),

            const SizedBox(width: AppDims.s2),

            Expanded(
              child: _CategoryTitleBlock(
                name: name,
                productCount: productCount,
                isFromCache: isFromCache,
              ),
            ),

            const SizedBox(width: AppDims.s2),

            _ToolbarIconButton(
              icon: isGrid ? SolarIconsOutline.list : SolarIconsOutline.widget,
              tooltip: isGrid ? tr.showList : tr.showGrid,
              onTap: onToggleLayout,
            ),

            const SizedBox(width: AppDims.s1),

            _ToolbarIconButton(
              icon: SolarIconsOutline.addCircle,
              tooltip: tr.addProduct,
              color: colors.primary,
              backgroundColor: colors.primary.withValues(alpha: 0.08),
              borderColor: colors.primary.withValues(alpha: 0.18),
              onTap: onAddProduct,
            ),

            const SizedBox(width: AppDims.s1),

            _MoreActionsButton(category: category),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colors.border.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _CategoryTitleBlock extends StatelessWidget {
  final String name;
  final int productCount;
  final bool isFromCache;

  const _CategoryTitleBlock({
    required this.name,
    required this.productCount,
    required this.isFromCache,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs500(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              SolarIconsOutline.bag5,
              size: 13,
              color: colors.textHint,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                tr.productCountLabel(productCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            if (isFromCache) ...[
              const SizedBox(width: AppDims.s2),
              const _OfflineBadge(),
            ],
          ],
        ),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool flipInRtl;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.flipInRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(
                color: borderColor ?? colors.border,
              ),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: DirectionalIcon(
                  icon: icon,
                  size: 20,
                  color: color ?? colors.textPrimary,
                  flipInRtl: flipInRtl,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreActionsButton extends StatelessWidget {
  final CategoryData category;

  const _MoreActionsButton({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return PopupMenuButton<_CategoryAction>(
      tooltip: tr.moreActions,
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.rMd),
        side: BorderSide(color: colors.border),
      ),
      offset: const Offset(0, 44),
      onSelected: (action) {
        switch (action) {
          case _CategoryAction.edit:
            showEditCategorySheet(context, category: category);
            break;
          case _CategoryAction.delete:
            showDeleteCategorySheet(context, category: category);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _CategoryAction.edit,
            child: _PopupActionRow(
              icon: SolarIconsOutline.penNewSquare,
              label: tr.editCategory,
              color: colors.textPrimary,
            ),
          ),
          PopupMenuItem(
            value: _CategoryAction.delete,
            child: _PopupActionRow(
              icon: SolarIconsOutline.trashBinTrash,
              label: tr.delete,
              color: const Color(0xFFDC2626),
            ),
          ),
        ];
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: colors.border),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            SolarIconsOutline.menuDots,
            size: 20,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PopupActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PopupActionRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs300(context).copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0EA5E9);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s2,
          vertical: 3,
        ),
        child: Text(
          context.tr.offline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs100(context).copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

enum _CategoryAction {
  edit,
  delete,
}