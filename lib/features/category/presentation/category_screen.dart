import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/features/category/presentation/widgets/categories_content.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_error_view.dart';
import 'package:amana_pos/features/category/presentation/widgets/desktop_categories_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_empty_view.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_loading_view.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized || context.isDesktop) return;
    _initialized = true;
    context.read<CategoryBloc>().add(const OnCategoryInitial());
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const DesktopCategoriesView();

    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<CategoryBloc, CategoryState>(
        buildWhen: (prev, curr) {
          return prev.categoryStatus != curr.categoryStatus ||
              prev.categoryList != curr.categoryList;
        },
        builder: (context, state) {
          return switch (state.categoryStatus) {
            CategoryStatus.initial ||
            CategoryStatus.loading =>
            const ProductLoadingView(isGrid: false),

            CategoryStatus.failure => CategoryErrorView(
              message: state.responseError,
            ),

            CategoryStatus.success => state.categoryList.isEmpty
                ? ProductEmptyView(
              hasCategories: false,
              title: context.tr.noCategoriesYet,
              message:
              'Create your first category to organize products and speed up selling.',
              primaryActionText: context.tr.newCategory,
              onPrimaryAction: () => showAddCategorySheet(context),
            )
                : CategoriesContent(categories: state.categoryList),
          };
        },
      ),
      floatingActionButton: BlocBuilder<CategoryBloc, CategoryState>(
        buildWhen: (prev, curr) {
          return prev.categoryList != curr.categoryList ||
              prev.categoryStatus != curr.categoryStatus;
        },
        builder: (context, state) {
          final hasCategories = state.categoryList.isNotEmpty;
          final isLoading = state.categoryStatus == CategoryStatus.initial ||
              state.categoryStatus == CategoryStatus.loading;

          if (!hasCategories || isLoading) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => showAddCategorySheet(context),
            backgroundColor: colors.primary,
            icon: const Icon(
              SolarIconsOutline.addCircle,
              color: Colors.white,
            ),
            label: Text(
              context.tr.newCategory,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}