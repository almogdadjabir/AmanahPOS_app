import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

import '../domain/debt_service.dart';

enum DebtSheetMode { receive, writeOff }

String debtErrorText(AppLocalizations tr, DebtError e) => switch (e) {
  DebtError.notAllowed => tr.dtErrNotAllowed,
  DebtError.exceedsBalance => tr.dtErrExceeds,
  DebtError.nothingOwed => tr.dtErrNothing,
  DebtError.amountInvalid || DebtError.methodInvalid => tr.dtErrAmount,
  DebtError.disabled || DebtError.noSession => tr.dtErrSave,
};

/// Receive a payment against a customer's debt, or write part of it off. The
/// amount starts as the whole debt and can never go above it.
Future<void> showDebtActionSheet(
  BuildContext context, {
  required DebtService service,
  required DebtSheetMode mode,
  required String customerId,
  required BigInt balance,
}) => showAppSheet<void>(
  context,
  builder: (_) => DebtActionSheet(
    service: service,
    mode: mode,
    customerId: customerId,
    balance: balance,
  ),
);

class DebtActionSheet extends StatefulWidget {
  const DebtActionSheet({
    super.key,
    required this.service,
    required this.mode,
    required this.customerId,
    required this.balance,
  });

  final DebtService service;
  final DebtSheetMode mode;
  final String customerId;
  final BigInt balance;

  @override
  State<DebtActionSheet> createState() => _DebtActionSheetState();
}

class _DebtActionSheetState extends State<DebtActionSheet> {
  late final TextEditingController _amount;
  final _note = TextEditingController();
  String _method = 'cash';
  bool _saving = false;
  String? _error;

  bool get _receive => widget.mode == DebtSheetMode.receive;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: Cents.format(widget.balance));
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  BigInt? get _typed {
    final v = Cents.parse(normalizeAmountInput(_amount.text), allowNegative: false);
    return v;
  }

  bool get _valid {
    final v = _typed;
    return v != null && v > BigInt.zero && v <= widget.balance;
  }

  BigInt get _half => (widget.balance + BigInt.one) ~/ BigInt.two;

  void _set(BigInt cents) => setState(() {
    _amount.text = Cents.format(cents);
    _error = null;
  });

  Future<void> _submit() async {
    final tr = context.tr;
    final v = _typed;
    if (v == null || !_valid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final DebtResult r;
    try {
      r = _receive
          ? await widget.service.receivePayment(
              customerId: widget.customerId,
              amount: v,
              method: _method,
              note: _note.text,
            )
          : await widget.service.writeOff(
              customerId: widget.customerId,
              amount: v,
              note: _note.text,
            );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = tr.dtErrSave;
      });
      return;
    }
    if (!mounted) return;
    switch (r) {
      case DebtDone():
        GlobalSnackBar.showSuccess(
          message: _receive
              ? tr.dtDoneReceived(shiftMoney(v))
              : tr.dtDoneWrittenOff(shiftMoney(v)),
        );
        Navigator.of(context).pop();
      case DebtFailed(:final error):
        setState(() {
          _saving = false;
          _error = debtErrorText(tr, error);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final typed = _typed;
    final over = typed != null && typed > widget.balance;

    String? line;
    Color? fg;
    Color? bg;
    if (_error != null) {
      line = _error;
      fg = colors.danger;
      bg = colors.dangerContainer;
    } else if (over) {
      line = tr.dtOverBalance(shiftMoney(widget.balance));
      fg = colors.danger;
      bg = colors.dangerContainer;
    } else if (_valid) {
      final left = widget.balance - typed!;
      line = left == BigInt.zero
          ? tr.dtAfterZero
          : tr.dtAfterLeft(shiftMoney(left));
      fg = left == BigInt.zero ? colors.success : colors.info;
      bg = left == BigInt.zero ? colors.successContainer : colors.infoContainer;
    }

    Widget chip(String label, BigInt value) {
      final on = typed == value;
      return Pressable(
        onTap: () => _set(value),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3,
            vertical: AppDims.s2,
          ),
          decoration: BoxDecoration(
            color: on ? colors.cashTint : colors.surfaceSoft,
            borderRadius: AppDims.borderPill,
          ),
          child: Text(
            label,
            textDirection: TextDirection.ltr,
            style: text.labelLarge!.copyWith(
              color: on ? colors.cashInk : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return AppSheet(
      title: _receive ? tr.dtReceive : tr.dtWriteOff,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: _saving ? null : () => Navigator.of(context).pop(),
      ),
      footer: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4,
          AppDims.s2,
          AppDims.s4,
          AppDims.s4,
        ),
        child: AppButton.wide(
          label: _valid
              ? (_receive
                    ? tr.dtBtnReceive(shiftMoney(typed!))
                    : tr.dtBtnWriteOff(shiftMoney(typed!)))
              : (_receive ? tr.dtReceive : tr.dtWriteOff),
          isLoading: _saving,
          onPressed: _valid && !_saving ? _submit : null,
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
                  label: tr.dtAmount,
                  child: AppRowTextField(
                    controller: _amount,
                    hint: '0.00',
                    numeric: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                if (!_receive)
                  AppFormRow(
                    label: tr.dtNote,
                    child: AppRowTextField(
                      controller: _note,
                      hint: tr.dtNoteHint,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              child: Row(
                children: [
                  chip(tr.dtFull(shiftMoney(widget.balance)), widget.balance),
                  if (_half != widget.balance) ...[
                    const SizedBox(width: AppDims.s2),
                    chip(tr.dtHalf(shiftMoney(_half)), _half),
                  ],
                ],
              ),
            ),
            if (_receive)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDims.s3),
                child: AppSegmented<String>(
                  selected: _method,
                  onChanged: (v) => setState(() => _method = v),
                  segments: [
                    AppSegment(value: 'cash', label: tr.cash),
                    AppSegment(value: 'bankak', label: tr.bankak),
                  ],
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: line == null
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDims.s3,
                        vertical: AppDims.s2,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppDims.s3),
                      ),
                      child: Text(
                        line,
                        style: text.bodyMedium!.copyWith(
                          color: fg,
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
