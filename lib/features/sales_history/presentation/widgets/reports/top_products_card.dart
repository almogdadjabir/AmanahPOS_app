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
          .map((p) => (name: p.name, amount: p.grossAmount))
          .toList(),
      emptyMessage: context.tr.reportsNoSalesInRange,
    );
  }
}

// ─── Shared ranked-list shell (public so top_categories_card.dart can import) ─

class RankedListCard extends StatelessWidget {
  const RankedListCard({
    super.key,
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<({String name, double amount})> items;
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
            style: AppTextStyles.sm300(
              context,
              weight: AppTextStyles.semibold,
            ),
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
                        name: item.name,
                        amount: item.amount,
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
    required this.name,
    required this.amount,
    required this.ratio,
    required this.colors,
    required this.context,
  });

  final String name;
  final double amount;
  final double ratio;
  final AppThemeColors colors;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDims.s2),
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
              Text(
                AppFormat.compactMoney(amount),
                style: AppTextStyles.sm100(
                  context,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s1),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            valueColor: const AlwaysStoppedAnimation<Color>(
              SalesReportColors.rankBar,
            ),
            backgroundColor: colors.border,
            borderRadius: BorderRadius.circular(AppDims.rXs),
          ),
        ],
      ),
    );
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
