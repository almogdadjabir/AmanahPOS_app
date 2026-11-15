import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_format.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Payment split: one segment and one row per method (cash amber,
/// Bankak indigo, everything else neutral). Percentages add up to 100.
class HomePaymentsCard extends StatelessWidget {
  final TodaySalesSummary today;

  const HomePaymentsCard({super.key, required this.today});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final rows = _rows(tr, colors);
    final percents = _percents(rows.map((r) => r.amount).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionLabel(tr.homePayments),
        HomeCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 10,
                    child: percents.every((p) => p == 0)
                        ? ColoredBox(color: colors.surfaceSoft)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < rows.length; i++)
                                if (percents[i] > 0) ...[
                                  if (i > 0 &&
                                      percents.take(i).any((p) => p > 0))
                                    const SizedBox(width: 3),
                                  Expanded(
                                    flex: percents[i],
                                    child: ColoredBox(color: rows[i].color),
                                  ),
                                ],
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const HomeHairline(indent: 22),
                _PayRow(
                  color: rows[i].color,
                  label: rows[i].label,
                  amount: rows[i].amount,
                  percent: percents[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Cash and Bankak always show; other methods only when they have sales.
  List<_Pay> _rows(AppLocalizations tr, AppThemeColors colors) {
    final breakdown = today.paymentBreakdown;
    double of(String m) {
      for (final e in breakdown) {
        if (e.method == m) return e.amount;
      }
      return m == 'cash' ? today.cashAmount : today.bankakAmount;
    }

    final rows = <_Pay>[
      _Pay(tr.cash, of('cash'), colors.cash),
      _Pay(tr.bankak, of('bankak'), colors.card),
    ];

    for (final e in breakdown) {
      if (e.method == 'cash' || e.method == 'bankak' || e.amount <= 0) continue;
      rows.add(_Pay(_label(tr, e.method), e.amount, colors.borderStrong));
    }

    // Older servers send no breakdown: fold the rest into one row.
    if (breakdown.isEmpty && today.otherAmount > 0) {
      rows.add(_Pay(tr.homePayOther, today.otherAmount, colors.borderStrong));
    }
    return rows;
  }

  String _label(AppLocalizations tr, String method) => switch (method) {
    'card' => tr.homePayCard,
    'bank_transfer' => tr.homePayBankTransfer,
    'mobile_wallet' => tr.homePayWallet,
    'loyalty_points' => tr.homePayLoyalty,
    'credit' => tr.homePayCredit,
    'split' => tr.homePaySplit,
    _ => tr.homePayOther,
  };

  /// Largest-remainder rounding so the shown percentages sum to 100.
  List<int> _percents(List<double> amounts) {
    final total = amounts.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return List.filled(amounts.length, 0);

    final raw = [for (final a in amounts) a / total * 100];
    final floors = [for (final r in raw) r.floor()];
    var left = 100 - floors.fold<int>(0, (a, b) => a + b);
    final order = List.generate(raw.length, (i) => i)
      ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));
    for (final i in order) {
      if (left <= 0) break;
      floors[i]++;
      left--;
    }
    return floors;
  }
}

class _Pay {
  final String label;
  final double amount;
  final Color color;

  const _Pay(this.label, this.amount, this.color);
}

class _PayRow extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;
  final int percent;

  const _PayRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: text.bodyLarge!.copyWith(
                fontSize: 17,
                color: colors.textPrimary,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              homeMoney(amount),
              style: text.titleMedium!
                  .copyWith(color: colors.textPrimary)
                  .tabular,
            ),
          ),
          SizedBox(
            width: 48,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '$percent%',
                  style: text.bodySmall!
                      .copyWith(fontSize: 13, color: colors.textHint)
                      .tabular,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
