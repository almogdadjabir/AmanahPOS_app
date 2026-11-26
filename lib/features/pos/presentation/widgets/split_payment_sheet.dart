import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/domain/split_payment.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// Collects the parts of one split sale (cash and Bankak). Returns the parts
/// when confirmed, null when cancelled. The sheet never writes a sale: the
/// checkout button does that.
Future<List<SalePaymentPart>?> showSplitPaymentSheet(
  BuildContext context, {
  required BigInt total,
  required bool bankakReady,
  List<SalePaymentPart> initial = const [],
}) => showAppSheet<List<SalePaymentPart>>(
  context,
  builder: (_) => SplitPaymentSheet(
    total: total,
    bankakReady: bankakReady,
    initial: initial,
  ),
);

class SplitPaymentSheet extends StatefulWidget {
  const SplitPaymentSheet({
    super.key,
    required this.total,
    required this.bankakReady,
    this.initial = const [],
  });

  final BigInt total;
  final bool bankakReady;
  final List<SalePaymentPart> initial;

  @override
  State<SplitPaymentSheet> createState() => _SplitPaymentSheetState();
}

class _SplitPaymentSheetState extends State<SplitPaymentSheet> {
  late final TextEditingController _cash;
  late final TextEditingController _bankak;

  @override
  void initState() {
    super.initState();
    String of(String m) {
      for (final p in widget.initial) {
        if (p.method == m) return p.amount;
      }
      return '';
    }

    _cash = TextEditingController(text: of('cash'));
    _bankak = TextEditingController(text: widget.bankakReady ? of('bankak') : '');
  }

  @override
  void dispose() {
    _cash.dispose();
    _bankak.dispose();
    super.dispose();
  }

  SplitEvaluation get _eval => SplitPayment.evaluate(
    total: widget.total,
    cash: normalizeAmountInput(_cash.text),
    bankak: normalizeAmountInput(_bankak.text),
  );

  void _fill(bool intoCash) {
    final v = SplitPayment.fillRest(
      total: widget.total,
      cash: normalizeAmountInput(_cash.text),
      bankak: normalizeAmountInput(_bankak.text),
      intoCash: intoCash,
    );
    if (v == null) return;
    setState(() => (intoCash ? _cash : _bankak).text = v);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final e = _eval;

    final (String label, Color fg, Color bg) = switch (e.status) {
      SplitStatus.exact => (tr.spPaid, colors.success, colors.successContainer),
      SplitStatus.over => (tr.spOver, colors.danger, colors.dangerContainer),
      SplitStatus.invalid => (
        tr.spInvalid,
        colors.danger,
        colors.dangerContainer,
      ),
      SplitStatus.incomplete => (tr.spLeft, colors.info, colors.infoContainer),
    };
    final canFill = e.status == SplitStatus.incomplete;

    Widget fill(bool intoCash, bool enabled) => Pressable(
      onTap: enabled ? () => _fill(intoCash) : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppDims.s2),
        child: Text(
          tr.spFillRest,
          style: text.labelMedium!.copyWith(
            color: enabled ? colors.primary : colors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return AppSheet(
      title: tr.spTitle,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      footer: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4,
          AppDims.s2,
          AppDims.s4,
          AppDims.s4,
        ),
        child: AppButton.wide(
          label: tr.spConfirm,
          onPressed: e.status == SplitStatus.exact
              ? () => Navigator.of(context).pop(e.parts)
              : null,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormGroup(
              children: [
                AppFormRow(
                  label: tr.spTotal,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      shiftMoney(widget.total),
                      textDirection: TextDirection.ltr,
                      style: text.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                AppFormRow(
                  label: tr.cash,
                  child: Row(
                    children: [
                      fill(true, canFill),
                      Expanded(
                        child: AppRowTextField(
                          controller: _cash,
                          hint: '0.00',
                          numeric: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                AppFormRow(
                  label: tr.bankak,
                  child: widget.bankakReady
                      ? Row(
                          children: [
                            fill(false, canFill),
                            Expanded(
                              child: AppRowTextField(
                                controller: _bankak,
                                hint: '0.00',
                                numeric: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          tr.spBankakSetup,
                          style: text.bodySmall!.copyWith(
                            color: colors.warning,
                          ),
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s3,
                  vertical: AppDims.s2,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppDims.s3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodyMedium!.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (e.status != SplitStatus.invalid)
                      Text(
                        shiftMoney(e.left),
                        textDirection: TextDirection.ltr,
                        style: text.bodyMedium!.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
