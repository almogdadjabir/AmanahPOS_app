import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _Option<T> {
  final T value;
  final String title;
  final String? description;
  const _Option(this.value, this.title, [this.description]);
}

/// Role picker sheet: two options with plain-language descriptions and Save.
/// Resolves to the saved role, or null when dismissed.
Future<String?> showRolePicker(
  BuildContext context, {
  required String current,
}) {
  final tr = context.tr;
  return showAppSheet<String>(
    context,
    builder: (_) => _OptionSheet<String>(
      title: tr.tmRole,
      initial: current,
      options: [
        for (final r in kUserRoles)
          _Option(r, userRoleLabel(context, r), userRoleDesc(context, r)),
      ],
    ),
  );
}

/// Branch picker sheet. Resolves to the saved shop id, or null when dismissed.
Future<String?> showBranchPicker(
  BuildContext context, {
  required List<ShopData> shops,
  required String? current,
}) {
  final tr = context.tr;
  return showAppSheet<String>(
    context,
    builder: (_) => _OptionSheet<String>(
      title: tr.tmBranch,
      initial: current ?? shops.first.id!,
      options: [for (final s in shops) _Option(s.id!, s.name?.trim() ?? '')],
    ),
  );
}

class _OptionSheet<T> extends StatefulWidget {
  final String title;
  final T initial;
  final List<_Option<T>> options;

  const _OptionSheet({
    required this.title,
    required this.initial,
    required this.options,
  });

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  late T _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return AppSheet(
      title: widget.title,
      trailingAction: AppSheetAction(
        label: tr.save,
        emphasized: true,
        onTap: () => Navigator.of(context).pop(_selected),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppFormGroup(
          children: [
            for (final o in widget.options)
              Pressable(
                scale: 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = o.value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.title,
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (o.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  o.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 19 / 14,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (o.value == _selected)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 12,
                            top: 2,
                          ),
                          child: Icon(
                            PhosphorIconsRegular.check,
                            size: 22,
                            color: colors.primary,
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
