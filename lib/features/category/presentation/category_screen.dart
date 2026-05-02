import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_error_view.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_list.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const OnCategoryInitial());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocBuilder<CategoryBloc, CategoryState>(
        buildWhen: (prev, curr) =>
        prev.categoryStatus != curr.categoryStatus ||
            prev.categoryList != curr.categoryList,
        builder: (context, state) {
          return switch (state.categoryStatus) {
            CategoryStatus.initial ||
            CategoryStatus.loading => const ProductLoadingView(isGrid: false),

            CategoryStatus.failure => CategoryErrorView(
              message: state.responseError,
            ),

            CategoryStatus.success => state.categoryList.isEmpty
                ? const ProductEmptyView(
              title: 'No categories yet',
              message:
              'Create your first category to organize products and speed up selling.',
            )
                : _CategoriesContent(categories: state.categoryList),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddCategorySheet(context),
        backgroundColor: context.appColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Category',
          style: AppTextStyles.bs300(context).copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  final List<CategoryData> categories;

  const _CategoriesContent({
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
              child: _CategoriesHeader(categories: categories)
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
              child: _CategoryStats(categories: categories)
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

class _CategoriesHeader extends StatelessWidget {
  final List<CategoryData> categories;

  const _CategoriesHeader({
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
            child: Icon(
              Icons.layers_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Categories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Group products into simple sections for faster checkout and cleaner inventory.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStats extends StatelessWidget {
  final List<CategoryData> categories;

  const _CategoryStats({
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final active = categories.where((c) => c.isActive == true).length;
    final inactive = categories.length - active;
    final subCategories = categories.fold<int>(
      0,
          (total, c) => total + (c.children?.length ?? 0),
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.layers_outlined,
            label: 'Total',
            value: '${categories.length}',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Active',
            value: '$active',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: Icons.pause_circle_outline_rounded,
            label: 'Inactive',
            value: '$inactive',
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: Icons.account_tree_outlined,
            label: 'Sub',
            value: '$subCategories',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: colors.primary,
          ),
          const SizedBox(height: AppDims.s1),
          Text(
            value,
            style: AppTextStyles.bs400(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}