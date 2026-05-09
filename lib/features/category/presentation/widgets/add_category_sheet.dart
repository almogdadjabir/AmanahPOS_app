import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_sheet_widgets.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:amana_pos/widgets/optional_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showAddCategorySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CategoryBloc>(),
      child: const _AddCategorySheet(),
    ),
  );
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _nameFocus.dispose(); _descFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CategoryBloc>().add(OnAddCategory(
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
          GlobalSnackBar.show(message: 'Category created successfully', isInfo: true);
        }
        if (state.submitStatus == CategorySubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true, isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: 'New Category',
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              FieldLabel(label: 'Category Name', required: true),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                nextFocus: _descFocus,
                hint: 'Beverages',
                prefixIcon: Icons.layers_rounded,
                validator:  CategoryFormValidators.name,
              ),
              const SizedBox(height: AppDims.s4),

              OptionalDivider(),
              const SizedBox(height: AppDims.s4),

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

              CategorySubmitButton(label: 'Create Category', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}