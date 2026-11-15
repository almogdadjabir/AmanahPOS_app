import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

class PickerOption<T> {
  final T value;
  final String label;
  final String? hint;

  const PickerOption({required this.value, required this.label, this.hint});
}

/// Single-choice list sheet with a checkmark on the selected option. Returns
/// the picked value, or null when dismissed.
Future<T?> showOptionPicker<T>(
  BuildContext context, {
  required String title,
  required List<PickerOption<T>> options,
  required T? selected,
}) {
  return showAdaptivePanel<T>(
    context,
    showDragHandle: false,
    builder: (sheetContext) => AppSheet(
      title: title,
      maxHeightFactor: 0.8,
      trailingAction: AppSheetAction(
        label: context.tr.cancel,
        onTap: () => Navigator.of(sheetContext).pop(),
      ),
      child: _OptionList<T>(
        options: options,
        selected: selected,
        onPick: (value) => Navigator.of(sheetContext).pop(value),
      ),
    ),
  );
}

class _OptionList<T> extends StatelessWidget {
  final List<PickerOption<T>> options;
  final T? selected;
  final ValueChanged<T> onPick;

  const _OptionList({
    required this.options,
    required this.selected,
    required this.onPick,
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
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4,
                  color: colors.border,
                ),
              Pressable(
                onTap: () => onPick(options[i].value),
                scale: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 54),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s4,
                      vertical: AppDims.s2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                options[i].label,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (options[i].hint != null)
                                Text(
                                  options[i].hint!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textHint,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (options[i].value == selected)
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
            ],
          ],
        ),
      ),
    );
  }
}
