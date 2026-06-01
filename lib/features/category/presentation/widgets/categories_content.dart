import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
            padding: const EdgeInsetsDirectional.fromSTEB(
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
            padding: const EdgeInsetsDirectional.fromSTEB(
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
                      _sectionTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs700(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s2),
                  TextButton.icon(
                    onPressed: () => showAddCategorySheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsetsDirectional.symmetric(
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
                      context.tr.addCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _sectionTitle(BuildContext context) {
    switch (_selectedFilter) {
      case CategoryQuickFilter.all:
        return context.tr.all;
      case CategoryQuickFilter.active:
        return context.tr.activeCategories;
      case CategoryQuickFilter.inactive:
        return context.tr.inactiveCategories;
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
    final content = _CategoryEmptyContent.fromFilter(context, filter);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        AppDims.s8,
        AppDims.s4,
        AppDims.s4,
      ),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(color: colors.border),
            ),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                content.icon,
                size: 34,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            content.message,
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

class _CategoryEmptyContent {
  final String title;
  final String message;
  final IconData icon;

  const _CategoryEmptyContent({
    required this.title,
    required this.message,
    required this.icon,
  });

  factory _CategoryEmptyContent.fromFilter(
      BuildContext context,
      CategoryQuickFilter filter,
      ) {
    final tr = context.tr;

    switch (filter) {
      case CategoryQuickFilter.all:
        return _CategoryEmptyContent(
          title: tr.noCategoriesYet,
          message: tr.noCategoriesYetMessage,
          icon: SolarIconsOutline.layersMinimalistic,
        );

      case CategoryQuickFilter.active:
        return _CategoryEmptyContent(
          title: tr.noActiveCategories,
          message: tr.noActiveCategoriesMessage,
          icon: SolarIconsOutline.checkCircle,
        );

      case CategoryQuickFilter.inactive:
        return _CategoryEmptyContent(
          title: tr.noInactiveCategories,
          message: tr.noInactiveCategoriesMessage,
          icon: SolarIconsOutline.pauseCircle,
        );
    }
  }
}