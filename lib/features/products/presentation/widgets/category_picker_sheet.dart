import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Result of the picker. [category] null means "General" (no explicit
/// category; created automatically when the product is saved).
class CategoryChoice {
  final CategoryData? category;
  const CategoryChoice(this.category);
}

/// Category sheet with an inline "new category" row at the top. Returns null
/// when dismissed.
Future<CategoryChoice?> showProductCategoryPicker(
  BuildContext context, {
  required ProductBloc bloc,
  required String? selectedId,
}) {
  return showAdaptivePanel<CategoryChoice>(
    context,
    showDragHandle: false,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _CategoryPickerSheet(selectedId: selectedId),
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  final String? selectedId;
  const _CategoryPickerSheet({required this.selectedId});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _nameCtrl = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canAdd => _nameCtrl.text.trim().isNotEmpty && !_creating;

  Future<void> _create() async {
    if (!_canAdd) return;
    setState(() => _creating = true);

    final completer = Completer<CategoryData?>();
    context.read<ProductBloc>().add(
      OnCreateProductCategory(name: _nameCtrl.text, completer: completer),
    );
    final created = await completer.future;

    if (!mounted) return;

    if (created == null) {
      setState(() => _creating = false);
      GlobalSnackBar.show(
        message: context.tr.somethingWentWrong,
        isError: true,
      );
      return;
    }

    Navigator.of(context).pop(CategoryChoice(created));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final categories = context.select<ProductBloc, List<CategoryData>>(
      (bloc) => bloc.state.categories,
    );

    Widget optionRow({
      required String title,
      String? hint,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Pressable(
        onTap: onTap,
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
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (hint != null)
                        Text(
                          hint,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    PhosphorIconsRegular.check,
                    size: 22,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final hairline = Divider(
      height: 0.5,
      thickness: 0.5,
      indent: AppDims.s4,
      color: colors.border,
    );

    return AppSheet(
      title: tr.category,
      maxHeightFactor: 0.85,
      trailingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: AppDims.borderLg,
          child: Column(
            children: [
              ColoredBox(
                color: colors.primaryContainer,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.plus,
                          size: 22,
                          color: colors.primary,
                        ),
                        const SizedBox(width: AppDims.s3),
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _create(),
                            cursorColor: colors.primary,
                            style: TextStyle(
                              fontSize: 17,
                              color: colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: tr.pfCategoryNameHint,
                              hintStyle: TextStyle(
                                fontSize: 17,
                                color: colors.textHint,
                              ),
                            ),
                          ),
                        ),
                        Pressable(
                          onTap: _canAdd ? _create : null,
                          scale: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _creating
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primary,
                                    ),
                                  )
                                : Text(
                                    tr.add,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: _canAdd
                                          ? colors.primary
                                          : colors.disabled,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              hairline,
              optionRow(
                title: tr.generalCategory,
                hint: tr.pfGeneralHint,
                selected: widget.selectedId == null,
                onTap: () =>
                    Navigator.of(context).pop(const CategoryChoice(null)),
              ),
              for (final category in categories) ...[
                hairline,
                optionRow(
                  title: category.name?.trim().isNotEmpty == true
                      ? category.name!.trim()
                      : tr.category,
                  selected: widget.selectedId == category.id,
                  onTap: () =>
                      Navigator.of(context).pop(CategoryChoice(category)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
