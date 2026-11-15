import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lines of the sale as tick rows. A selected line grows a stepper row.
class ReturnLinesCard extends StatelessWidget {
  final List<SaleHistoryLineItem> lines;
  final Map<String, double> selected;
  final ValueChanged<String> onToggle;
  final void Function(String lineId, double quantity) onQuantity;

  const ReturnLinesCard({
    super.key,
    required this.lines,
    required this.selected,
    required this.onToggle,
    required this.onQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < lines.length; i++) ...[
              _LineRow(
                line: lines[i],
                quantity: selected[lines[i].lineId],
                onToggle: () => onToggle(lines[i].lineId),
                onQuantity: (q) => onQuantity(lines[i].lineId, q),
              ),
              if (i < lines.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4,
                  color: colors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final SaleHistoryLineItem line;
  final double? quantity;
  final VoidCallback onToggle;
  final ValueChanged<double> onQuantity;

  const _LineRow({
    required this.line,
    required this.quantity,
    required this.onToggle,
    required this.onQuantity,
  });

  bool get _gone => line.returnableQuantity <= 0;
  bool get _on => quantity != null;
  bool get _fractional => line.quantity % 1 != 0;
  double get _step => _fractional ? 0.5 : 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final name = line.productName.trim().isEmpty
        ? tr.product
        : line.productName.trim();
    final sold = line.returnedQuantity > 0
        ? tr.rtSoldReturned(
            saleQty(line.quantity),
            saleQty(line.returnedQuantity),
          )
        : tr.rtSold(saleQty(line.quantity));

    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      color: _on ? colors.primaryContainer : null,
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
      child: Row(
        children: [
          _Tick(on: _on, disabled: _gone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sold,
                  style: TextStyle(fontSize: 13, color: colors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              saleNumber(line.unitPrice),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );

    final tappable = _gone
        ? Opacity(opacity: 0.5, child: row)
        : Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            scale: 1,
            behavior: HitTestBehavior.opaque,
            child: row,
          );

    if (!_on) return tappable;

    final q = quantity!;
    final min = _step;
    final max = line.returnableQuantity;
    return Column(
      children: [
        tappable,
        Container(
          color: colors.primaryContainer,
          padding: const EdgeInsetsDirectional.fromSTEB(52, 10, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.rtQuantity,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      tr.rtUpTo(saleQty(max)),
                      style: TextStyle(fontSize: 13, color: colors.textHint),
                    ),
                  ],
                ),
              ),
              _Stepper(
                quantity: q,
                typed: _fractional,
                canMinus: q > min,
                canPlus: q < max,
                onMinus: () => onQuantity(q - _step < min ? min : q - _step),
                onPlus: () => onQuantity(q + _step > max ? max : q + _step),
                onTapNumber: () async {
                  final v = await showAdaptivePanel<double>(
                    context,
                    builder: (_) => _QtyEntrySheet(initial: q, max: max),
                  );
                  if (v != null) onQuantity(v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tick extends StatelessWidget {
  final bool on;
  final bool disabled;

  const _Tick({required this.on, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? colors.primary : Colors.transparent,
          border: Border.all(
            color: on ? colors.primary : colors.borderStrong,
            width: 1.6,
          ),
        ),
        child: on
            ? Icon(PhosphorIconsBold.check, size: 14, color: colors.onPrimary)
            : null,
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final double quantity;
  final bool typed;
  final bool canMinus;
  final bool canPlus;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onTapNumber;

  const _Stepper({
    required this.quantity,
    required this.typed,
    required this.canMinus,
    required this.canPlus,
    required this.onMinus,
    required this.onPlus,
    required this.onTapNumber,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => Pressable(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      scale: 1,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 36,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colors.primary : colors.disabled,
        ),
      ),
    );

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(PhosphorIconsRegular.minus, canMinus, onMinus),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: typed ? onTapNumber : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  saleQty(quantity),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFeatures: AppTextStyles.tabularFigures,
                    decoration: typed ? TextDecoration.underline : null,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          btn(PhosphorIconsRegular.plus, canPlus, onPlus),
        ],
      ),
    );
  }
}

/// Type an exact quantity (weighed items).
class _QtyEntrySheet extends StatefulWidget {
  final double initial;
  final double max;

  const _QtyEntrySheet({required this.initial, required this.max});

  @override
  State<_QtyEntrySheet> createState() => _QtyEntrySheetState();
}

class _QtyEntrySheetState extends State<_QtyEntrySheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: saleQty(widget.initial),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _done() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    return AppSheet(
      title: tr.rtQuantity,
      subtitle: tr.rtUpTo(saleQty(widget.max)),
      trailingAction: AppSheetAction(
        label: tr.done,
        onTap: _done,
        emphasized: true,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onSubmitted: (_) => _done(),
          cursorColor: colors.primary,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }
}
