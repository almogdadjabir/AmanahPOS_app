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

void showEditCategorySheet(BuildContext context,
    {required CategoryData category}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CategoryBloc>(),
      child: _EditCategorySheet(category: category),
    ),
  );
}

class _EditCategorySheet extends StatefulWidget {
  final CategoryData category;
  const _EditCategorySheet({required this.category});

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  bool get _hasChanges =>
      _nameCtrl.text.trim() != (widget.category.name ?? '') ||
          _descCtrl.text.trim() != (widget.category.description ?? '');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name ?? '');
    _descCtrl = TextEditingController(text: widget.category.description ?? '');
    _nameCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _nameFocus.dispose(); _descFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;
    context.read<CategoryBloc>().add(OnEditCategory(
      categoryId:  widget.category.id!,
      name:        _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'Category updated', isInfo: true);
        }
        if (state.submitStatus == CategorySubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true, isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: 'Edit Category',
        subtitle: widget.category.name,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              FieldLabel(label: 'Name', required: true),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode:  _nameFocus,
                nextFocus:  _descFocus,
                hint: 'Beverages',
                prefixIcon: Icons.layers_rounded,
                validator:  CategoryFormValidators.name,
              ),
              const SizedBox(height: AppDims.s3),

              FieldLabel(label: 'Description'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                hint: 'Drinks and beverages',
                prefixIcon: Icons.notes_rounded,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppDims.s5),

              CategorySubmitButton(
                label: 'Save Changes',
                onPressed: _submit,
                enabled: _hasChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}