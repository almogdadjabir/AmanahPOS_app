import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_sheet_widgets.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showEditCategorySheet(
    BuildContext context, {
      required CategoryData category,
    }) {
  final categoryBloc = context.read<CategoryBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: categoryBloc,
      child: _EditCategorySheet(category: category),
    ),
  );
}

class _EditCategorySheet extends StatefulWidget {
  final CategoryData category;

  const _EditCategorySheet({
    required this.category,
  });

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _descFocus;

  late final String _initialName;
  late final String _initialDescription;

  bool get _hasChanges {
    return _nameCtrl.text.trim() != _initialName ||
        _descCtrl.text.trim() != _initialDescription;
  }

  @override
  void initState() {
    super.initState();

    _initialName = widget.category.name?.trim() ?? '';
    _initialDescription = widget.category.description?.trim() ?? '';

    _nameCtrl = TextEditingController(text: _initialName);
    _descCtrl = TextEditingController(text: _initialDescription);

    _nameFocus = FocusNode();
    _descFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();

    _nameFocus.dispose();
    _descFocus.dispose();

    super.dispose();
  }

  void _submit() {
    final categoryId = widget.category.id?.trim();

    if (categoryId == null || categoryId.isEmpty) {
      GlobalSnackBar.show(
        message: context.tr.invalidCategory,
        isError: true,
      );
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (!_hasChanges) return;

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();

    context.read<CategoryBloc>().add(
      OnEditCategory(
        categoryId: categoryId,
        name: name,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: context.tr.categoryUpdatedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == CategorySubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: tr.editCategory,
        subtitle: _initialName.isEmpty ? null : _initialName,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(
                label: tr.fieldCategoryName,
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                nextFocus: _descFocus,
                hint: tr.categoryNameHint,
                prefixIcon: SolarIconsOutline.layersMinimalistic,
                validator: (value) {
                  return CategoryFormValidators.name(context, value);
                },
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(label: tr.fieldDescription),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                hint: tr.categoryDescriptionShortHint,
                prefixIcon: SolarIconsOutline.notes,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: AppDims.s5),

              AnimatedBuilder(
                animation: Listenable.merge([
                  _nameCtrl,
                  _descCtrl,
                ]),
                builder: (context, _) {
                  return BlocSelector<CategoryBloc, CategoryState,
                      CategorySubmitStatus>(
                    selector: (state) => state.submitStatus,
                    builder: (context, submitStatus) {
                      final isSubmitting =
                          submitStatus == CategorySubmitStatus.loading;

                      return CategorySubmitButton(
                        label: tr.saveChanges,
                        onPressed: isSubmitting ? null : _submit,
                        enabled: _hasChanges && !isSubmitting,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}