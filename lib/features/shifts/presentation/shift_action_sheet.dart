import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

import '../domain/cash_expectation.dart';
import '../domain/shift.dart';
import '../domain/shift_service.dart';
import 'shift_format.dart';
import 'shifts_cubit.dart';

enum ShiftSheetMode { open, close, count, payIn, payOut }

/// One sheet for the five small shift actions: open (opening cash), close
/// (count), count a closed shift, pay in, pay out. Close and count show what
/// the drawer should hold and the difference as the amount is typed; a
/// difference never blocks. A pay-out beyond the drawer only shows a calm note.
Future<void> showShiftActionSheet(
  BuildContext context, {
  required ShiftsCubit cubit,
  required ShiftSheetMode mode,
  ShiftInfo? shift,
  BigInt? expected,
}) => showAppSheet<void>(
  context,
  builder: (_) => ShiftActionSheet(
    cubit: cubit,
    mode: mode,
    shift: shift,
    expected: expected,
  ),
);

class ShiftActionSheet extends StatefulWidget {
  const ShiftActionSheet({
    super.key,
    required this.cubit,
    required this.mode,
    this.shift,
    this.expected,
  });

  final ShiftsCubit cubit;
  final ShiftSheetMode mode;

  /// The shift being counted ([ShiftSheetMode.count]).
  final ShiftInfo? shift;

  /// What the drawer should hold (close, count, pay out).
  final BigInt? expected;

  @override
  State<ShiftActionSheet> createState() => _ShiftActionSheetState();
}

class _ShiftActionSheetState extends State<ShiftActionSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  bool _carried = false;
  String? _error;

  ShiftSheetMode get _mode => widget.mode;
  bool get _isMove =>
      _mode == ShiftSheetMode.payIn || _mode == ShiftSheetMode.payOut;
  bool get _showsExpected =>
      _mode == ShiftSheetMode.close || _mode == ShiftSheetMode.count;
  BigInt get _expected =>
      widget.expected ?? widget.shift?.expected ?? BigInt.zero;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refresh);
    if (_mode == ShiftSheetMode.open) _prefill();
  }

  Future<void> _prefill() async {
    final c = await widget.cubit.carryOver();
    if (!mounted || c == null || _amount.text.isNotEmpty) return;
    setState(() {
      _carried = true;
      _amount.text = Cents.format(c);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _note.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _error = null);
  }

  BigInt? get _typed {
    final t = normalizeAmountInput(_amount.text);
    if (t.isEmpty) return null;
    return Cents.parse(t, allowNegative: false);
  }

  String _title(BuildContext context) {
    final tr = context.tr;
    return switch (_mode) {
      ShiftSheetMode.open => tr.sfWOpen,
      ShiftSheetMode.close => tr.sfWClose,
      ShiftSheetMode.count => tr.sfWCount,
      ShiftSheetMode.payIn => tr.sfWPayIn,
      ShiftSheetMode.payOut => tr.sfWPayOut,
    };
  }

  String _action(BuildContext context) {
    final tr = context.tr;
    return switch (_mode) {
      ShiftSheetMode.open => tr.sfActOpen,
      ShiftSheetMode.close => tr.sfActClose,
      ShiftSheetMode.count => tr.sfBtnSaveCount,
      ShiftSheetMode.payIn => tr.sfActPayIn,
      ShiftSheetMode.payOut => tr.sfActPayOut,
    };
  }

  String _amountLabel(BuildContext context) {
    final tr = context.tr;
    return switch (_mode) {
      ShiftSheetMode.open => tr.sfLOpening,
      ShiftSheetMode.close || ShiftSheetMode.count => tr.sfLCounted,
      _ => tr.sfLAmount,
    };
  }

  bool get _canSubmit {
    if (_saving) return false;
    final v = _typed;
    if (_isMove) {
      return v != null && v > BigInt.zero && _reason.text.trim().isNotEmpty;
    }
    if (_mode == ShiftSheetMode.open) {
      return _amount.text.trim().isEmpty || v != null;
    }
    return v != null; // close and count need a count
  }

  Future<void> _submit() async {
    final tr = context.tr;
    final v = _typed;
    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _note.text.trim();
    final ShiftResult r;
    try {
      r = switch (_mode) {
        ShiftSheetMode.open => await widget.cubit.openShift(openingCash: v),
        ShiftSheetMode.close => await widget.cubit.closeShift(
          counted: v,
          note: note,
        ),
        ShiftSheetMode.count => await widget.cubit.countShift(
          widget.shift!.id,
          v!,
          note: note,
        ),
        ShiftSheetMode.payIn => await widget.cubit.move(
          isPayIn: true,
          amount: v!,
          reason: _reason.text,
        ),
        ShiftSheetMode.payOut => await widget.cubit.move(
          isPayIn: false,
          amount: v!,
          reason: _reason.text,
        ),
      };
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = tr.sfErrSave;
      });
      return;
    }
    if (!mounted) return;
    switch (r) {
      case ShiftFailed(:final error):
        setState(() {
          _saving = false;
          _error = shiftErrorText(tr, error);
        });
      case ShiftDone():
        final msg = switch (_mode) {
          ShiftSheetMode.open => tr.sfDoneOpen,
          ShiftSheetMode.close => tr.sfDoneClose,
          ShiftSheetMode.count => tr.sfDoneCount,
          ShiftSheetMode.payIn => tr.sfDonePayIn,
          ShiftSheetMode.payOut => tr.sfDonePayOut,
        };
        Navigator.of(context).pop();
        GlobalSnackBar.showSuccess(message: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final typed = _typed;

    // The one reserved message slot under the amount.
    Widget? slot;
    if (_error != null) {
      slot = _Note(text: _error!, color: colors.danger, bg: colors.dangerContainer);
    } else if (_showsExpected && typed != null) {
      final d = CashExpectation.difference(typed, _expected);
      slot = d == BigInt.zero
          ? _Note(
              text: tr.sfDiffEven,
              color: colors.success,
              bg: colors.successContainer,
            )
          : d.isNegative
          ? _Note(
              text: tr.sfDiffShort(shiftMoney(-d)),
              color: colors.danger,
              bg: colors.dangerContainer,
            )
          : _Note(
              text: tr.sfDiffOver(shiftMoney(d)),
              color: colors.info,
              bg: colors.infoContainer,
            );
    } else if (_mode == ShiftSheetMode.payOut &&
        typed != null &&
        CashExpectation.payOutExceeds(_expected, typed)) {
      slot = _Note(
        text: tr.sfOverNote,
        color: colors.warning,
        bg: colors.warningContainer,
      );
    } else if (_mode == ShiftSheetMode.open && _carried) {
      slot = Text(
        tr.sfCarryHint,
        style: text.bodySmall!.copyWith(color: colors.textSecondary),
      );
    }

    return AppSheet(
      title: _title(context),
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
          label: _action(context),
          isLoading: _saving,
          onPressed: _canSubmit ? _submit : null,
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
                if (_showsExpected)
                  AppFormRow(
                    label: tr.sfLExpected,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        shiftMoney(_expected),
                        textDirection: TextDirection.ltr,
                        style: text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                AppFormRow(
                  label: _amountLabel(context),
                  child: AppRowTextField(
                    controller: _amount,
                    hint: '0.00',
                    numeric: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                if (_isMove)
                  AppFormRow(
                    label: tr.sfLReason,
                    child: AppRowTextField(
                      controller: _reason,
                      hint: tr.sfLReason,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                if (_showsExpected)
                  AppFormRow(
                    label: tr.sfLNote,
                    child: AppRowTextField(
                      controller: _note,
                      hint: tr.sfLNote,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 34),
                child: slot ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.color, required this.bg});

  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s3,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDims.s3),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
