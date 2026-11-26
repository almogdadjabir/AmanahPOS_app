import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

/// What the sheet gives back: [discount] null means "remove it". The sheet
/// itself returns null when it is cancelled.
class DiscountChoice {
  const DiscountChoice(this.discount);
  final CartDiscount? discount;
}

/// Percent or amount off [baseCents] (a cart line or the whole sale). Shows the
/// new total as you type; a discount above 100% or above the base is refused.
Future<DiscountChoice?> showDiscountSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required BigInt baseCents,
  CartDiscount? initial,
}) => showAppSheet<DiscountChoice>(
  context,
  builder: (_) => DiscountSheet(
    title: title,
    subtitle: subtitle,
    baseCents: baseCents,
    initial: initial,
  ),
);

class DiscountSheet extends StatefulWidget {
  const DiscountSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.baseCents,
    this.initial,
  });

  final String title;
  final String? subtitle;
  final BigInt baseCents;
  final CartDiscount? initial;

  @override
  State<DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<DiscountSheet> {
  late DiscountKind _kind;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _kind = widget.initial?.kind ?? DiscountKind.percent;
    _value = TextEditingController(text: widget.initial?.value ?? '');
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String get _typed => normalizeAmountInput(_value.text).trim();

  DiscountProblem? get _problem =>
      CartDiscount.check(_kind, _typed, widget.baseCents);

  bool get _ready => _typed.isNotEmpty && _problem == null;

  CartDiscount _make() => _kind == DiscountKind.percent
      ? CartDiscount.percent(_typed)
      : CartDiscount.amount(_typed);

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final problem = _typed.isEmpty ? null : _problem;

    String? line;
    Color? fg;
    Color? bg;
    if (problem != null) {
      line = switch (problem) {
        DiscountProblem.notANumber ||
        DiscountProblem.zero => tr.dcErrNumber,
        DiscountProblem.overBase => _kind == DiscountKind.percent
            ? tr.dcErrPercent
            : tr.dcErrAmount(shiftMoney(widget.baseCents)),
      };
      fg = colors.danger;
      bg = colors.dangerContainer;
    } else if (_ready) {
      final cut = _make().cutOf(widget.baseCents);
      line = tr.dcNewTotal(shiftMoney(widget.baseCents - cut));
      fg = colors.success;
      bg = colors.successContainer;
    }

    final applyLabel = !_ready
        ? tr.dcDiscount
        : _kind == DiscountKind.percent
        ? tr.dcApplyPercent(_typed)
        : tr.dcApplyAmount(
            shiftMoney(_make().cutOf(widget.baseCents)),
          );

    return AppSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailingAction: widget.initial == null
          ? null
          : AppSheetAction(
              label: tr.dcRemove,
              destructive: true,
              onTap: () => Navigator.of(context).pop(const DiscountChoice(null)),
            ),
      footer: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDims.s4,
          AppDims.s2,
          AppDims.s4,
          AppDims.s4,
        ),
        child: AppButton.wide(
          label: applyLabel,
          onPressed: _ready
              ? () => Navigator.of(context).pop(DiscountChoice(_make()))
              : null,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppDims.s3),
              child: AppSegmented<DiscountKind>(
                selected: _kind,
                onChanged: (v) => setState(() => _kind = v),
                segments: [
                  AppSegment(value: DiscountKind.percent, label: tr.dcPercent),
                  AppSegment(value: DiscountKind.amount, label: tr.dcAmount),
                ],
              ),
            ),
            AppFormGroup(
              children: [
                AppFormRow(
                  label: _kind == DiscountKind.percent
                      ? tr.dcPercentOff
                      : tr.dcAmountOff,
                  child: AppRowTextField(
                    controller: _value,
                    hint: _kind == DiscountKind.percent ? '10' : '0.00',
                    numeric: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s3),
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
