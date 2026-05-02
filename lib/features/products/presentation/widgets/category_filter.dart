import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.background,
        boxShadow: overlapsContent
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: BlocBuilder<ProductBloc, ProductState>(
        buildWhen: (prev, curr) =>
        prev.categories != curr.categories ||
            prev.selectedCategoryId != curr.selectedCategoryId,
        builder: (context, state) {
          final categories = state.categories;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppDims.s2),
            itemBuilder: (context, i) {
              final isAll = i == 0;
              final category = isAll ? null : categories[i - 1];

              final isSelected = isAll
                  ? state.selectedCategoryId == null
                  : state.selectedCategoryId == category?.id;

              return CategoryChip(
                label: isAll ? 'All Products' : category?.name ?? '—',
                isSelected: isSelected,
                onTap: () {
                  context.read<ProductBloc>().add(
                    OnProductCategorySelected(
                      categoryId: isAll ? null : category?.id,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CategoryFilterDelegate oldDelegate) => true;
}

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}