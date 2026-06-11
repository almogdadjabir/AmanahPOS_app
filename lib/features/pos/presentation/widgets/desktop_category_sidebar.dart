import 'dart:math' as math;

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
      width: 200,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top accent bar — marks this as the active navigation panel
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.30),
                  ],
                ),
              ),
            ),
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

        final sparkline = summary?.sparklineAmounts.isNotEmpty == true
            ? summary!.sparklineAmounts
            : const <double>[0, 0];

        String? shiftLabel;
        if (isCashier && shift?.shiftStartedAt != null) {
          final start =
              DateTime.tryParse(shift!.shiftStartedAt!) ?? DateTime.now();
          final diff = DateTime.now().difference(start);
          final h = diff.inHours;
          final m = diff.inMinutes.remainder(60);
          shiftLabel = '$h:${m.toString().padLeft(2, '0')}';
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(AppDims.s3),
          padding: const EdgeInsets.fromLTRB(
            AppDims.s3,
            AppDims.s3,
            AppDims.s3,
            AppDims.s2,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: isDark ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: colors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (shiftLabel != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        shiftLabel,
                        style: AppTextStyles.sm100(context).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_fmt(amount)} $currency',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$salesCount ${context.tr.salesChipLabel.toLowerCase()}',
                style: AppTextStyles.sm100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              SizedBox(
                width: double.infinity,
                height: 26,
                child: CustomPaint(
                  painter: _SidebarSparklinePainter(
                    data: sparkline,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(num value) {
    final v = value.toDouble();
    final formatted =
        v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

// ── Mini sparkline painter ────────────────────────────────────────────────────

class _SidebarSparklinePainter extends CustomPainter {
  _SidebarSparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxV = data.reduce(math.max);
    final minV = data.reduce(math.min);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final strokePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalized = (data[i] - minV) / range;
      final y = size.height - 2 - normalized * (size.height - 4);

      if (i == 0) {
        strokePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
      } else {
        strokePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.00),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      strokePath,
      Paint()
        ..color = color.withValues(alpha: 0.80)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SidebarSparklinePainter old) =>
      old.data != data || old.color != color;
}

// ── Category list ─────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) =>
          prev.categories != curr.categories ||
          prev.products != curr.products,
      builder: (context, productState) {
        final categories = productState.categories;

        // Compute active product count per category for at-a-glance navigation
        final counts = <String?, int>{};
        for (final product in productState.products) {
          if (product.isActive ?? true) {
            counts[product.category] =
                (counts[product.category] ?? 0) + 1;
          }
        }
        final totalCount =
            counts.values.fold<int>(0, (a, b) => a + b);

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
                  count: totalCount,
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
                    count: counts[category.id] ?? 0,
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

// ── Category item — desktop-optimised with hover feedback ─────────────────────

class _CategoryItem extends StatefulWidget {
  const _CategoryItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = widget.isSelected;
    final showCount = widget.count != null && widget.count! > 0;

    return MouseRegion(
      cursor: isSelected
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: isSelected ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : _hovered
                ? colors.surfaceSoft.withValues(alpha: 0.65)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3,
            vertical: AppDims.s2 + 2,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 7,
                height: 7,
                margin: const EdgeInsetsDirectional.only(end: AppDims.s2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colors.primary
                      : _hovered
                      ? colors.textSecondary
                      : colors.border,
                ),
              ),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: isSelected
                        ? colors.primary
                        : _hovered
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.border.withValues(
                            alpha: _hovered ? 0.9 : 0.55,
                          ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: AppTextStyles.sm100(context).copyWith(
                      color: isSelected
                          ? colors.primary
                          : colors.textHint,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
