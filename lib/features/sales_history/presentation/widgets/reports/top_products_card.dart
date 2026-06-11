import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';

// ─── Public entry point ───────────────────────────────────────────────────────

class TopProductsCard extends StatelessWidget {
  const TopProductsCard({super.key, required this.products});

  final List<SalesTopProduct> products;

  @override
  Widget build(BuildContext context) {
    return RankedListCard(
      title: context.tr.topProductsTitle,
      items: products
          .map((p) => (
                name: p.name,
                amount: p.grossAmount,
                subtitle: _qtyLabel(p.quantitySold),
              ))
          .toList(),
      emptyMessage: context.tr.reportsNoSalesInRange,
    );
  }

  static String _qtyLabel(double qty) {
    if (qty <= 0) return '';
    final int q = qty.truncate();
    return q == qty ? '$q items' : '${qty.toStringAsFixed(1)} items';
  }
}

// ─── Shared ranked-list card (used by categories too) ────────────────────────

class RankedListCard extends StatelessWidget {
  const RankedListCard({
    super.key,
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<({String name, double amount, String? subtitle})> items;
  final String emptyMessage;

  static const int _maxItems = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = items.take(_maxItems).toList();
    final maxAmount =
        visible.isEmpty ? 1.0 : visible.map((i) => i.amount).reduce(_max);

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sm300(context, weight: AppTextStyles.semibold),
          ),
          const SizedBox(height: AppDims.s3),
          Expanded(
            child: visible.isEmpty
                ? _EmptyState(message: emptyMessage)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final ratio =
                          maxAmount > 0 ? item.amount / maxAmount : 0.0;
                      return _RankedRow(
                        rank: index + 1,
                        name: item.name,
                        amount: item.amount,
                        subtitle: item.subtitle,
                        ratio: ratio,
                        colors: colors,
                        context: context,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static double _max(double a, double b) => a > b ? a : b;
}

// ─── Single ranked row ────────────────────────────────────────────────────────

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.rank,
    required this.name,
    required this.amount,
    required this.ratio,
    required this.colors,
    required this.context,
    this.subtitle,
  });

  final int rank;
  final String name;
  final double amount;
  final double ratio;
  final String? subtitle;
  final AppThemeColors colors;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final barColor = _rankBarColor(rank);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDims.s2 + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sm200(
                          context,
                          weight: AppTextStyles.medium,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDims.s2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormat.compactMoney(amount),
                          style: AppTextStyles.sm200(
                            context,
                            weight: AppTextStyles.semibold,
                            color: barColor,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: AppTextStyles.sm100(
                              context,
                              color: colors.textHint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDims.s1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDims.rXs),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        backgroundColor: colors.border,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _rankBarColor(int rank) {
    return switch (rank) {
      1 => SalesReportColors.rankGold,
      2 => SalesReportColors.rankSilver,
      3 => SalesReportColors.rankBronze,
      _ => SalesReportColors.rankRest,
    };
  }
}

// ─── Rank badge ───────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _medal(rank);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: rank <= 3 ? 12 : 9,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1,
        ),
      ),
    );
  }

  static (Color bg, Color fg, String label) _medal(int rank) {
    return switch (rank) {
      1 => (
          SalesReportColors.rankGold.withAlpha(30),
          SalesReportColors.rankGold,
          '🥇',
        ),
      2 => (
          SalesReportColors.rankSilver.withAlpha(30),
          SalesReportColors.rankSilver,
          '🥈',
        ),
      3 => (
          SalesReportColors.rankBronze.withAlpha(30),
          SalesReportColors.rankBronze,
          '🥉',
        ),
      _ => (
          SalesReportColors.rankRest.withAlpha(15),
          SalesReportColors.rankRest,
          '$rank',
        ),
    };
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Text(
        message,
        style: AppTextStyles.sm200(context, color: colors.textHint),
      ),
    );
  }
}
