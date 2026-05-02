import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == categories.length - 1 ? 0 : AppDims.s3,
            ),
            child: _CategoryCard(category: categories[index])
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 50 + (index * 35)),
              duration: 260.ms,
            )
                .slideY(
              begin: 0.04,
              end: 0,
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

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<CategoryBloc>(),
              child: CategoryDetailScreen(category: category),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  Icons.layers_rounded,
                  size: 26,
                  color: colors.primary,
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
                      style: AppTextStyles.bs500(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.description?.trim().isNotEmpty == true
                          ? category.description!.trim()
                          : 'No description added',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDims.s2),
                    Row(
                      children: [
                        if (childCount > 0) ...[
                          _ChildBadge(count: childCount),
                          const SizedBox(width: AppDims.s2),
                        ],
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textHint,
                    size: 20,
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
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 12,
            color: colors.textHint,
          ),
          const SizedBox(width: 4),
          Text(
            '$count sub',
            style: AppTextStyles.bs100(context).copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textHint,
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: active ? const Color(0xFF16A34A) : colors.textHint,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final id = category.id;
        if (id == null) return;

        context.read<CategoryBloc>().add(
          OnToggleCategoryActive(
            categoryId: id,
            isActive: !isActive,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF22C55E).withValues(alpha: 0.18)
              : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? const Color(0xFF22C55E).withValues(alpha: 0.30)
                : colors.border,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF16A34A) : colors.textHint,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}