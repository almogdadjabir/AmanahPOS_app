import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Teal net-sales card at the top of Reports (HTML `.hero2`).
class ReportHero extends StatelessWidget {
  final SalesReportSummary summary;

  const ReportHero({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final ink = colors.heroInk;
    final soft = ink.withValues(alpha: 0.82);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.heroGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.rpNetSales, style: TextStyle(fontSize: 14, color: soft)),
          const SizedBox(height: 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: saleNumber(summary.netSalesAmount),
                      style: TextStyle(
                        fontSize: 42,
                        height: 46 / 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.26,
                        color: ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: ' ${tr.shUnit}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr.rpFromSales(
              saleNumber(summary.salesCount),
              saleNumber(summary.averageSaleAmount),
            ),
            style: TextStyle(fontSize: 14, color: soft),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ink.withValues(alpha: 0.2)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  _Stat(
                    value: saleNumber(summary.grossSalesAmount),
                    label: tr.rpGross,
                  ),
                  _Stat(
                    value: '−${saleNumber(summary.refundAmount)}',
                    label: tr.rpReturns,
                  ),
                  _Stat(
                    value: saleNumber(summary.totalTaxCollected),
                    label: tr.rpTax,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final ink = context.appColors.heroInk;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.78)),
          ),
        ],
      ),
    );
  }
}
