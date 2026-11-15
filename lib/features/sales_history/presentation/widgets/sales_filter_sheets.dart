import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sales_filter_bar.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// Option menu sheet (same look as the Category sheet on Products).
/// Resolves with a 1-tuple so "All" (a null value) differs from dismissed.
Future<({T value})?> _showOptions<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T selected,
}) {
  return showAdaptivePanel<({T value})>(
    context,
    showDragHandle: false,
    builder: (sheetContext) => AppSheet(
      title: title,
      maxHeightFactor: 0.8,
      child: _OptionList<T>(options: options, selected: selected),
    ),
  );
}

class _OptionList<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;

  const _OptionList({required this.options, required this.selected});

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
            for (var i = 0; i < options.length; i++) ...[
              Pressable(
                scale: 1,
                onTap: () => Navigator.of(context).pop((value: options[i].$1)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (options[i].$1 == selected)
                          Icon(
                            PhosphorIconsRegular.check,
                            size: 22,
                            color: colors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < options.length - 1)
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

/// Returns the new filters, or null when dismissed / unchanged.
Future<SalesHistoryFilters?> pickSalesDate(
  BuildContext context,
  SalesHistoryFilters filters,
) async {
  final tr = context.tr;
  final picked = await _showOptions<SalesDatePreset>(
    context,
    title: tr.shChipDate,
    selected: filters.date,
    options: [
      for (final p in SalesDatePreset.values) (p, salesDateLabel(context, p)),
    ],
  );
  if (picked == null || !context.mounted) return null;

  if (picked.value == SalesDatePreset.custom) {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: filters.customFrom != null && filters.customTo != null
          ? DateTimeRange(start: filters.customFrom!, end: filters.customTo!)
          : null,
    );
    if (range == null) return null;
    return filters.copyWith(
      date: SalesDatePreset.custom,
      customFrom: range.start,
      customTo: range.end,
    );
  }
  if (picked.value == filters.date) return null;
  return filters.copyWith(date: picked.value);
}

Future<SalesHistoryFilters?> pickSalesPayment(
  BuildContext context,
  SalesHistoryFilters filters,
) async {
  final tr = context.tr;
  final picked = await _showOptions<String?>(
    context,
    title: tr.shChipPayment,
    selected: filters.payment,
    options: [
      (null, tr.shPayAll),
      ('cash', tr.shPayCash),
      ('bankak', tr.shPayBankak),
      ('card', tr.shPayCard),
    ],
  );
  if (picked == null || picked.value == filters.payment) return null;
  return picked.value == null
      ? filters.copyWith(clearPayment: true)
      : filters.copyWith(payment: picked.value);
}

Future<SalesHistoryFilters?> pickSalesStatus(
  BuildContext context,
  SalesHistoryFilters filters,
) async {
  final tr = context.tr;
  final picked = await _showOptions<String?>(
    context,
    title: tr.shChipStatus,
    selected: filters.status,
    options: [
      (null, tr.shStatusAll),
      ('completed', tr.shStatusCompleted),
      ('partial_refund', tr.shStatusPartial),
      ('refunded', tr.shStatusReturned),
      ('cancelled', tr.shStatusCancelled),
    ],
  );
  if (picked == null || picked.value == filters.status) return null;
  return picked.value == null
      ? filters.copyWith(clearStatus: true)
      : filters.copyWith(status: picked.value);
}
