import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/categories_header.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_list.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_stats.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesContent extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoriesContent({super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.appColors.primary,
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
              child: CategoriesHeader(categories: categories)
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .slideY(
                begin: 0.06,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: CategoryStats(categories: categories)
                  .animate()
                  .fadeIn(delay: 70.ms, duration: 320.ms)
                  .slideY(
                begin: 0.06,
                end: 0,
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
                      'Categories',
                      style: AppTextStyles.bs600(context).copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showAddCategorySheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 34),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
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

          SliverToBoxAdapter(
            child: CategoryList(categories: categories),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
