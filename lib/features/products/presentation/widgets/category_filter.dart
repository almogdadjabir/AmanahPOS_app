import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  const CategoryFilterDelegate();

  static const double _height = 58;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
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
      child: BlocSelector<ProductBloc, ProductState, _CategoryFilterData>(
        selector: (state) {
          return _CategoryFilterData(
            categories: state.categories,
            selectedCategoryId: state.selectedCategoryId,
          );
        },
        builder: (context, data) {
          final categories = data.categories;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s2,
            ),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppDims.s2),
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : categories[index - 1];

              final isSelected = isAll
                  ? data.selectedCategoryId == null
                  : data.selectedCategoryId == category?.id;

              return CategoryChip(
                label: isAll
                    ? context.tr.allProducts
                    : category?.name?.trim().isNotEmpty == true
                    ? category!.name!.trim()
                    : context.tr.unknownCategory,
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
  bool shouldRebuild(covariant CategoryFilterDelegate oldDelegate) => false;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
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
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterData {
  final List<dynamic> categories;
  final String? selectedCategoryId;

  const _CategoryFilterData({
    required this.categories,
    required this.selectedCategoryId,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CategoryFilterData &&
            other.categories == categories &&
            other.selectedCategoryId == selectedCategoryId;
  }

  @override
  int get hashCode => Object.hash(categories, selectedCategoryId);
}