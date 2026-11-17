import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/features/category/presentation/category_form_screen.dart';
import 'package:amana_pos/features/sync/presentation/widgets/catalog_sync_pill.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void openCategoryDetail(BuildContext context, CategoryData category) {
  final categoryBloc = context.read<CategoryBloc>();

  Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(
        value: categoryBloc,
        child: CategoryDetailScreen(category: category),
      ),
    ),
  );
}

/// Grouped list of categories: tint tile, name, product count, chevron.
/// Swipe reveals Edit and Delete (owner/manager only: [canEdit]).
class CategoryListGroup extends StatelessWidget {
  final List<CategoryData> categories;
  final CatalogSyncMarks syncMarks;
  final bool canEdit;

  const CategoryListGroup({
    super.key,
    required this.categories,
    this.syncMarks = CatalogSyncMarks.none,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

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
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 44 + AppDims.s3,
                  color: colors.border,
                ),
              if (canEdit)
                AppSwipeActions(
                  actions: [
                    AppSwipeAction(
                      label: tr.edit,
                      icon: PhosphorIconsRegular.pencilSimple,
                      color: colors.primary,
                      onTap: () =>
                          openCategoryForm(context, category: categories[i]),
                    ),
                    AppSwipeAction(
                      label: tr.delete,
                      icon: PhosphorIconsRegular.trash,
                      color: colors.danger,
                      onTap: () =>
                          confirmDeleteCategory(context, categories[i]),
                    ),
                  ],
                  child: CategoryRow(
                    key: ValueKey(categories[i].id ?? i),
                    category: categories[i],
                    syncMark: syncMarks.markOf(categories[i].id),
                  ),
                )
              else
                CategoryRow(
                  key: ValueKey(categories[i].id ?? i),
                  category: categories[i],
                  syncMark: syncMarks.markOf(categories[i].id),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryRow extends StatelessWidget {
  final CategoryData category;

  /// "Not synced" / "Sync failed" pill after the name.
  final CatalogSyncMark syncMark;

  const CategoryRow({
    super.key,
    required this.category,
    this.syncMark = CatalogSyncMark.synced,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    final isActive = category.isActive != false;
    final name = category.name?.trim();
    final count = category.productCount;
    final description = category.description?.trim();
    final subtitle = count != null
        ? tr.pcCount('$count')
        : (description?.isNotEmpty == true ? description! : null);

    return Pressable(
      onTap: () => openCategoryDetail(context, category),
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            child: Row(
              children: [
                CategoryThumb(category: category, isActive: isActive),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name?.isNotEmpty == true ? name! : tr.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge!.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  tr.inactive,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (syncMark != CatalogSyncMark.synced) ...[
                            const SizedBox(width: 6),
                            CatalogSyncPill(mark: syncMark),
                          ],
                        ],
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(
                              fontSize: 13,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44px category tile: its image (a staged, not yet uploaded pick shows
/// first, then the downloaded/served one), else the tinted stack icon.
class CategoryThumb extends StatelessWidget {
  final CategoryData category;
  final bool isActive;
  final double size;

  const CategoryThumb({
    super.key,
    required this.category,
    this.isActive = true,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = [category.thumbnailUrl, category.image]
        .map((u) => u?.trim())
        .firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);
    final id = category.id;
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? colors.primaryContainer : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        PhosphorIconsRegular.stack,
        size: size / 2,
        color: isActive ? colors.primary : colors.disabled,
      ),
    );
    if (url == null && (id == null || id.isEmpty)) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: SizedBox(
        width: size,
        height: size,
        child: OfflineCachedImage(
          imageUrl: url,
          fit: BoxFit.cover,
          entityType: 'category',
          entityId: id,
          errorWidget: url == null ? icon : null,
        ),
      ),
    );
  }
}
