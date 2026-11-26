import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/debts/data/debt_reader.dart';
import 'package:amana_pos/features/debts/presentation/customer_picker_sheet.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/presentation/widgets/split_payment_sheet.dart';
import 'package:amana_pos/features/pos/domain/split_payment.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class PaymentSelector extends StatelessWidget {
  const PaymentSelector({
    super.key,
    required this.paymentMethod,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppDims.s4,
      AppDims.s4,
      AppDims.s4,
      0,
    ),
  });

  final String paymentMethod;
  final EdgeInsetsGeometry padding;

  Future<void> _pickCustomer(BuildContext context, {bool thenAccount = false}) async {
    final bloc = context.read<PosBloc>();
    final c = await showCustomerPicker(context);
    if (c == null) return;
    bloc.add(PosCustomerSelected(id: c.id, name: c.name));
    if (thenAccount) bloc.add(const PosPaymentMethodChanged('credit'));
  }

  Future<void> _openSplit(
    BuildContext context, {
    required bool bankakReady,
    required bool accountOn,
  }) async {
    final bloc = context.read<PosBloc>();
    final total = Cents.parse(bloc.state.total.toStringAsFixed(2));
    if (total == null || total <= BigInt.zero) return;
    final parts = await showSplitPaymentSheet(
      context,
      total: total,
      bankakReady: bankakReady,
      accountEnabled: accountOn,
      accountCustomer: bloc.state.customerName,
      initial: bloc.state.splitParts,
    );
    if (parts != null) bloc.add(PosSplitConfirmed(parts));
  }

  @override
  Widget build(BuildContext context) {
    final features = getIt<BusinessFeaturesService>();
    return StreamBuilder<BusinessFeatures>(
      stream: features.changes,
      initialData: features.current,
      builder: (context, snap) => _build(
        context,
        snap.data?.splitPayments ?? true,
        snap.data?.onAccount ?? true,
      ),
    );
  }

  Widget _build(BuildContext context, bool splitOn, bool accountOn) {
    final colors = context.appColors;
    final isBankak = paymentMethod == 'bankak';
    final isSplit = paymentMethod == 'split';
    final isCredit = paymentMethod == 'credit';
    if ((isSplit && !splitOn) || (isCredit && !accountOn)) {
      // The owner switched it off while it was picked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<PosBloc>().add(const PosPaymentMethodChanged('cash'));
        }
      });
    }

    final bankakAccount = context.select<AuthBloc, String?>((bloc) {
      final account = bloc.state.profile?.bankakAccount?.accountNumber?.trim();
      return account == null || account.isEmpty ? null : account;
    });

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr.payment,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          AppSegmented<String>(
            selected: isSplit && splitOn
                ? 'split'
                : isCredit && accountOn
                ? 'credit'
                : (isBankak ? 'bankak' : 'cash'),
            onChanged: (value) {
              if (value == 'split') {
                _openSplit(
                  context,
                  bankakReady: bankakAccount != null,
                  accountOn: accountOn,
                );
              } else if (value == 'credit') {
                if (context.read<PosBloc>().state.customerId == null) {
                  _pickCustomer(context, thenAccount: true);
                } else {
                  context.read<PosBloc>().add(
                    const PosPaymentMethodChanged('credit'),
                  );
                }
              } else {
                context.read<PosBloc>().add(PosPaymentMethodChanged(value));
              }
            },
            segments: [
              AppSegment(
                value: 'cash',
                label: context.tr.cash,
                leading: _MethodChip(
                  icon: PhosphorIconsRegular.wallet,
                  background: colors.cashTint,
                  foreground: colors.cashInk,
                ),
              ),
              AppSegment(
                value: 'bankak',
                label: context.tr.bankak,
                leading: _MethodChip(
                  icon: PhosphorIconsRegular.creditCard,
                  background: colors.digitalTint,
                  foreground: colors.digitalInk,
                ),
              ),
              if (splitOn)
                AppSegment(
                  value: 'split',
                  label: context.tr.spOption,
                  leading: _MethodChip(
                    icon: PhosphorIconsRegular.arrowsLeftRight,
                    background: colors.surfaceSoft,
                    foreground: colors.textSecondary,
                  ),
                ),
              if (accountOn)
                AppSegment(
                  value: 'credit',
                  label: context.tr.dtAccount,
                  leading: _MethodChip(
                    icon: PhosphorIconsRegular.notebook,
                    background: colors.warningContainer,
                    foreground: colors.warning,
                  ),
                ),
            ],
          ),
          if (accountOn) ...[
            const SizedBox(height: AppDims.s3),
            _CustomerRow(onPick: () => _pickCustomer(context)),
          ],
          if (isCredit && accountOn) ...[
            const SizedBox(height: AppDims.s3),
            const _OwesLine(),
          ] else if (isSplit && splitOn) ...[
            const SizedBox(height: AppDims.s3),
            _SplitSummary(
              onEdit: () =>
                  _openSplit(
                    context,
                    bankakReady: bankakAccount != null,
                    accountOn: accountOn,
                  ),
            ),
          ] else if (isBankak) ...[
            const SizedBox(height: AppDims.s3),
            if (bankakAccount != null)
              _BankakReadyRow(account: bankakAccount)
            else
              const _BankakSetupRow(),
          ] else ...[
            const SizedBox(height: AppDims.s3),
            const _CashReceived(),
          ],
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Icon(icon, size: 14, color: foreground),
      ),
    );
  }
}

class _CashReceived extends StatefulWidget {
  const _CashReceived();

  @override
  State<_CashReceived> createState() => _CashReceivedState();
}

class _CashReceivedState extends State<_CashReceived> {
  static const _notes = [5000, 10000, 20000, 50000];

  int _selected = 0;

  List<double> _options(double total) {
    final options = <double>[total];
    for (final note in _notes) {
      if (options.length == 3) break;
      if (note > total) options.add(note.toDouble());
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final total = context.select<PosBloc, double>((bloc) => bloc.state.total);
    final options = _options(total);
    final selected = _selected < options.length ? _selected : 0;
    final change = options[selected] - total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr.cashReceived,
          style: text.labelLarge!.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDims.s2),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: AppDims.s2),
              _ReceivedChip(
                label: i == 0 ? context.tr.exactAmount : money(options[i]),
                selected: i == selected,
                onTap: () => setState(() => _selected = i),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDims.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                context.tr.changeDue,
                style: text.bodyMedium!.copyWith(color: colors.textSecondary),
              ),
            ),
            AppAmount(
              value: money(change),
              unit: AppFormat.currency,
              style: text.titleMedium!.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceivedChip extends StatelessWidget {
  const _ReceivedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Pressable(
      onTap: onTap,
      haptic: true,
      child: AnimatedContainer(
        duration: AppDims.medium,
        curve: AppDims.ease,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4 - 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.cashTint : colors.surfaceSoft,
          borderRadius: AppDims.borderPill,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!
              .copyWith(
                color: selected ? colors.cashInk : colors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              )
              .tabular,
        ),
      ),
    );
  }
}

class _BankakReadyRow extends StatelessWidget {
  const _BankakReadyRow({required this.account});

  final String account;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Icon(PhosphorIconsRegular.checkCircle, size: 16, color: colors.success),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              context.tr.bankakReadyAccount(account),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: colors.textHint).tabular,
            ),
          ),
        ),
      ],
    );
  }
}

class _BankakSetupRow extends StatelessWidget {
  const _BankakSetupRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Pressable(
      onTap: () => Navigator.of(context).pushNamed(RouteStrings.settingsScreen),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: AppDims.borderMd,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppDims.s3),
          child: Row(
            children: [
              Icon(
                PhosphorIconsRegular.warning,
                size: 18,
                color: colors.warning,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  context.tr.bankakAccountSetupBanner,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitSummary extends StatelessWidget {
  const _SplitSummary({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final state = context.watch<PosBloc>().state;
    final total = Cents.parse(state.total.toStringAsFixed(2));
    final stale =
        state.splitParts.isEmpty ||
        total == null ||
        !SplitPayment.matches(state.splitParts, total);

    String name(SalePaymentPart p) => switch (p.method) {
      'bankak' => tr.bankak,
      'credit' => tr.dtOnAccount,
      _ => tr.cash,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: stale ? colors.warningContainer : colors.surfaceSoft,
        borderRadius: AppDims.borderMd,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stale)
              Text(
                tr.spMismatch,
                style: text.bodyMedium!.copyWith(color: colors.textPrimary),
              )
            else
              for (final p in state.splitParts)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name(p),
                        style: text.bodyMedium!.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      shiftMoney(Cents.parse(p.amount) ?? BigInt.zero),
                      textDirection: TextDirection.ltr,
                      style: text.bodyMedium!.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: AppDims.s2),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Pressable(
                onTap: onEdit,
                child: Text(
                  tr.spEdit,
                  style: text.labelLarge!.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final name = context.select<PosBloc, String?>((b) => b.state.customerName);

    return Row(
      children: [
        Expanded(
          child: Text(
            name == null ? tr.dtCustomer : '${tr.dtCustomer}: $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium!.copyWith(color: colors.textSecondary),
          ),
        ),
        if (name != null) ...[
          Pressable(
            onTap: () =>
                context.read<PosBloc>().add(const PosCustomerCleared()),
            child: Text(
              tr.dtClear,
              style: text.labelLarge!.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppDims.s4),
        ],
        Pressable(
          onTap: onPick,
          child: Text(
            name == null ? tr.dtAddOptional : tr.dtChange,
            style: text.labelLarge!.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Owes 1,200.00 now. After this sale: 6,200.00."
class _OwesLine extends StatelessWidget {
  const _OwesLine();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final id = context.select<PosBloc, String?>((b) => b.state.customerId);
    final total = Cents.parse(
      context.select<PosBloc, double>((b) => b.state.total).toStringAsFixed(2),
    );
    if (id == null || total == null) return const SizedBox.shrink();

    return FutureBuilder<BigInt>(
      future: getIt<DebtReader>().balance(id),
      builder: (context, snap) {
        final now = snap.data;
        if (now == null) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.infoContainer,
            borderRadius: AppDims.borderMd,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDims.s3),
            child: Text(
              tr.dtOwesNowAfter(shiftMoney(now), shiftMoney(now + total)),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: colors.info),
            ),
          ),
        );
      },
    );
  }
}
