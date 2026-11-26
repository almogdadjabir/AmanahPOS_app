import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/providers/feature_bloc_providers.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/customer_detail_screen.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:flutter/material.dart';

import '../data/debt_reader.dart';
import '../domain/debt.dart';

/// Customers who owe money, biggest first, with the total. Reached from More
/// while On account is switched on.
class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key, this.reader});

  final DebtReader? reader;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final r = reader ?? getIt<DebtReader>();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SettingsNavBar(backLabel: tr.back),
            Expanded(
              child: StreamBuilder<List<Debtor>>(
                stream: r.watchDebtors(),
                builder: (context, snap) {
                  final list = snap.data ?? const <Debtor>[];
                  final total = list.fold<BigInt>(
                    BigInt.zero,
                    (a, d) => a + d.balance,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      MediaQuery.viewPaddingOf(context).bottom + 24,
                    ),
                    children: [
                      AppLargeTitle(title: tr.dtDebtsTitle),
                      if (snap.hasData && list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppDims.s6),
                          child: Text(
                            tr.dtNoDebts,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium!.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      else if (list.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppDims.s4),
                          margin: const EdgeInsets.only(bottom: AppDims.s4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppDims.s4),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.dtTotalOwed,
                                style: text.labelLarge!.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                shiftMoney(total),
                                textDirection: TextDirection.ltr,
                                style: text.headlineMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                tr.dtCustomersCount('${list.length}'),
                                style: text.bodySmall!.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                tr.dtFromPhone,
                                style: text.bodySmall!.copyWith(
                                  color: colors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppGroup(
                          children: [
                            for (final d in list)
                              AppGroupRow(
                                title: d.name.isEmpty ? '—' : d.name,
                                value: shiftMoney(d.balance),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => FeatureBlocProviders.customers(
                                      child: CustomerDetailScreen(
                                        customer: CustomerData(
                                          id: d.customerId,
                                          name: d.name,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
