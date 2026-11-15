import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_cards.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Payment split: stacked bar plus one legend row per method.
/// Cash is amber, Bankak indigo, everything else slate.
class ReportPaymentsCard extends StatelessWidget {
  final List<PaymentMethodBreakdown> methods;

  const ReportPaymentsCard({super.key, required this.methods});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final total = methods.fold<double>(0, (a, m) => a + m.amount);

    Color colorOf(String m) => switch (m) {
      'cash' => colors.cash,
      'bankak' => colors.card,
      _ => colors.textSecondary,
    };
    int pct(double v) => total <= 0 ? 0 : (v / total * 100).round();

    return ReportCard(
      title: tr.rpPayments,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < methods.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: (methods[i].amount * 1000).round().clamp(
                          1,
                          1 << 30,
                        ),
                        child: ColoredBox(color: colorOf(methods[i].method)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < methods.length; i++)
            Container(
              constraints: const BoxConstraints(minHeight: 42),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: colors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorOf(methods[i].method),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      salePaymentName(context, methods[i].method),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: colors.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 44,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${pct(methods[i].amount)}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 14, color: colors.textHint),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 84),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        saleNumber(methods[i].amount),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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
