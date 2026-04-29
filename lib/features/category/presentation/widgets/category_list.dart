import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class CategoryList extends StatelessWidget {
  final List<CategoryData> categories;
  const CategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s4, AppDims.s4, 100),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, i) => _CategoryCard(category: categories[i]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryData category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final isActive   = category.isActive ?? false;
    final childCount = category.children?.length ?? 0;

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<CategoryBloc>(),
            child: CategoryDetailScreen(category: category),
          ),
        )),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(Icons.layers_rounded,
                    size: 22, color: context.appColors.primary),
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (category.description != null) ...[
                          Flexible(
                            child: Text(
                              category.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs200(context).copyWith(
                              fontWeight: FontWeight.w600,
                                color: context.appColors.textHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDims.s2),
                        ],
                        if (childCount > 0)
                          _ChildBadge(count: childCount),
                      ],
                    ),
                  ],
                ),
              ),

              _ActiveToggle(category: category),
              const SizedBox(width: AppDims.s2),
              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildBadge extends StatelessWidget {
  final int count;
  const _ChildBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 10, color: context.appColors.textHint),
          const SizedBox(width: 3),
          Text(
            '$count sub',
            style: AppTextStyles.bs100(context).copyWith(
            fontWeight: FontWeight.w700,
              color: context.appColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final CategoryData category;
  const _ActiveToggle({required this.category});

  @override
  Widget build(BuildContext context) {
    final isActive = category.isActive ?? false;
    return GestureDetector(
      onTap: () => context.read<CategoryBloc>().add(
        OnToggleCategoryActive(
          categoryId: category.id!,
          isActive: !isActive,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF22C55E).withOpacity(0.12)
              : context.appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w800,
            color: isActive
                ? const Color(0xFF16A34A)
                : context.appColors.textHint,
          ),
        ),
      ),
    );
  }
}