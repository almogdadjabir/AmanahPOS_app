import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopCategorySidebar extends StatelessWidget {
  const DesktopCategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 160,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CompactStatsBlock(),
            Divider(height: 1, thickness: 1, color: colors.border),
            const Expanded(child: _CategoryList()),
          ],
        ),
      ),
    );
  }
}

// ── Compact stats block ───────────────────────────────────────────────────────

class _CompactStatsBlock extends StatelessWidget {
  const _CompactStatsBlock();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.summary != curr.summary,
      builder: (context, dashState) {
        final authState = context.read<AuthBloc>().state;
        final summary = dashState.summary;
        final shift = summary?.shift;
        final isCashier = authState.permissions.isCashier;

        final name = isCashier
            ? (shift?.cashierName?.trim().isNotEmpty == true
                ? shift!.cashierName!
                : authState.profile?.fullName ?? 'Cashier')
            : context.tr.posTodaySales;

        final amount = isCashier
            ? (shift?.grossSalesAmount ?? summary?.today.grossSalesAmount ?? 0)
            : (summary?.today.grossSalesAmount ?? 0);

        final salesCount = isCashier
            ? (shift?.salesCount ?? summary?.today.salesCount ?? 0)
            : (summary?.today.salesCount ?? 0);

        final currency = summary?.currency ?? 'SDG';

        return Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sm200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt(amount)} $currency',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs500(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$salesCount sales',
                style: AppTextStyles.sm100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(dynamic value) {
    final v = double.tryParse(value.toString()) ?? 0.0;
    final formatted = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

// ── Category list ─────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) => prev.categories != curr.categories,
      builder: (context, productState) {
        final categories = productState.categories;

        return BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) =>
              prev.selectedCategoryId != curr.selectedCategoryId,
          builder: (context, posState) {
            final selectedId = posState.selectedCategoryId;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const _SectionLabel(),
                _CategoryItem(
                  label: context.tr.posAllCategory,
                  isSelected: selectedId == null,
                  onTap: () => context
                      .read<PosBloc>()
                      .add(const PosCategoryChanged(null)),
                ),
                for (final category in categories)
                  _CategoryItem(
                    key: ValueKey(category.id),
                    label: category.name?.trim().isNotEmpty == true
                        ? category.name!.trim()
                        : 'Category',
                    isSelected: selectedId == category.id,
                    onTap: () => context
                        .read<PosBloc>()
                        .add(PosCategoryChanged(category.id)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s3, AppDims.s2, AppDims.s3, AppDims.s1),
      child: Text(
        'CATEGORIES',
        style: AppTextStyles.sm100(context).copyWith(
          color: context.appColors.textHint,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          height: 1,
        ),
      ),
    );
  }
}

// ── Category item ─────────────────────────────────────────────────────────────

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: isSelected ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2 + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsetsDirectional.only(end: AppDims.s2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : colors.border,
              ),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
