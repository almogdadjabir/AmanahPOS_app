import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/edit_category_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryDetailScreen extends StatelessWidget {
  final CategoryData category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryBloc, CategoryState, CategoryData?>(
      selector: (state) {
        // Search top-level and inside children
        for (final c in state.categoryList) {
          if (c.id == category.id) return c;
          final child = c.children
              ?.where((ch) => ch.id == category.id)
              .firstOrNull;
          if (child != null) return child;
        }
        return category;
      },
      builder: (context, data) {
        final c = data ?? category;
        return Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            slivers: [
              _CategoryAppBar(category: c),
              SliverPadding(
                padding: const EdgeInsets.all(AppDims.s4),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _InfoSection(category: c),
                    const SizedBox(height: AppDims.s5),
                    _SubcategoriesSection(
                        category: c, children: c.children ?? []),
                    const SizedBox(height: AppDims.s6),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryAppBar extends StatelessWidget {
  final CategoryData category;
  const _CategoryAppBar({required this.category});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: context.appColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded,
            color: context.appColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () => showEditCategorySheet(context, category: category),
          icon: Icon(Icons.edit_outlined,
              size: 20, color: context.appColors.textPrimary),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.appColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 56),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(Icons.layers_rounded,
                    size: 30, color: context.appColors.primary),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                category.name ?? '—',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final CategoryData category;
  const _InfoSection({required this.category});

  @override
  Widget build(BuildContext context) {
    final isActive = category.isActive ?? false;
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.circle,
            iconColor: isActive
                ? const Color(0xFF22C55E)
                : context.appColors.textHint,
            label: 'Status',
            value: isActive ? 'Active' : 'Inactive',
          ),
          _Divider(),
          if (category.description != null) ...[
            _InfoRow(
              icon: Icons.notes_rounded,
              label: 'Description',
              value: category.description!,
            ),
            _Divider(),
          ],
          _InfoRow(
            icon: Icons.sort_rounded,
            label: 'Sort Order',
            value: '${category.sortOrder ?? 0}',
          ),
          _Divider(),
          _InfoRow(
            icon: category.parent != null
                ? Icons.account_tree_outlined
                : Icons.layers_rounded,
            label: 'Type',
            value: category.parent != null ? 'Subcategory' : 'Top Level',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SubcategoriesSection extends StatelessWidget {
  final CategoryData category;
  final List<CategoryData> children;
  const _SubcategoriesSection(
      {required this.category, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SUBCATEGORIES',
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: context.appColors.textHint,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              // onPressed: () => showAddCategorySheet(
              //   context,
              //   parentId: category.id,
              //   parentName: category.name,
              // ),
              onPressed: (){},
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Add Sub',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s2),
        if (children.isEmpty)
          _EmptySubcategories()
        else
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  _SubcategoryTile(child: children[i]),
                  if (i < children.length - 1) _Divider(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  final CategoryData child;
  const _SubcategoryTile({required this.child});

  @override
  Widget build(BuildContext context) {
    final isActive = child.isActive ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 16, color: context.appColors.textHint),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              child.name ?? '—',
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
        ],
      ),
    );
  }
}

class _EmptySubcategories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s5),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 28, color: context.appColors.textHint),
          const SizedBox(height: AppDims.s2),
          Text(
            'No subcategories yet',
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color: iconColor ?? context.appColors.textHint),
          const SizedBox(width: AppDims.s3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1, thickness: 1,
    indent: AppDims.s4,
    color: context.appColors.border,
  );
}