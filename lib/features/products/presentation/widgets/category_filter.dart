import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.appColors.background,
      child: BlocBuilder<ProductBloc, ProductState>(
        buildWhen: (prev, curr) =>
        prev.categories != curr.categories ||
            prev.selectedCategoryId != curr.selectedCategoryId,
        builder: (context, state) {
          final categories = state.categories;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: AppDims.s2),
            itemCount: categories.length + 1,  // +1 for "All"
            separatorBuilder: (_, __) =>
            const SizedBox(width: AppDims.s2),
            itemBuilder: (context, i) {
              // index 0 = "All"
              final isAll = i == 0;
              final category = isAll ? null : categories[i - 1];
              final isSelected = isAll
                  ? state.selectedCategoryId == null
                  : state.selectedCategoryId == category!.id;

              return CategoryChip(
                label: isAll ? 'All' : category!.name ?? '',
                isSelected: isSelected,
                onTap: () => context.read<ProductBloc>().add(
                  OnProductCategorySelected(
                      categoryId: isAll ? null : category!.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(CategoryFilterDelegate _) => false;
}

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppDims.s2),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.primary
              : context.appColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? context.appColors.primary
                : context.appColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bs400(context).copyWith(
            fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}