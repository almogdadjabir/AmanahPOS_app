import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_cards.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ReportRankedRow {
  final String name;
  final double quantity;
  final double amount;

  const ReportRankedRow({
    required this.name,
    required this.quantity,
    required this.amount,
  });
}

/// Ranked list with a thin proportional bar under each name (top products,
/// top categories).
class ReportRankedCard extends StatelessWidget {
  final String title;
  final List<ReportRankedRow> rows;

  const ReportRankedCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final max = rows.isEmpty ? 0.0 : rows.first.amount;

    return ReportCard(
      title: title,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: colors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          tr.rpSold(saleQty(rows[i].quantity)),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 4,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ColoredBox(color: colors.surfaceSoft),
                                ),
                                Positioned.fill(
                                  child: FractionallySizedBox(
                                    alignment: AlignmentDirectional.centerStart,
                                    widthFactor: max <= 0
                                        ? 0
                                        : (rows[i].amount / max).clamp(0, 1),
                                    child: ColoredBox(color: colors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      saleNumber(rows[i].amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
