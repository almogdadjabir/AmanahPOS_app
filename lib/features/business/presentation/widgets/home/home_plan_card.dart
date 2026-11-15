import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_format.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:flutter/material.dart';

/// Slim subscription row: plan name, price, time-left bar and badge.
class HomePlanCard extends StatelessWidget {
  final BusinessData data;

  const HomePlanCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final sub = data.activeSubscription;

    final hasSub = sub != null;
    final isFree = sub?.isFree ?? true;
    final daysLeft = sub?.daysRemaining ?? 0;
    final isExpired = hasSub && !isFree && daysLeft <= 0;
    final soon = hasSub && !isFree && daysLeft > 0 && daysLeft <= 7;

    final accent = !hasSub
        ? colors.warning
        : isExpired
        ? colors.danger
        : soon
        ? colors.warning
        : colors.primary;
    final tint = !hasSub
        ? colors.warningContainer
        : isExpired
        ? colors.dangerContainer
        : soon
        ? colors.warningContainer
        : colors.primaryContainer;

    final title = sub?.name ?? tr.homePlanNone;
    final subtitle = !hasSub
        ? tr.homePlanContact
        : isFree
        ? tr.homePlanFree
        : _price(tr, sub.price, sub.currency, sub.billingPeriod) ??
              tr.homePlanPaid;
    final badge = !hasSub
        ? tr.homePlanInactive
        : isFree
        ? tr.homePlanNoExpiry
        : isExpired
        ? tr.homePlanExpired
        : tr.homePlanDaysLeft(daysLeft);

    final progress = !hasSub
        ? 0.0
        : isFree
        ? 1.0
        : isExpired
        ? 0.0
        : (daysLeft / _cycleDays(sub)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: HomeCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isFree && hasSub
                          ? PhosphorIconsRegular.gift
                          : PhosphorIconsRegular.medal,
                      size: 20,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge!.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!.copyWith(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: colors.surfaceSoft,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badge,
                      style: text.labelMedium!.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasSub) ...[
              const HomeHairline(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    tr.homePlanLimits(
                      _limit(sub.maxShops, tr.homePlanUnlimited),
                      _limit(sub.maxProducts, tr.homePlanUnlimited),
                      _limit(sub.maxUsers, tr.homePlanUnlimited),
                    ),
                    style: text.bodySmall!.copyWith(
                      fontSize: 13,
                      color: colors.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _limit(int? value, String unlimited) =>
      value == null || value <= 0 ? unlimited : '$value';

  /// Cycle length: the plan's own, else start to end date, else 30.
  int _cycleDays(ActiveSubscription sub) {
    final cycle = sub.billingCycleDays;
    if (cycle != null && cycle > 0) return cycle;

    final start = DateTime.tryParse(sub.startDate ?? '');
    final end = DateTime.tryParse(sub.endDate ?? '');
    if (start != null && end != null) {
      final days = end.difference(start).inDays;
      if (days > 0) return days;
    }
    return 30;
  }

  String? _price(
    AppLocalizations tr,
    String? price,
    String? currency,
    String? period,
  ) {
    final p = price?.trim() ?? '';
    if (p.isEmpty) return null;
    final value = double.tryParse(p);
    final shown = value == null ? p : homeMoney(value);
    final text = '$shown ${currency?.trim() ?? ''}'.trim();
    return switch (period) {
      'monthly' => tr.homePlanPriceMonthly(text),
      'yearly' => tr.homePlanPriceYearly(text),
      _ => text,
    };
  }
}
