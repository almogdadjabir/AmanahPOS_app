import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/debt_reader.dart';
import '../domain/debt.dart';
import 'debt_action_sheet.dart';
import 'debts_scope.dart';

/// Balance, actions and ledger of one customer. Shows nothing while On account
/// is switched off, or while the customer has never had a debt record.
class CustomerDebtSection extends StatelessWidget {
  const CustomerDebtSection({
    super.key,
    required this.customerId,
    required this.canWriteOff,
  });

  final String customerId;
  final bool canWriteOff;

  @override
  Widget build(BuildContext context) {
    final features = getIt<BusinessFeaturesService>();
    return StreamBuilder<BusinessFeatures>(
      stream: features.changes,
      initialData: features.current,
      builder: (context, snap) {
        if (!(snap.data?.onAccount ?? true)) return const SizedBox.shrink();
        return _Body(customerId: customerId, canWriteOff: canWriteOff);
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.customerId, required this.canWriteOff});

  final String customerId;
  final bool canWriteOff;

  @override
  Widget build(BuildContext context) {
    final reader = getIt<DebtReader>();
    return StreamBuilder<List<DebtLedgerEntry>>(
      stream: reader.watchLedger(customerId),
      builder: (context, ledgerSnap) {
        final ledger = ledgerSnap.data ?? const <DebtLedgerEntry>[];
        return StreamBuilder<BigInt>(
          stream: reader.watchBalance(customerId),
          builder: (context, balSnap) {
            final balance = balSnap.data ?? BigInt.zero;
            if (ledger.isEmpty && balance == BigInt.zero) {
              return const SizedBox.shrink();
            }
            return _Content(
              customerId: customerId,
              canWriteOff: canWriteOff,
              balance: balance,
              ledger: ledger,
            );
          },
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.customerId,
    required this.canWriteOff,
    required this.balance,
    required this.ledger,
  });

  final String customerId;
  final bool canWriteOff;
  final BigInt balance;
  final List<DebtLedgerEntry> ledger;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final owes = balance > BigInt.zero;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(locale).add_Hm();

    String label(DebtLedgerEntry e) => switch (e.kind) {
      DebtLedgerKind.sale => tr.dtLedgerSale,
      DebtLedgerKind.payment => tr.dtLedgerPayment(
        e.method == 'bankak' ? tr.bankak : tr.cash,
      ),
      DebtLedgerKind.writeoff => tr.dtLedgerWriteOff,
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppDims.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.s4),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.dtOwesNow,
                  style: text.labelLarge!.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shiftMoney(balance),
                  textDirection: TextDirection.ltr,
                  style: text.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: owes ? colors.danger : colors.success,
                  ),
                ),
                Text(
                  tr.dtFromPhone,
                  style: text.bodySmall!.copyWith(color: colors.textHint),
                ),
                if (owes) ...[
                  const SizedBox(height: AppDims.s3),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: tr.dtReceive,
                          onPressed: () => showDebtActionSheet(
                            context,
                            service: buildDebtService(context),
                            mode: DebtSheetMode.receive,
                            customerId: customerId,
                            balance: balance,
                          ),
                        ),
                      ),
                      if (canWriteOff) ...[
                        const SizedBox(width: AppDims.s2),
                        Expanded(
                          child: AppButton(
                            label: tr.dtWriteOff,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => showDebtActionSheet(
                              context,
                              service: buildDebtService(context),
                              mode: DebtSheetMode.writeOff,
                              customerId: customerId,
                              balance: balance,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (ledger.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppDims.s4,
                bottom: AppDims.s2,
              ),
              child: Text(
                tr.dtHistory,
                style: text.labelLarge!.copyWith(color: colors.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDims.s4),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (final e in ledger)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDims.s3,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label(e),
                                  style: text.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  e.rejected
                                      ? tr.dtRejected
                                      : fmt.format(e.at.toLocal()),
                                  style: text.bodySmall!.copyWith(
                                    color: e.rejected
                                        ? colors.danger
                                        : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${e.adds ? '+' : '-'}${shiftMoney(e.amount)}',
                            textDirection: TextDirection.ltr,
                            style: text.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: e.rejected
                                  ? colors.textHint
                                  : e.adds
                                  ? colors.danger
                                  : colors.success,
                              decoration: e.rejected
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
