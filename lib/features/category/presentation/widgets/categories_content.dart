import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/categories_header.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class CategoriesContent extends StatefulWidget {
  final List<CategoryData> categories;

  const CategoriesContent({
    super.key,
    required this.categories,
  });

  @override
  State<CategoriesContent> createState() => _CategoriesContentState();
}

class _CategoriesContentState extends State<CategoriesContent> {
  CategoryQuickFilter _selectedFilter = CategoryQuickFilter.all;

  void _onFilterChanged(CategoryQuickFilter filter) {
    if (_selectedFilter == filter) return;

    setState(() {
      _selectedFilter = filter;
    });
  }

  List<CategoryData> get _filteredCategories {
    switch (_selectedFilter) {
      case CategoryQuickFilter.all:
        return widget.categories;

      case CategoryQuickFilter.active:
        return widget.categories.where((category) {
          return category.isActive == true;
        }).toList(growable: false);

      case CategoryQuickFilter.inactive:
        return widget.categories.where((category) {
          return category.isActive != true;
        }).toList(growable: false);

      case CategoryQuickFilter.withSubCategories:
        return widget.categories.where((category) {
          return (category.children?.length ?? 0) > 0;
        }).toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filteredCategories = _filteredCategories;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async {
        context.read<CategoryBloc>().add(const OnCategoryInitial());
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: CategoriesHeader(
                categories: widget.categories,
                selectedFilter: _selectedFilter,
                onFilterChanged: _onFilterChanged,
              )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(
                begin: 0.04,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s5,
              AppDims.s4,
              AppDims.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _sectionTitle,
                      style: AppTextStyles.bs700(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showAddCategorySheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s2,
                      ),
                      minimumSize: const Size(0, 38),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      SolarIconsOutline.addCircle,
                      size: 18,
                    ),
                    label: Text(
                      'Add Category',
                      style: AppTextStyles.bs300(context).copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (filteredCategories.isEmpty)
            SliverToBoxAdapter(
              child: _CategoryFilterEmptyView(filter: _selectedFilter),
            )
          else
            SliverToBoxAdapter(
              child: CategoryList(categories: filteredCategories),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  String get _sectionTitle {
    switch (_selectedFilter) {
      case CategoryQuickFilter.all:
        return 'Categories';
      case CategoryQuickFilter.active:
        return 'Active Categories';
      case CategoryQuickFilter.inactive:
        return 'Inactive Categories';
      case CategoryQuickFilter.withSubCategories:
        return 'Categories With Sub Categories';
    }
  }
}

class _CategoryFilterEmptyView extends StatelessWidget {
  final CategoryQuickFilter filter;

  const _CategoryFilterEmptyView({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = switch (filter) {
      CategoryQuickFilter.all => 'No categories yet',
      CategoryQuickFilter.active => 'No active categories',
      CategoryQuickFilter.inactive => 'No inactive categories',
      CategoryQuickFilter.withSubCategories => 'No sub categories found',
    };

    final message = switch (filter) {
      CategoryQuickFilter.all =>
      'Create your first category to organize products.',
      CategoryQuickFilter.active =>
      'No categories are currently active.',
      CategoryQuickFilter.inactive =>
      'All categories are currently active.',
      CategoryQuickFilter.withSubCategories =>
      'No categories have sub categories yet.',
    };

    final icon = switch (filter) {
      CategoryQuickFilter.all => SolarIconsOutline.layersMinimalistic,
      CategoryQuickFilter.active => SolarIconsOutline.checkCircle,
      CategoryQuickFilter.inactive => SolarIconsOutline.pauseCircle,
      CategoryQuickFilter.withSubCategories => SolarIconsOutline.widget,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s8,
        AppDims.s4,
        AppDims.s4,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              icon,
              size: 34,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}