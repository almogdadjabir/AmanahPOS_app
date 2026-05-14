import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class CategoryList extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoryList({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        0,
        AppDims.s4,
        0,
      ),
      child: Column(
        children: List.generate(categories.length, (index) {
          final category = categories[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == categories.length - 1 ? 0 : AppDims.s3,
            ),
            child: _CategoryCard(category: category)
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 24 + (index % 6) * 18),
              duration: 220.ms,
            )
                .slideY(
              begin: 0.025,
              end: 0,
              duration: 220.ms,
              curve: Curves.easeOutCubic,
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryData category;

  const _CategoryCard({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = category.isActive ?? false;
    final childCount = category.children?.length ?? 0;

    final name = category.name?.trim().isNotEmpty == true
        ? category.name!.trim()
        : 'Category';

    final description = category.description?.trim().isNotEmpty == true
        ? category.description!.trim()
        : 'No description added';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                return BlocProvider.value(
                  value: context.read<CategoryBloc>(),
                  child: CategoryDetailScreen(category: category),
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: colors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  SolarIconsOutline.layersMinimalistic,
                  size: 27,
                  color: colors.primary,
                ),
              ),

              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppDims.s2),
                    Wrap(
                      spacing: AppDims.s2,
                      runSpacing: AppDims.s1,
                      children: [
                        if (childCount > 0) _ChildBadge(count: childCount),
                        _StatusBadge(active: isActive),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDims.s2),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ActiveToggle(category: category),
                  const SizedBox(height: AppDims.s3),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      SolarIconsOutline.altArrowRight,
                      color: colors.textHint,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildBadge extends StatelessWidget {
  final int count;

  const _ChildBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            SolarIconsOutline.widget,
            size: 13,
            color: colors.textHint,
          ),
          const SizedBox(width: 5),
          Text(
            '$count sub',
            style: AppTextStyles.bs100(context).copyWith(
              fontWeight: FontWeight.w900,
              color: colors.textSecondary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? const Color(0xFF16A34A) : colors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.20 : 0.12),
        ),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final CategoryData category;

  const _ActiveToggle({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = category.isActive ?? false;
    final colors = context.appColors;
    final activeColor = const Color(0xFF16A34A);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final id = category.id;
        if (id == null || id.trim().isEmpty) return;

        context.read<CategoryBloc>().add(
          OnToggleCategoryActive(
            categoryId: id,
            isActive: !isActive,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.16)
              : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.34)
                : colors.border,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isActive ? activeColor : colors.textHint,
              shape: BoxShape.circle,
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}