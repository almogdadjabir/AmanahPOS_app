import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
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
        buildWhen: (prev, curr) => prev.categoryStatus != curr.categoryStatus,
        builder: (context, state) {
          return switch (state.categoryStatus) {
            CategoryStatus.initial ||
            CategoryStatus.loading => const _LoadingView(),
            CategoryStatus.failure  => _ErrorView(message: state.responseError),
            CategoryStatus.success  => state.categoryList.isEmpty
                ? const _EmptyView()
                : _CategoryList(categories: state.categoryList),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        // onPressed: () => showAddCategorySheet(context),
        onPressed: (){},
        backgroundColor: context.appColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 13,
            fontWeight: FontWeight.w800, color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, __) => _Skeleton(),
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      padding: const EdgeInsets.all(AppDims.s3),
      child: Row(
        children: [
          _Shimmer(width: 44, height: 44, radius: AppDims.rSm),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 120, height: 13, radius: 4),
                const SizedBox(height: 7),
                _Shimmer(width: 80, height: 11, radius: 4),
              ],
            ),
          ),
          _Shimmer(width: 44, height: 22, radius: 999),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: context.appColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: context.appColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.layers_rounded,
                  size: 36, color: context.appColors.primary),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              'No categories yet',
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              'Organise your products by creating your first category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String? message;
  const _ErrorView({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: context.appColors.textHint),
            const SizedBox(height: AppDims.s3),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDims.s2),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'NunitoSans', fontSize: 12,
                      color: context.appColors.textSecondary)),
            ],
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<CategoryBloc>()
                  .add(const OnCategoryInitial()),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final List<CategoryData> categories;
  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s4, AppDims.s4, 100),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
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
              // ── Icon ────────────────────────────────────────────────
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

              // ── Info ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 14,
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
                              style: TextStyle(
                                fontFamily: 'NunitoSans', fontSize: 11,
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

              // ── Status toggle ─────────────────────────────────────────
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
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 10,
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
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 10,
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